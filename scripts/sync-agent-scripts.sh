#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=0
PROVIDERS=()
SECTION_STARTED=0

RUN_DIR="$(pwd)"
COPILOT_PROMPTS_DIR="${COPILOT_PROMPTS_DIR:-}"
COPILOT_USER_PROMPTS_DIR="${COPILOT_USER_PROMPTS_DIR:-}"
CURSOR_COMMANDS_DIR="${CURSOR_COMMANDS_DIR:-}"
CURSOR_SCOPE="${CURSOR_SCOPE:-global}"
COPILOT_SCOPE="${COPILOT_SCOPE:-none}"
AGENTS_SCOPE="${AGENTS_SCOPE:-global}"

usage() {
  cat <<'USAGE'
Usage: scripts/sync-agent-scripts.sh [options]

Sync skills/, slash-commands/, and project MCP bundles from this repo into
supported agent runtimes.

Skills install as relative symlinks into this repo's skills/ — one canonical
copy, every runtime links to it (no duplication, no re-sync after edits). The
link targets are ~/.agents/skills (cross-tool standard, read by Codex, Gemini,
Cursor, Copilot, Windsurf), ~/.claude/skills (Claude Code only), and
~/.gemini/antigravity-cli/skills (Antigravity CLI). This makes agent-scripts a
runtime dependency: move or delete it and the links break.
Commands/prompts are copied to each tool's native location.

Profiles (profiles/<name>/skills/ plus optional profiles/<name>/mcp.json) are
project-scoped packages. They are NOT part of the default run — sync them with
the 'profiles' provider, which installs into each assigned project's
.agents/skills, .claude/skills, and .mcp.json. Assignments come from
profile-assignments.json or from --profile/--project for a one-off.

Options:
  --providers <list>          Comma-separated providers (agents,subagents,codex,claude,gemini,cursor,copilot,antigravity,profiles)
  --provider <name>           Add a single provider (repeatable)
  --agents-home <path>        Override agents home (default: ~/.agents)
  --agents-skills-dir <path>  Override agents skills directory (default: ~/.agents/skills)
  --agents-scope <scope>      Agents scope: global, project, or both (default: global)
  --claude-home <path>        Override Claude home (default: ~/.claude)
  --claude-skills-dir <path>  Override Claude skills directory (default: ~/.claude/skills)
  --codex-home <path>         Override Codex home (default: ~/.codex)
  --gemini-home <path>        Override Gemini home (default: ~/.gemini)
  --antigravity-skills-dir <path>Override Antigravity CLI skills dir (default: ~/.gemini/antigravity-cli/skills)
  --cursor-commands-dir <path>Override Cursor project commands dir (default: ./.cursor/commands)
  --cursor-scope <scope>      Cursor scope: project, global, or both (default: global)
  --copilot-prompts-dir <path>Override Copilot workspace prompts dir (default: ./.github/prompts)
  --copilot-user-prompts-dir <path>Override Copilot user prompts dir (required for user scope)
  --copilot-scope <scope>     Copilot scope: workspace, user, both, or none (default: none)
  --profile <name>            Profile to sync for a one-off (repeatable; requires --project)
  --project <path>            Target project root for a one-off profile sync
  --profiles-manifest <path>  Override assignments file (default: ./profile-assignments.json)
  --dry-run                   Print actions without writing files
  -h, --help                  Show this help

Examples:
  scripts/sync-agent-scripts.sh
  scripts/sync-agent-scripts.sh --providers agents,claude
  scripts/sync-agent-scripts.sh --provider agents --agents-scope both
  scripts/sync-agent-scripts.sh --provider copilot --copilot-scope workspace
  scripts/sync-agent-scripts.sh --provider profiles
  scripts/sync-agent-scripts.sh --provider profiles --profile swift-app-developer --project ~/Developer/platesnap
USAGE
}

log() {
  printf '%s\n' "$*"
}

log_section() {
  if [[ "$SECTION_STARTED" -eq 1 ]]; then
    printf '\n'
  fi
  SECTION_STARTED=1
  printf '== %s ==\n' "$1"
}

log_sub() {
  printf '  %s\n' "$*"
}

log_action() {
  local verb="$1"
  local src="$2"
  local dest="$3"
  printf '  - %s %s -> %s\n' "$verb" "$src" "$dest"
}

action_verb() {
  local dest="$1"
  if [[ -e "$dest" ]]; then
    printf 'update'
  else
    printf 'create'
  fi
}

files_identical() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "$dest" ]]; then
    return 1
  fi
  cmp -s "$src" "$dest"
}

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

run_copy_file() {
  local src="$1"
  local dest="$2"
  local verb
  if files_identical "$src" "$dest"; then
    return 0
  fi
  verb=$(action_verb "$dest")
  log_action "$verb" "$src" "$dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp -f "$src" "$dest"
}

