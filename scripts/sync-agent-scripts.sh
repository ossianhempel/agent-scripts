#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=0
PRUNE=0
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

Profiles (profiles/<name>/skills/ plus optional profiles/<name>/mcp.json and
profiles/<name>/plugins.json) are project-scoped packages. They are NOT part of
the default run — sync them with the 'profiles' provider, which installs into
each assigned project's .agents/skills, .claude/skills, .mcp.json, and (Claude
only) .claude/settings.json plugin config. Assignments come from
profile-assignments.json or from --profile/--project for a one-off.

Plugins (plugins.json at the repo root) are public agent plugins installed
globally. They are NOT part of the default run — apply them with the 'plugins'
provider. Nothing is vendored: the 'claude' section is merged declaratively into
~/.claude/settings.json (extraKnownMarketplaces + enabledPlugins), and the
'codex' section registers marketplaces via `codex plugin marketplace add`, writes
enabled plugins into ~/.codex/config.toml, and runs any per-plugin installCommands.

Options:
  --providers <list>          Comma-separated providers (agents,subagents,codex,claude,gemini,cursor,copilot,antigravity,profiles,plugins)
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
  --prune                     (plugins provider) Also DISABLE/REMOVE managed
                              plugins no longer in the manifest. Only ever
                              touches plugins under marketplaces the manifest
                              declares — never manually-installed plugins.
  -h, --help                  Show this help

Examples:
  scripts/sync-agent-scripts.sh
  scripts/sync-agent-scripts.sh --providers agents,claude
  scripts/sync-agent-scripts.sh --provider agents --agents-scope both
  scripts/sync-agent-scripts.sh --provider copilot --copilot-scope workspace
  scripts/sync-agent-scripts.sh --provider profiles
  scripts/sync-agent-scripts.sh --provider profiles --profile swift-app-developer --project ~/Developer/platesnap
  scripts/sync-agent-scripts.sh --provider plugins
  scripts/sync-agent-scripts.sh --provider plugins --dry-run
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

# Copy one skill dir into a project as a real, self-contained directory.
# The source may itself be a profile->_shared symlink; cp -RL dereferences it so
# the project NEVER carries a link into agent-scripts (which would break on
# clone/CI/another machine, and which some tools don't traverse). Skips when the
# existing copy is already byte-identical (no git churn), and always replaces a
# stale symlink left by the old symlink-install model. Returns 0 if it wrote, 1
# if it skipped an identical copy.
copy_skill_dir() {
  local src="$1"
  local dest="$2"
  # diff follows a top-level symlink given as an argument, so this compares the
  # resolved _shared content against the project copy. A real, identical dir is
  # left untouched; a symlink dest (old model) fails the `! -L` guard and is
  # replaced with a copy below.
  if [[ -d "$dest" && ! -L "$dest" ]] && diff -qr "$src" "$dest" >/dev/null 2>&1; then
    return 1
  fi
  log_action "$(action_verb "$dest")" "skill copy" "$dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -RL "$src" "$dest"
  return 0
}

