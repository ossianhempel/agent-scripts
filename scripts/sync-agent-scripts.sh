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

Sync skills/ and slash-commands/ from this repo into supported agent runtimes.

Skills sync to ~/.agents/skills (cross-tool standard, read by Codex, Gemini,
Cursor, Copilot, Windsurf) and ~/.claude/skills (Claude Code only).
Commands/prompts sync to each tool's native location.

Options:
  --providers <list>          Comma-separated providers (agents,codex,claude,gemini,cursor,copilot)
  --provider <name>           Add a single provider (repeatable)
  --agents-home <path>        Override agents home (default: ~/.agents)
  --agents-skills-dir <path>  Override agents skills directory (default: ~/.agents/skills)
  --agents-scope <scope>      Agents scope: global, project, or both (default: global)
  --claude-home <path>        Override Claude home (default: ~/.claude)
  --claude-skills-dir <path>  Override Claude skills directory (default: ~/.claude/skills)
  --codex-home <path>         Override Codex home (default: ~/.codex)
  --gemini-home <path>        Override Gemini home (default: ~/.gemini)
  --cursor-commands-dir <path>Override Cursor project commands dir (default: ./.cursor/commands)
  --cursor-scope <scope>      Cursor scope: project, global, or both (default: global)
  --copilot-prompts-dir <path>Override Copilot workspace prompts dir (default: ./.github/prompts)
  --copilot-user-prompts-dir <path>Override Copilot user prompts dir (required for user scope)
  --copilot-scope <scope>     Copilot scope: workspace, user, both, or none (default: none)
  --dry-run                   Print actions without writing files
  -h, --help                  Show this help

Examples:
  scripts/sync-agent-scripts.sh
  scripts/sync-agent-scripts.sh --providers agents,claude
  scripts/sync-agent-scripts.sh --provider agents --agents-scope both
  scripts/sync-agent-scripts.sh --provider copilot --copilot-scope workspace
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

log_sync_summary() {
  local verb="$1"
  local label="$2"
  local count="$3"
  printf '  - %s skill %s (%s files)\n' "$verb" "$label" "$count"
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

dirs_identical() {
  local src="$1"
  local dest="$2"
  if [[ ! -d "$dest" ]]; then
    return 1
  fi
  diff -qr --exclude='feedback.log' "$src" "$dest" >/dev/null 2>&1
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

run_sync_dir() {
  local src="$1"
  local dest="$2"
  local label="${3:-}"
  local count
  local verb

  if dirs_identical "$src" "$dest"; then
    return 0
  fi

  count=$(find "$src" -type f | wc -l | tr -d ' ')
  verb=$(action_verb "$dest")
  if [[ -n "$label" ]]; then
    log_sync_summary "$verb" "$label" "$count"
  else
    log_action "$verb" "$src" "$dest ($count files)"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  # Preserve destination feedback.log (written by agents during sessions)
  local saved_feedback=""
  if [[ -f "$dest/feedback.log" ]]; then
    saved_feedback=$(mktemp)
    cp -f "$dest/feedback.log" "$saved_feedback"
  fi

  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"

  # Restore preserved feedback.log
  if [[ -n "$saved_feedback" ]]; then
    cp -f "$saved_feedback" "$dest/feedback.log"
    rm -f "$saved_feedback"
  fi
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

  if [[ ! -d "$src_root" ]]; then
    log "Skipping: missing source $src_root"
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

sync_skills_to() {
  local dest_dir="$1"
  local label="$2"
  log_sub "$label -> $dest_dir"
  shopt -s nullglob
  for skill_dir in "$ROOT/skills"/*; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    run_sync_dir "$skill_dir" "$dest_dir/$skill_name" "$skill_name"
  done
  shopt -u nullglob
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
  PROVIDERS=(agents codex claude gemini cursor copilot)
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

# --- Codex: prompts only (skills handled by agents provider) ---
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

  update_gemini_settings "$GEMINI_HOME/settings.json" "$GEMINI_CONTEXT_FILE_DEFAULT"
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

log "Done."