update_gemini_settings() {
  local settings_path="$1"
  local context_file="$2"
  local verb=""
  local current=""

  if [[ -f "$settings_path" ]]; then
    current=$(python3 - "$settings_path" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    data = {}
value = data.get("contextFileName", "")
print(value if isinstance(value, str) else "")
PY
)
    if [[ "$current" == "$context_file" ]]; then
      log_action "skip" "contextFileName" "$settings_path"
      return 0
    fi
    verb="update"
  else
    verb="create"
  fi

  log_action "$verb" "contextFileName" "$settings_path"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$settings_path")"
  python3 - "$settings_path" "$context_file" <<'PY'
import json
import os
import sys

path = sys.argv[1]
context_file = sys.argv[2]

data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError:
        data = {}

data["contextFileName"] = context_file

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
}

sync_markdown_tree() {
  local src_root="$1"
  local dest_root="$2"

  # No source tree is a benign "nothing to sync" state (e.g. a repo with zero
  # slash commands) — skip quietly rather than logging a scary line.
  if [[ ! -d "$src_root" ]]; then
    return 0
  fi

  while IFS= read -r -d '' file; do
    local rel="${file#$src_root/}"
    run_copy_file "$file" "$dest_root/$rel"
  done < <(find "$src_root" -type f -name '*.md' -print0)
}