# Remove skill dirs this sync previously managed but no longer does, plus any
# broken symlinks left behind by the old symlink-install model. NEVER deletes
# project-authored skills: only names recorded in the dest's
# .agent-scripts-managed manifest are eligible for prune. Rewrites the manifest
# to the current managed set.
prune_managed_skills() {
  local dest_root="$1"
  shift
  local current=("$@")
  local manifest="$dest_root/.agent-scripts-managed"
  if [[ ! -d "$dest_root" ]]; then
    return 0
  fi

  # Clean dangling symlinks (migration leftovers) regardless of the manifest —
  # a broken link is never legitimate project content.
  local entry
  shopt -s nullglob
  for entry in "$dest_root"/*; do
    if [[ -L "$entry" && ! -e "$entry" ]]; then
      log_action "remove" "broken symlink" "$entry"
      if [[ "$DRY_RUN" -ne 1 ]]; then
        rm -f "$entry"
      fi
    fi
  done
  shopt -u nullglob

  # Prune previously-managed names that are no longer in the current set.
  if [[ -f "$manifest" ]]; then
    local name in_current j
    while IFS= read -r name; do
      if [[ -z "$name" ]]; then
        continue
      fi
      in_current=0
      for ((j = 0; j < ${#current[@]}; j++)); do
        if [[ "${current[$j]}" == "$name" ]]; then
          in_current=1
          break
        fi
      done
      if [[ "$in_current" -eq 0 && -e "$dest_root/$name" ]]; then
        log_action "remove" "stale skill" "$dest_root/$name"
        if [[ "$DRY_RUN" -ne 1 ]]; then
          rm -rf "$dest_root/$name"
        fi
      fi
    done < "$manifest"
  fi

  # Record the new managed set so the next sync can prune accurately.
  if [[ "$DRY_RUN" -ne 1 && ${#current[@]} -gt 0 ]]; then
    mkdir -p "$dest_root"
    printf '%s\n' "${current[@]}" > "$manifest"
  fi
}

# Install one or more profiles' skills into a project as self-contained COPIES
# (not symlinks). App repos must stay portable: a symlink into agent-scripts
# breaks the moment the repo is cloned, run in CI, or opened on another machine,
# and some editors/indexers won't traverse it. The in-repo _shared model still
# gives a single source of truth; we dereference it at install time so the
# project gets real files. When a project maps to several profiles, their skills
# are unioned (first profile wins a name clash) so the prune pass is correct.
sync_profiles_to_project() {
  local project="$1"
  shift
  local profiles=("$@")

  # Never materialize a project root that doesn't exist — that would just
  # create an empty <name>/.agents/skills/ tree out of nowhere.
  if [[ ! -d "$project" ]]; then
    log_sub "Skipping: project not found ($project)"
    return 0
  fi

  local dest_agents="$project/.agents/skills"
  local dest_claude="$project/.claude/skills"

  # Union of skill_name -> source path across every profile for this project.
  local skill_names=()
  local skill_srcs=()
  local profile src mcp_src plugins_src skill_dir skill_name i found
  for profile in "${profiles[@]}"; do
    src="$ROOT/profiles/$profile/skills"
    mcp_src="$ROOT/profiles/$profile/mcp.json"
    plugins_src="$ROOT/profiles/$profile/plugins.json"

    if [[ ! -d "$src" && ! -f "$mcp_src" && ! -f "$plugins_src" ]]; then
      log_sub "Skipping: missing profile '$profile' ($src, $mcp_src, or $plugins_src)"
      continue
    fi
    log_sub "$profile -> $project (self-contained copies)"

    if [[ -d "$src" ]]; then
      shopt -s nullglob
      for skill_dir in "$src"/*; do
        # Accept both real dirs and symlinks (shared skills are profile-level symlinks).
        [[ -d "$skill_dir" || -L "$skill_dir" ]] || continue
        skill_name="$(basename "$skill_dir")"
        found=0
        for ((i = 0; i < ${#skill_names[@]}; i++)); do
          if [[ "${skill_names[$i]}" == "$skill_name" ]]; then
            found=1
            break
          fi
        done
        if [[ "$found" -eq 1 ]]; then
          log_sub "  note: '$skill_name' provided by multiple profiles; keeping first"
          continue
        fi
        skill_names+=("$skill_name")
        skill_srcs+=("$skill_dir")
      done
      shopt -u nullglob
    fi

    sync_profile_mcp_to_project "$profile" "$project" "$mcp_src"
    # Per-project plugins are Claude-only (Codex plugins are inherently global);
    # merge into this project's .claude/settings.json.
    sync_claude_plugins "$plugins_src" "$project/.claude/settings.json" "$profile"
  done

  # Install the union as copies into both dest dirs, then prune each.
  local d
  for d in "$dest_agents" "$dest_claude"; do
    for ((i = 0; i < ${#skill_names[@]}; i++)); do
      copy_skill_dir "${skill_srcs[$i]}" "$d/${skill_names[$i]}" || true
    done
    prune_managed_skills "$d" "${skill_names[@]}"
  done
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

# Merge a plugins manifest's `claude` section into a Claude settings.json:
#   extraKnownMarketplaces <- claude.marketplaces (each wrapped as {"source": <entry>})
#   enabledPlugins         <- claude.enabled[] as {name: true}
# Declarative and idempotent — Claude Code resolves/installs the marketplace on
# next launch, so no files are vendored. Preserves unrelated settings; warns
# (never clobbers) on a marketplace-source conflict. Reusable for both the global
# manifest (~/.claude/settings.json) and per-profile manifests (project settings).
sync_claude_plugins() {
  local manifest="$1"
  local settings_path="$2"
  local label="$3"

  [[ -f "$manifest" ]] || return 0
  # Nothing to do if the manifest has no claude section.
  python3 -c 'import json,sys; sys.exit(0 if (json.load(open(sys.argv[1])).get("claude") or {}) else 1)' "$manifest" || return 0

  log_action "$(action_verb "$settings_path")" "$label Claude plugins$([[ "$PRUNE" -eq 1 ]] && echo ' (+prune)')" "$settings_path"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  python3 - "$manifest" "$settings_path" "$PRUNE" <<'PY'
import json, os, sys

manifest_path, settings_path, prune_arg = sys.argv[1:4]
prune = prune_arg == "1"

with open(manifest_path, "r", encoding="utf-8") as f:
    manifest = json.load(f)

claude = manifest.get("claude") or {}
marketplaces = claude.get("marketplaces") or {}
enabled = claude.get("enabled") or []

settings = {}
if os.path.exists(settings_path):
    with open(settings_path, "r", encoding="utf-8") as f:
        text = f.read().strip()
    if text:
        settings = json.loads(text)
    if not isinstance(settings, dict):
        raise SystemExit(f"{settings_path} must contain a JSON object")

changed = False

known = settings.setdefault("extraKnownMarketplaces", {})
if not isinstance(known, dict):
    raise SystemExit(f"{settings_path} extraKnownMarketplaces must be an object")
for name, src in marketplaces.items():
    entry = {"source": src}
    if name not in known:
        known[name] = entry
        changed = True
    elif known[name] != entry:
        sys.stderr.write(
            f"WARNING: {settings_path} already defines marketplace '{name}' "
            f"differently; keeping existing value.\n"
        )

enabled_plugins = settings.setdefault("enabledPlugins", {})
if not isinstance(enabled_plugins, dict):
    raise SystemExit(f"{settings_path} enabledPlugins must be an object")
for plugin in enabled:
    if enabled_plugins.get(plugin) is not True:
        enabled_plugins[plugin] = True
        changed = True

# Prune: within marketplaces THIS manifest manages, drop any enabled plugin that
# is no longer declared. Scoped to managed marketplaces so manually-installed
# plugins (e.g. swift-lsp@claude-plugins-official) are never touched. Marketplace
# registrations are left in place (harmless once no plugin references them).
if prune:
    managed = set(marketplaces.keys())
    desired = set(enabled)
    for key in list(enabled_plugins.keys()):
        mkt = key.split("@", 1)[1] if "@" in key else None
        if mkt in managed and key not in desired:
            del enabled_plugins[key]
            changed = True
            sys.stderr.write(f"  pruned (disabled) plugin '{key}'\n")

if changed:
    os.makedirs(os.path.dirname(settings_path) or ".", exist_ok=True)
    with open(settings_path, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"  updated {settings_path}")
else:
    print(f"  no change {settings_path}")
PY
}

# Apply a plugins manifest's `codex` section (Codex plugins are inherently global):
#   1. Register each marketplace via `codex plugin marketplace add <repo>` (the
#      docs say use the CLI, not hand-edited config.toml). Idempotent / tolerant.
#   2. Enable each plugin declaratively in ~/.codex/config.toml as
#      [plugins."name@marketplace"] enabled = true — the documented on/off store,
#      so no interactive /plugins TUI is required.
#   3. Run any installCommands (e.g. CE's bunx installer for custom agents).
#   4. Print manualSteps as a fallback note.
sync_codex_plugins() {
  local manifest="$1"
  [[ -f "$manifest" ]] || return 0
  python3 -c 'import json,sys; sys.exit(0 if (json.load(open(sys.argv[1])).get("codex") or {}) else 1)' "$manifest" || return 0

  local codex_config="$CODEX_HOME/config.toml"
  log_sub "Codex plugins -> $codex_config (+ CLI marketplace registration)"

  # 1. Register marketplaces via the Codex CLI.
  if command -v codex >/dev/null 2>&1; then
    while IFS= read -r repo; do
      [[ -n "$repo" ]] || continue
      log_action "run" "codex marketplace" "codex plugin marketplace add $repo"
      [[ "$DRY_RUN" -eq 1 ]] || codex plugin marketplace add "$repo" \
        || log_sub "  (marketplace add returned non-zero — likely already registered)"
    done < <(python3 -c 'import json,sys; [print(r) for r in (json.load(open(sys.argv[1])).get("codex",{}).get("marketplaces") or [])]' "$manifest")
  else
    log_sub "  Skipping marketplace registration: 'codex' CLI not found"
  fi

  # 2. Enable plugins declaratively in config.toml (and, with --prune, disable
  #    managed-marketplace plugins no longer in the manifest).
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_action "would-write" "codex enabledPlugins$([[ "$PRUNE" -eq 1 ]] && echo ' (+prune)')" "$codex_config"
  else
    python3 - "$manifest" "$codex_config" "$PRUNE" <<'PY'
import json, os, re, sys

manifest_path, config_path, prune_arg = sys.argv[1:4]
prune = prune_arg == "1"

enabled = (json.load(open(manifest_path)).get("codex") or {}).get("enabled") or []
# With nothing declared we can't derive which marketplaces are "managed", so
# there's nothing to enable and nothing safe to prune.
if not enabled:
    raise SystemExit(0)

text = ""
if os.path.exists(config_path):
    with open(config_path, "r", encoding="utf-8") as f:
        text = f.read()

def set_state(text, plugin, value, create=True):
    """Set [plugins."plugin"] enabled=value, flipping an existing table or (when
    create) appending a new one. Never creates a duplicate table (TOML forbids
    it). Returns (text, changed)."""
    val = "true" if value else "false"
    pat = re.compile(r'(\[plugins\."' + re.escape(plugin) + r'"\]\n)(.*?)(?=\n\[|\Z)', re.S)
    m = pat.search(text)
    if not m:
        if not create:
            return text, False
        return text.rstrip("\n") + ("\n\n" if text.strip() else "") + f'[plugins."{plugin}"]\nenabled = {val}\n', True
    body = m.group(2)
    if re.search(r'^\s*enabled\s*=', body, re.M):
        new_body = re.sub(r'^(\s*enabled\s*=\s*)(?:true|false)\b', r'\1' + val, body, flags=re.M)
    else:
        new_body = f"enabled = {val}\n" + body
    if new_body == body:
        return text, False
    return text[:m.start(2)] + new_body + text[m.end(2):], True

changed_any = False
for plugin in enabled:
    text, changed = set_state(text, plugin, True, create=True)
    changed_any = changed_any or changed

if prune:
    # Managed marketplaces = the marketplace suffixes this manifest declares.
    # Only plugins under those are eligible — manually-installed plugins under
    # other marketplaces (e.g. @openai-curated) are never touched.
    managed = {p.split("@", 1)[1] for p in enabled if "@" in p}
    desired = set(enabled)
    keys = [m.group(1) for m in re.finditer(r'\[plugins\."([^"]+)"\]', text)]
    for key in keys:
        mkt = key.split("@", 1)[1] if "@" in key else None
        if mkt in managed and key not in desired:
            text, changed = set_state(text, key, False, create=False)
            if changed:
                changed_any = True
                sys.stderr.write(f"  pruned (disabled) codex plugin '{key}'\n")

if changed_any:
    os.makedirs(os.path.dirname(config_path) or ".", exist_ok=True)
    with open(config_path, "w", encoding="utf-8") as f:
        f.write(text if text.endswith("\n") else text + "\n")
    print(f"  wrote {config_path}")
else:
    print(f"  no change {config_path}")
PY
  fi

  # 3. Run extra install commands (e.g. bunx for CE custom agents).
  while IFS=$'\t' read -r -a cmd; do
    [[ ${#cmd[@]} -gt 0 ]] || continue
    if ! command -v "${cmd[0]}" >/dev/null 2>&1; then
      log_sub "  Skipping install command ('${cmd[0]}' not found): ${cmd[*]}"
      continue
    fi
    log_action "run" "codex install" "${cmd[*]}"
    [[ "$DRY_RUN" -eq 1 ]] || "${cmd[@]}" || log_sub "  (command returned non-zero: ${cmd[*]})"
  done < <(python3 -c '
import json, sys
for c in (json.load(open(sys.argv[1])).get("codex",{}).get("installCommands") or []):
    print("\t".join(str(a) for a in c))
' "$manifest")

  # 4. Surface any manual fallback steps.
  while IFS= read -r step; do
    [[ -n "$step" ]] && log_sub "  NOTE: $step"
  done < <(python3 -c '
import json, sys
for s in (json.load(open(sys.argv[1])).get("codex",{}).get("manualSteps") or []):
    print(s)
' "$manifest")
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
    --prune)
      PRUNE=1
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

# --- Codex: prompts (skills handled by agents provider) ---
if want_provider "codex"; then
  codex_prompts_dir="$CODEX_HOME/prompts"

  log_section "Codex"
  log_sub "Prompts -> $codex_prompts_dir"
  shopt -s nullglob
  for prompt in "$ROOT/slash-commands"/*.md; do
    [[ -f "$prompt" ]] || continue
    run_copy_file "$prompt" "$codex_prompts_dir/$(basename "$prompt")"
  done
  shopt -u nullglob
fi

# --- Claude Code: skills + commands (does not support .agents/) ---
if want_provider "claude"; then
  claude_commands_dir="$CLAUDE_HOME/commands"
  log_section "Claude"
  sync_skills_to "$CLAUDE_SKILLS_DIR" "Skills"

  log_sub "Commands -> $claude_commands_dir"
  sync_markdown_tree "$ROOT/slash-commands" "$claude_commands_dir"
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

  # Group profiles by project so each project receives the UNION of its
  # assigned profiles' skills and exactly one (correct) prune pass.
  if [[ ${#profile_pairs[@]} -gt 0 ]]; then
    profile_projects="$(printf '%s\n' "${profile_pairs[@]}" | cut -f1 | awk '!seen[$0]++')"
    while IFS= read -r profile_project; do
      [[ -n "$profile_project" ]] || continue
      profile_names_for_project=()
      for pair in "${profile_pairs[@]}"; do
        if [[ "${pair%%$'\t'*}" == "$profile_project" ]]; then
          profile_names_for_project+=("${pair#*$'\t'}")
        fi
      done
      sync_profiles_to_project "${profile_project/#\~/$HOME}" "${profile_names_for_project[@]}"
    done <<< "$profile_projects"
  fi
fi

# --- Plugins: public agent plugins (declarative config, no files vendored) ---
if want_provider "plugins"; then
  log_section "Plugins"
  plugins_manifest="$ROOT/plugins.json"
  if [[ ! -f "$plugins_manifest" ]]; then
    log_sub "Skipping: no plugins.json at repo root"
  else
    log_sub "Manifest -> $plugins_manifest"
    sync_claude_plugins "$plugins_manifest" "$CLAUDE_HOME/settings.json" "global"
    sync_codex_plugins "$plugins_manifest"
  fi
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