sync_codex_hook() {
  local codex_home="$1"
  local hook_command="$2"
  local hooks_path="$codex_home/hooks.json"

  log_sub "Hooks -> $hooks_path"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_action "$(action_verb "$hooks_path")" "SessionStart auto-pull hook" "$hooks_path"
    return 0
  fi

  mkdir -p "$codex_home"
  python3 - "$hooks_path" "$hook_command" <<'PY'
import json
import os
import sys

path = sys.argv[1]
command = sys.argv[2]
hook = {
    "type": "command",
    "command": command,
    "timeout": 30,
}

data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            existing = json.load(f)
        if isinstance(existing, dict):
            data = existing
    except json.JSONDecodeError:
        data = {}

hooks_root = data.setdefault("hooks", {})
if not isinstance(hooks_root, dict):
    hooks_root = {}
    data["hooks"] = hooks_root

session_start = hooks_root.get("SessionStart")
if not isinstance(session_start, list):
    session_start = []
hooks_root["SessionStart"] = session_start

for item in session_start:
    if not isinstance(item, dict):
        continue
    existing_hooks = item.get("hooks")
    if not isinstance(existing_hooks, list):
        continue
    item["hooks"] = [
        existing_hook
        for existing_hook in existing_hooks
        if not (
            isinstance(existing_hook, dict)
            and existing_hook.get("command") == command
        )
    ]

session_start[:] = [
    item
    for item in session_start
    if not (
        isinstance(item, dict)
        and isinstance(item.get("hooks"), list)
        and len(item["hooks"]) == 0
    )
]

group = None
for item in session_start:
    if isinstance(item, dict) and "matcher" not in item:
        group = item
        break

if group is None:
    group = {"hooks": []}
    session_start.append(group)

hooks = group.setdefault("hooks", [])
if not isinstance(hooks, list):
    hooks = []
    group["hooks"] = hooks

hooks.append(hook)

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

sync_claude_hook() {
  local settings_path="$1"
  local hook_command="$2"

  log_sub "Hooks -> $settings_path"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_action "$(action_verb "$settings_path")" "SessionStart auto-pull hook" "$settings_path"
    return 0
  fi

  mkdir -p "$(dirname "$settings_path")"
  python3 - "$settings_path" "$hook_command" <<'PY'
import json
import os
import sys

path = sys.argv[1]
command = sys.argv[2]
hook = {
    "type": "command",
    "command": command,
    "timeout": 30,
}

data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            existing = json.load(f)
        if isinstance(existing, dict):
            data = existing
    except json.JSONDecodeError:
        data = {}

hooks_root = data.setdefault("hooks", {})
if not isinstance(hooks_root, dict):
    hooks_root = {}
    data["hooks"] = hooks_root

session_start = hooks_root.setdefault("SessionStart", [])
if not isinstance(session_start, list):
    session_start = []
    hooks_root["SessionStart"] = session_start

for item in session_start:
    if not isinstance(item, dict):
        continue
    existing_hooks = item.get("hooks")
    if not isinstance(existing_hooks, list):
        continue
    item["hooks"] = [
        existing_hook
        for existing_hook in existing_hooks
        if not (
            isinstance(existing_hook, dict)
            and existing_hook.get("command") == command
        )
    ]

session_start[:] = [
    item
    for item in session_start
    if not (
        isinstance(item, dict)
        and isinstance(item.get("hooks"), list)
        and len(item["hooks"]) == 0
    )
]

group = None
for item in session_start:
    if isinstance(item, dict) and "matcher" not in item:
        group = item
        break

if group is None:
    group = {"hooks": []}
    session_start.append(group)

hooks = group.setdefault("hooks", [])
if not isinstance(hooks, list):
    hooks = []
    group["hooks"] = hooks

hooks.append(hook)

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

render_gemini_toml() {
  local src="$1"
  local dest="$2"
  local name="$3"

  local title
  title=$(awk 'NR==1 && /^# / {sub(/^# /, ""); print; exit}' "$src")
  local desc="${title:-$name}"
  desc=${desc//\"/\\\"}

  local body
  body=$(awk 'NR==1 && /^# / {next} {print}' "$src")
  body=${body//\$ARGUMENTS/{{args}}}
  body=${body//\"\"\"/\\\"\\\"\\\"}

  local tmp_file
  tmp_file=$(mktemp)
  {
    printf 'description = "%s"\n\n' "$desc"
    printf 'prompt = """\n'
    printf '%s\n' "$body"
    printf '"""\n'
  } > "$tmp_file"

  if files_identical "$tmp_file" "$dest"; then
    rm -f "$tmp_file"
    return 0
  fi

  log_action "$(action_verb "$dest")" "$src" "$dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    rm -f "$tmp_file"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  mv "$tmp_file" "$dest"
}

render_copilot_prompt() {
  local src="$1"
  local dest="$2"
  local name="$3"

  local title
  title=$(awk 'NR==1 && /^# / {sub(/^# /, ""); print; exit}' "$src")
  local desc="${title:-$name}"
  desc=${desc//\"/\\\"}

  local body
  body=$(awk 'NR==1 && /^# / {next} {print}' "$src")
  if [[ "$body" == *'$ARGUMENTS'* ]]; then
    local args_placeholder='${input:arguments:Provide arguments}'
    body=${body//\$ARGUMENTS/$args_placeholder}
  fi

  local tmp_file
  tmp_file=$(mktemp)
  {
    printf '%s\n' '---'
    printf 'mode: agent\n'
    printf 'description: "%s"\n' "$desc"
    printf '%s\n\n' '---'
    printf '%s\n' "$body"
  } > "$tmp_file"

  if files_identical "$tmp_file" "$dest"; then
    rm -f "$tmp_file"
    return 0
  fi

  log_action "$(action_verb "$dest")" "$src" "$dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    rm -f "$tmp_file"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  mv "$tmp_file" "$dest"
}

want_provider() {
  local target="$1"
  for provider in "${PROVIDERS[@]}"; do
    if [[ "$provider" == "$target" || "$provider" == "all" ]]; then
      return 0
    fi
  done
  return 1
}

scope_has() {
  local scope="$1"
  local target="$2"
  if [[ "$scope" == "both" ]]; then
    return 0
  fi
  [[ "$scope" == "$target" ]]
}

# Global skills install as relative symlinks straight into agent-scripts —
# one canonical copy in the repo, every runtime links to it. Zero duplication,
# zero drift: edit a skill in the repo and every tool sees it instantly, no
# re-sync needed. (Profiles use the same model for project-scoped skills.)
sync_skills_to() {
  local dest_dir="$1"
  local label="$2"
  log_sub "$label -> $dest_dir (symlinks into agent-scripts)"
  shopt -s nullglob
  for skill_dir in "$ROOT/skills"/*; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    make_relative_symlink "$dest_dir/$skill_name" "$skill_dir" 1
  done
  shopt -u nullglob
}

# Print "project<TAB>profile" lines from the assignments manifest. A project
# with multiple profiles yields one line per profile.
parse_profile_manifest() {
  local manifest="$1"
  if [[ ! -f "$manifest" ]]; then
    return 0
  fi
  python3 - "$manifest" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as exc:  # noqa: BLE001
    sys.stderr.write(f"failed to parse {path}: {exc}\n")
    sys.exit(1)

assignments = data.get("assignments", data)
if not isinstance(assignments, dict):
    sys.exit(0)

for project, profiles in assignments.items():
    if project.startswith("_"):
        continue
    if isinstance(profiles, str):
        profiles = [profiles]
    if not isinstance(profiles, list):
        continue
    for profile in profiles:
        if isinstance(profile, str) and profile:
            print(f"{project}\t{profile}")
PY
}

# Create/refresh a symlink at $link pointing to $target via a relative path
# computed from the link's directory. Idempotent and dry-run aware.
#
# By default refuses to clobber a real directory or file at $link — only
# replaces existing symlinks (any target) or creates new entries. A real dir
# with the same name as a profile skill is treated as project-authored content
# (the agent-scripts repo has no business deleting it); the sync skips it and
# warns loudly. The user resolves manually: delete the dir if it's stale, or
# promote its content into the profile if it's the canonical copy.
#
# Pass force=1 only for fully sync-managed destinations (the global skills
# dirs), where a real dir is a stale copy from the old copy-based model and is
# safe to replace with a symlink — the same name was already overwritten on
# every prior sync under the copy model, so this is not new clobbering behavior.
make_relative_symlink() {
  local link="$1"
  local target="$2"
  local force="${3:-0}"
  local link_dir
  link_dir="$(dirname "$link")"

  local rel
  rel="$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$target" "$link_dir")"

  if [[ -L "$link" && "$(readlink "$link")" == "$rel" ]]; then
    return 0
  fi

  # Safety: never destroy a real (non-symlink) directory or file at $link unless
  # explicitly forced for a sync-managed destination.
  if [[ ! -L "$link" && -e "$link" && "$force" != "1" ]]; then
    log_sub "WARNING: $link is a real directory/file, not a symlink — refusing to clobber. Move or promote its content, then rerun."
    return 0
  fi

  log_action "$(action_verb "$link")" "symlink" "$link -> $rel"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  mkdir -p "$link_dir"
  # rm -rf on a symlink removes only the link, not its target; on a forced
  # real-dir replacement it removes the stale copy.
  rm -rf "$link"
  ln -s "$rel" "$link"
}

# Install one profile's skills into a project as relative symlinks pointing
# back into agent-scripts. Zero duplication, zero drift — edits in agent-scripts
# show up instantly in every assigned project.
#
#   <project>/.agents/skills/<name>  -> ../../../agent-scripts/profiles/<profile>/skills/<name>
#   <project>/.claude/skills/<name>  -> ../../.agents/skills/<name>
#
# Shared skills resolve through profile->_shared symlink chains naturally;
# we deliberately do NOT collapse the chain so moves between profiles only
# touch one place.
sync_profile_to_project() {
  local profile="$1"
  local project="$2"
  local src="$ROOT/profiles/$profile/skills"
  local mcp_src="$ROOT/profiles/$profile/mcp.json"

  if [[ ! -d "$src" && ! -f "$mcp_src" ]]; then
    log_sub "Skipping: missing profile '$profile' ($src or $mcp_src)"
    return 0
  fi
  # Never materialize a project root that doesn't exist — that would just
  # create an empty <name>/.agents/skills/ tree out of nowhere.
  if [[ ! -d "$project" ]]; then
    log_sub "Skipping: project not found ($project)"
    return 0
  fi

  local dest_agents="$project/.agents/skills"
  local dest_claude="$project/.claude/skills"
  log_sub "$profile -> $project (relative symlinks into agent-scripts)"

  if [[ -d "$src" ]]; then
    shopt -s nullglob
    for skill_dir in "$src"/*; do
      # Accept both real dirs and symlinks (shared skills are profile-level symlinks).
      [[ -d "$skill_dir" || -L "$skill_dir" ]] || continue
      skill_name="$(basename "$skill_dir")"
      make_relative_symlink "$dest_agents/$skill_name" "$skill_dir"
      make_relative_symlink "$dest_claude/$skill_name" "$dest_agents/$skill_name"
    done
    shopt -u nullglob
  fi

  sync_profile_mcp_to_project "$profile" "$project" "$mcp_src"
}

sync_profile_mcp_to_project() {
  local profile="$1"
  local project="$2"
  local src="$3"
  local dest="$project/.mcp.json"
  local codex_dest="$project/.codex/config.toml"

  if [[ ! -f "$src" ]]; then
    return 0
  fi

  log_action "$(action_verb "$dest")" "$profile MCP servers" "$dest"
  log_action "$(action_verb "$codex_dest")" "$profile Codex MCP servers" "$codex_dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  python3 - "$src" "$dest" "$codex_dest" "$profile" <<'PY'
import json
import os
import sys
import tomllib

src_path, dest_path, codex_dest_path, profile = sys.argv[1:5]

with open(src_path, "r", encoding="utf-8") as f:
    src = json.load(f)

src_servers = src.get("mcpServers")
if not isinstance(src_servers, dict):
    raise SystemExit(f"{src_path} must contain an object at mcpServers")


def to_codex_server(server):
    if not isinstance(server, dict):
        raise SystemExit("MCP server entries must be objects")
    if "url" in server:
        result = {"url": server["url"]}
        if "bearer_token_env_var" in server:
            result["bearer_token_env_var"] = server["bearer_token_env_var"]
        return result
    result = {}
    for key in ("command", "args", "env", "startup_timeout_sec"):
        if key in server:
            result[key] = server[key]
    if "command" not in result:
        raise SystemExit("MCP stdio server entries must contain command")
    return result


def render_mcp_server_toml(name, server):
    lines = [f"[mcp_servers.{name}]"]
    for key, value in server.items():
        if key == "env" and isinstance(value, dict):
            continue
        lines.append(f"{key} = {toml_value(value)}")
    if isinstance(server.get("env"), dict):
        lines.append("")
        lines.append(f"[mcp_servers.{name}.env]")
        for env_key, env_value in server["env"].items():
            lines.append(f"{env_key} = {toml_value(env_value)}")
    return "\n".join(lines)


def toml_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int) and not isinstance(value, bool):
        return str(value)
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(item) for item in value) + "]"
    return json.dumps(str(value), ensure_ascii=False)

dest = {}
if os.path.exists(dest_path):
    with open(dest_path, "r", encoding="utf-8") as f:
        dest = json.load(f)
    if not isinstance(dest, dict):
        raise SystemExit(f"{dest_path} must contain a JSON object")

dest_servers = dest.setdefault("mcpServers", {})
if not isinstance(dest_servers, dict):
    raise SystemExit(f"{dest_path} must contain an object at mcpServers")

changed = False
for name, server in src_servers.items():
    if name not in dest_servers:
        dest_servers[name] = server
        changed = True
        continue
    if dest_servers[name] != server:
        sys.stderr.write(
            f"WARNING: {dest_path} already defines MCP server '{name}' "
            f"differently; keeping project value instead of {profile} profile value.\n"
        )

if changed:
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    with open(dest_path, "w", encoding="utf-8") as f:
        json.dump(dest, f, indent=2, ensure_ascii=False)
        f.write("\n")

codex = {}
if os.path.exists(codex_dest_path):
    with open(codex_dest_path, "rb") as f:
        codex = tomllib.load(f)
    if not isinstance(codex, dict):
        raise SystemExit(f"{codex_dest_path} must contain a TOML object")

codex_servers = codex.setdefault("mcp_servers", {})
if not isinstance(codex_servers, dict):
    raise SystemExit(f"{codex_dest_path} must contain a table at mcp_servers")

changed = False
missing_sections = []
for name, server in src_servers.items():
    codex_server = to_codex_server(server)
    if name not in codex_servers:
        codex_servers[name] = codex_server
        missing_sections.append((name, codex_server))
        changed = True
        continue
    if codex_servers[name] != codex_server:
        sys.stderr.write(
            f"WARNING: {codex_dest_path} already defines MCP server '{name}' "
            f"differently; keeping project value instead of {profile} profile value.\n"
        )

if changed:
    os.makedirs(os.path.dirname(codex_dest_path), exist_ok=True)
    existing = ""
    if os.path.exists(codex_dest_path):
        with open(codex_dest_path, "r", encoding="utf-8") as f:
            existing = f.read()
    with open(codex_dest_path, "a", encoding="utf-8") as f:
        if existing and not existing.endswith("\n"):
            f.write("\n")
        if existing and missing_sections:
            f.write("\n")
        for index, (name, server) in enumerate(missing_sections):
            if index > 0:
                f.write("\n\n")
            f.write(render_mcp_server_toml(name, server))
            f.write("\n")
PY
}

AGENTS_HOME_DEFAULT="$HOME/.agents"
CODEX_HOME_DEFAULT="$HOME/.codex"
CLAUDE_HOME_DEFAULT="$HOME/.claude"
GEMINI_HOME_DEFAULT="$HOME/.gemini"
GEMINI_CONTEXT_FILE_DEFAULT="AGENTS.md"

AGENTS_HOME="$AGENTS_HOME_DEFAULT"
CODEX_HOME="$CODEX_HOME_DEFAULT"
CLAUDE_HOME="$CLAUDE_HOME_DEFAULT"
GEMINI_HOME="$GEMINI_HOME_DEFAULT"
AGENTS_SKILLS_DIR_DEFAULT="$HOME/.agents/skills"
AGENTS_SKILLS_DIR="$AGENTS_SKILLS_DIR_DEFAULT"
CLAUDE_SKILLS_DIR_DEFAULT="$HOME/.claude/skills"
CLAUDE_SKILLS_DIR="$CLAUDE_SKILLS_DIR_DEFAULT"
ANTIGRAVITY_SKILLS_DIR_DEFAULT="$HOME/.gemini/antigravity-cli/skills"
ANTIGRAVITY_SKILLS_DIR="$ANTIGRAVITY_SKILLS_DIR_DEFAULT"

PROFILES_MANIFEST_DEFAULT="$ROOT/profile-assignments.json"
PROFILES_MANIFEST="$PROFILES_MANIFEST_DEFAULT"
PROFILE_NAMES=()
PROFILE_PROJECT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --providers)
      IFS=',' read -r -a providers_list <<< "$2"
      for p in "${providers_list[@]}"; do
        PROVIDERS+=("$(to_lower "$p")")
      done
      shift 2
      ;;
    --provider)
      PROVIDERS+=("$(to_lower "$2")")
      shift 2
      ;;
    --agents-home)
      AGENTS_HOME="$2"
      shift 2
      ;;
    --agents-skills-dir)
      AGENTS_SKILLS_DIR="$2"
      shift 2
      ;;
    --agents-scope)
      AGENTS_SCOPE="$(to_lower "$2")"
      shift 2
      ;;
    --codex-home)
      CODEX_HOME="$2"
      shift 2
      ;;
    --claude-home)
      CLAUDE_HOME="$2"
      shift 2
      ;;
    --claude-skills-dir)
      CLAUDE_SKILLS_DIR="$2"
      shift 2
      ;;
    --gemini-home)
      GEMINI_HOME="$2"
      shift 2
      ;;
    --antigravity-skills-dir)
      ANTIGRAVITY_SKILLS_DIR="$2"
      shift 2
      ;;
    --profile)
      PROFILE_NAMES+=("$2")
      shift 2
      ;;
    --project)
      PROFILE_PROJECT="$2"
      shift 2
      ;;
    --profiles-manifest)
      PROFILES_MANIFEST="$2"
      shift 2
      ;;
    --cursor-commands-dir)
      CURSOR_COMMANDS_DIR="$2"
      shift 2
      ;;
    --cursor-scope)
      CURSOR_SCOPE="$(to_lower "$2")"
      shift 2
      ;;
    --copilot-prompts-dir)
      COPILOT_PROMPTS_DIR="$2"
      shift 2
      ;;
    --copilot-user-prompts-dir)
      COPILOT_USER_PROMPTS_DIR="$2"
      shift 2
      ;;
    --copilot-scope)
      COPILOT_SCOPE="$(to_lower "$2")"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ ${#PROVIDERS[@]} -eq 0 ]]; then
  # A one-off profile sync (--profile/--project without --providers) should only
  # run the profiles provider, never fan out the global skill set.
  if [[ ${#PROFILE_NAMES[@]} -gt 0 || -n "$PROFILE_PROJECT" ]]; then
    PROVIDERS=(profiles)
  else
    PROVIDERS=(agents subagents codex claude gemini cursor copilot antigravity)
  fi
fi

case "$AGENTS_SCOPE" in
  global|project|both) ;;
  *)
    log "Invalid --agents-scope: $AGENTS_SCOPE (expected global, project, or both)"
    exit 1
    ;;
esac

case "$CURSOR_SCOPE" in
  project|global|both) ;;
  *)
    log "Invalid --cursor-scope: $CURSOR_SCOPE (expected project, global, or both)"
    exit 1
    ;;
esac

case "$COPILOT_SCOPE" in
  workspace|user|both|none) ;;
  *)
    log "Invalid --copilot-scope: $COPILOT_SCOPE (expected workspace, user, both, or none)"
    exit 1
    ;;
esac

# --- Agents: cross-tool skills (read by Codex, Gemini, Cursor, Copilot, Windsurf) ---
if want_provider "agents"; then
  log_section "Agents"

  if scope_has "$AGENTS_SCOPE" "global"; then
    sync_skills_to "$AGENTS_SKILLS_DIR" "Global skills"
  fi

  if scope_has "$AGENTS_SCOPE" "project"; then
    sync_skills_to "$RUN_DIR/.agents/skills" "Project skills"
  fi
fi

# --- Subagents: native subagent files generated per harness from subagents/ ---
if want_provider "subagents"; then
  log_section "Subagents"
  if [[ -d "$ROOT/subagents" ]]; then
    gen_args=(--claude-agents-dir "$CLAUDE_HOME/agents" --codex-agents-dir "$CODEX_HOME/agents")
    [[ "$DRY_RUN" -eq 1 ]] && gen_args+=(--dry-run)
    python3 "$ROOT/scripts/gen-subagents.py" "${gen_args[@]}"
  else
    log_sub "No subagents/ dir; skipping"
  fi
fi

# --- Codex: prompts + hooks (skills handled by agents provider) ---
if want_provider "codex"; then
  codex_prompts_dir="$CODEX_HOME/prompts"
  auto_pull_hook="$ROOT/hooks/scripts/git-auto-pull-current-branch.sh"

  log_section "Codex"
  log_sub "Prompts -> $codex_prompts_dir"
  shopt -s nullglob
  for prompt in "$ROOT/slash-commands"/*.md; do
    [[ -f "$prompt" ]] || continue
    run_copy_file "$prompt" "$codex_prompts_dir/$(basename "$prompt")"
  done
  shopt -u nullglob

  skill_usage_hooks="$ROOT/hooks/scripts/install-skill-usage-hooks.py"
  if [[ -f "$skill_usage_hooks" ]]; then
    log_sub "Hooks -> skill usage (Codex + Claude)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log_action "would run" "install-skill-usage-hooks.py" "$skill_usage_hooks"
    else
      python3 "$skill_usage_hooks"
    fi
  elif [[ -f "$auto_pull_hook" ]]; then
    sync_codex_hook "$CODEX_HOME" "$auto_pull_hook"
  else
    log_sub "Skipping hooks: missing $auto_pull_hook"
  fi
fi

# --- Claude Code: skills + commands + hooks (does not support .agents/) ---
if want_provider "claude"; then
  claude_commands_dir="$CLAUDE_HOME/commands"
  auto_pull_hook="$ROOT/hooks/scripts/git-auto-pull-current-branch.sh"
  log_section "Claude"
  sync_skills_to "$CLAUDE_SKILLS_DIR" "Skills"

  log_sub "Commands -> $claude_commands_dir"
  sync_markdown_tree "$ROOT/slash-commands" "$claude_commands_dir"

  skill_usage_hooks="$ROOT/hooks/scripts/install-skill-usage-hooks.py"
  if ! want_provider "codex" && [[ -f "$skill_usage_hooks" ]]; then
    log_sub "Hooks -> skill usage (Claude + Codex)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log_action "would run" "install-skill-usage-hooks.py" "$skill_usage_hooks"
    else
      python3 "$skill_usage_hooks"
    fi
  elif [[ -f "$auto_pull_hook" ]]; then
    sync_claude_hook "$CLAUDE_HOME/settings.json" "$auto_pull_hook"
  else
    log_sub "Skipping hooks: missing $auto_pull_hook"
  fi
fi

# --- Gemini: commands + settings only (skills handled by agents provider) ---
if want_provider "gemini"; then
  gemini_commands_dir="$GEMINI_HOME/commands"
  log_section "Gemini"

  log_sub "Commands -> $gemini_commands_dir"

  # Guard the find: a missing slash-commands/ tree is a benign no-op, not an error.
  if [[ -d "$ROOT/slash-commands" ]]; then
    while IFS= read -r -d '' file; do
      rel="${file#$ROOT/slash-commands/}"
      base_name="${rel##*/}"
      base_name="${base_name%.md}"
      rel_dir="$(dirname "$rel")"
      if [[ "$rel_dir" == "." ]]; then
        dest_dir="$gemini_commands_dir"
      else
        dest_dir="$gemini_commands_dir/$rel_dir"
      fi
      render_gemini_toml "$file" "$dest_dir/$base_name.toml" "$base_name"
    done < <(find "$ROOT/slash-commands" -type f -name '*.md' -print0)
  fi

  update_gemini_settings "$GEMINI_HOME/settings.json" "$GEMINI_CONTEXT_FILE_DEFAULT"
fi

# --- Antigravity CLI: skills (standard SKILL.md dirs, own global skills location) ---
if want_provider "antigravity"; then
  log_section "Antigravity"
  sync_skills_to "$ANTIGRAVITY_SKILLS_DIR" "Skills"
fi

# --- Profiles: project-scoped skill packages (never part of the default run) ---
if want_provider "profiles"; then
  log_section "Profiles"

  profile_pairs=()
  if [[ ${#PROFILE_NAMES[@]} -gt 0 || -n "$PROFILE_PROJECT" ]]; then
    if [[ -z "$PROFILE_PROJECT" || ${#PROFILE_NAMES[@]} -eq 0 ]]; then
      log "One-off profile sync requires both --project and --profile."
      exit 1
    fi
    for pn in "${PROFILE_NAMES[@]}"; do
      profile_pairs+=("$PROFILE_PROJECT"$'\t'"$pn")
    done
  else
    log_sub "Manifest -> $PROFILES_MANIFEST"
    if [[ ! -f "$PROFILES_MANIFEST" ]]; then
      log_sub "Skipping: no manifest at $PROFILES_MANIFEST (pass --profile/--project for a one-off)."
    else
      while IFS= read -r line; do
        [[ -n "$line" ]] && profile_pairs+=("$line")
      done < <(parse_profile_manifest "$PROFILES_MANIFEST")
    fi
  fi

  for pair in "${profile_pairs[@]}"; do
    profile_project="${pair%%$'\t'*}"
    profile_name="${pair#*$'\t'}"
    profile_project="${profile_project/#\~/$HOME}"
    sync_profile_to_project "$profile_name" "$profile_project"
  done
fi

# --- Cursor: commands only (skills handled by agents provider) ---
if want_provider "cursor"; then
  if [[ -z "$CURSOR_COMMANDS_DIR" ]]; then
    CURSOR_COMMANDS_DIR="$RUN_DIR/.cursor/commands"
  fi

  log_section "Cursor"

  if scope_has "$CURSOR_SCOPE" "project"; then
    log_sub "Project commands -> $CURSOR_COMMANDS_DIR"
    sync_markdown_tree "$ROOT/slash-commands" "$CURSOR_COMMANDS_DIR"
  fi

  if scope_has "$CURSOR_SCOPE" "global"; then
    global_cursor_commands_dir="$HOME/.cursor/commands"
    log_sub "Global commands -> $global_cursor_commands_dir"
    sync_markdown_tree "$ROOT/slash-commands" "$global_cursor_commands_dir"
  fi
fi

# --- Copilot: prompts only (skills handled by agents provider) ---
if want_provider "copilot"; then
  log_section "Copilot"

  if scope_has "$COPILOT_SCOPE" "workspace"; then
    if [[ -z "$COPILOT_PROMPTS_DIR" ]]; then
      log_sub "Skipping workspace prompts: set COPILOT_PROMPTS_DIR or --copilot-prompts-dir."
    else
      log_sub "Workspace prompts -> $COPILOT_PROMPTS_DIR"
      while IFS= read -r -d '' file; do
        rel="${file#$ROOT/slash-commands/}"
        base_name="${rel##*/}"
        base_name="${base_name%.md}"
        rel_dir="$(dirname "$rel")"
        if [[ "$rel_dir" == "." ]]; then
          dest_dir="$COPILOT_PROMPTS_DIR"
        else
          dest_dir="$COPILOT_PROMPTS_DIR/$rel_dir"
        fi
        render_copilot_prompt "$file" "$dest_dir/$base_name.prompt.md" "$base_name"
      done < <(find "$ROOT/slash-commands" -type f -name '*.md' -print0)
    fi
  fi

  if scope_has "$COPILOT_SCOPE" "user"; then
    if [[ -z "$COPILOT_USER_PROMPTS_DIR" ]]; then
      log_sub "Skipping user prompts: set COPILOT_USER_PROMPTS_DIR or --copilot-user-prompts-dir."
    else
      log_sub "User prompts -> $COPILOT_USER_PROMPTS_DIR"
      while IFS= read -r -d '' file; do
        rel="${file#$ROOT/slash-commands/}"
        base_name="${rel##*/}"
        base_name="${base_name%.md}"
        rel_dir="$(dirname "$rel")"
        if [[ "$rel_dir" == "." ]]; then
          dest_dir="$COPILOT_USER_PROMPTS_DIR"
        else
          dest_dir="$COPILOT_USER_PROMPTS_DIR/$rel_dir"
        fi
        render_copilot_prompt "$file" "$dest_dir/$base_name.prompt.md" "$base_name"
      done < <(find "$ROOT/slash-commands" -type f -name '*.md' -print0)
    fi
  fi

  if [[ "$COPILOT_SCOPE" == "none" ]]; then
    log_sub "Skipping prompts: set --copilot-scope and a prompts dir."
  fi
fi

# --- Symlink: ensure CLAUDE.md <-> AGENTS.md in git repos ---
ensure_claude_agents_symlink() {
  local dir="$1"

  # Skip non-git directories
  [[ -d "$dir/.git" ]] || return 0

  # Skip agent-scripts itself
  [[ "$(cd "$dir" && pwd)" == "$ROOT" ]] && return 0

  local has_claude=0
  local has_agents=0
  local claude_is_symlink=0
  local agents_is_symlink=0

  # Check all case variants
  for f in "$dir"/CLAUDE.md "$dir"/claude.md; do
    if [[ -e "$f" || -L "$f" ]]; then
      has_claude=1
      [[ -L "$f" ]] && claude_is_symlink=1
    fi
  done
  for f in "$dir"/AGENTS.md "$dir"/agents.md; do
    if [[ -e "$f" || -L "$f" ]]; then
      has_agents=1
      [[ -L "$f" ]] && agents_is_symlink=1
    fi
  done

  # Both present - check if CLAUDE.md is already a symlink, or if identical files
  if [[ "$has_claude" -eq 1 && "$has_agents" -eq 1 ]]; then
    # Already a symlink - nothing to do
    [[ "$claude_is_symlink" -eq 1 ]] && return 0

    # Both are real files - if identical, replace CLAUDE.md with symlink
    local claude_file agents_file
    for f in "$dir"/CLAUDE.md "$dir"/claude.md; do
      [[ -e "$f" ]] && claude_file="$f" && break
    done
    for f in "$dir"/AGENTS.md "$dir"/agents.md; do
      [[ -e "$f" ]] && agents_file="$f" && break
    done

    if cmp -s "$claude_file" "$agents_file"; then
      log_sub "$(basename "$dir"): CLAUDE.md identical to AGENTS.md, replacing with symlink"
      if [[ "$DRY_RUN" -eq 0 ]]; then
        rm -f "$claude_file"
        ln -s AGENTS.md "$claude_file"
      fi
    fi
    return 0
  fi

  # Neither exists - nothing to do
  if [[ "$has_claude" -eq 0 && "$has_agents" -eq 0 ]]; then
    return 0
  fi

  local repo_name
  repo_name=$(basename "$dir")

  # Scenario 1: only CLAUDE.md exists -> copy to AGENTS.md, replace CLAUDE.md with symlink
  if [[ "$has_claude" -eq 1 && "$has_agents" -eq 0 ]]; then
    local claude_file
    for f in "$dir"/CLAUDE.md "$dir"/claude.md; do
      [[ -e "$f" ]] && claude_file="$f" && break
    done
    local agents_file="$dir/AGENTS.md"

    log_sub "$repo_name: CLAUDE.md -> copy to AGENTS.md, replace with symlink"
    if [[ "$DRY_RUN" -eq 0 ]]; then
      cp -f "$claude_file" "$agents_file"
      rm -f "$claude_file"
      ln -s AGENTS.md "$claude_file"
    fi
  fi

  # Scenario 2: only AGENTS.md exists -> create CLAUDE.md as symlink
  if [[ "$has_agents" -eq 1 && "$has_claude" -eq 0 ]]; then
    log_sub "$repo_name: create CLAUDE.md -> symlink to AGENTS.md"
    if [[ "$DRY_RUN" -eq 0 ]]; then
      ln -s AGENTS.md "$dir/CLAUDE.md"
    fi
  fi
}

# Only sweep ~/Developer repos for CLAUDE.md <-> AGENTS.md symlinks during a
# general (claude/agents) sync. A targeted run like `--provider profiles
# --project X` should not silently mutate every other repo's instructions
# files; the user expects scope to match the flag.
if want_provider "claude" || want_provider "agents"; then
  log_section "Symlinks"
  log_sub "CLAUDE.md <-> AGENTS.md in ~/Developer repos"
  shopt -s nullglob
  for repo_dir in "$HOME/Developer"/*/; do
    ensure_claude_agents_symlink "${repo_dir%/}"
  done
  shopt -u nullglob
fi

log "Done."
