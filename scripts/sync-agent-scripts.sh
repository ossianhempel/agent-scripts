#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=0
PROVIDERS=()
SECTION_STARTED=0

RUN_DIR="$(pwd)"
COPILOT_PROMPTS_DIR="${COPILOT_PROMPTS_DIR:-}"
COPILOT_USER_PROMPTS_DIR="${COPILOT_USER_PROMPTS_DIR:-}"
COPILOT_SKILLS_DIR="${COPILOT_SKILLS_DIR:-}"
CURSOR_COMMANDS_DIR="${CURSOR_COMMANDS_DIR:-}"
CURSOR_SKILLS_DIR="${CURSOR_SKILLS_DIR:-}"
CURSOR_SCOPE="${CURSOR_SCOPE:-global}"
COPILOT_SCOPE="${COPILOT_SCOPE:-none}"

usage() {
  cat <<'USAGE'
Usage: scripts/sync-agent-scripts.sh [options]

Sync skills/ and slash-commands/ from this repo into supported agent runtimes.

Options:
  --providers <list>          Comma-separated providers (codex,claude,gemini,cursor,copilot)
  --provider <name>           Add a single provider (repeatable)
  --codex-home <path>         Override Codex home (default: ~/.codex)
  --claude-home <path>        Override Claude home (default: ~/.claude)
  --claude-skills-dir <path>  Override Claude skills directory (default: ~/.claude/skills)
  --gemini-home <path>        Override Gemini home (default: ~/.gemini)
  --cursor-commands-dir <path>Override Cursor project commands dir (default: ./.cursor/commands)
  --cursor-skills-dir <path>  Override Cursor project skills dir (default: ./.cursor/skills)
  --cursor-scope <scope>      Cursor scope: project, global, or both (default: global)
  --copilot-prompts-dir <path>Override Copilot workspace prompts dir (default: ./.github/prompts)
  --copilot-user-prompts-dir <path>Override Copilot user prompts dir (required for user scope)
  --copilot-skills-dir <path> Set Copilot skills dir (default: none)
  --copilot-scope <scope>     Copilot scope: workspace, user, both, or none (default: none)
  --dry-run                   Print actions without writing files
  -h, --help                  Show this help

Examples:
  scripts/sync-agent-scripts.sh
  scripts/sync-agent-scripts.sh --providers codex,claude
  COPILOT_PROMPTS_DIR=~/work/myrepo/.github/prompts scripts/sync-agent-scripts.sh --provider copilot
  scripts/sync-agent-scripts.sh --provider cursor --cursor-scope global
  scripts/sync-agent-scripts.sh --provider copilot --copilot-scope user --copilot-user-prompts-dir ~/Library/Application\\ Support/Code/User/profiles/Default
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

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

run_copy_file() {
  local src="$1"
  local dest="$2"
  local verb
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
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
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

  log_action "$(action_verb "$dest")" "$src" "$dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  {
    printf 'description = "%s"\n\n' "$desc"
    printf 'prompt = """\n'
    printf '%s\n' "$body"
    printf '"""\n'
  } > "$dest"
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

  log_action "$(action_verb "$dest")" "$src" "$dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  {
    printf '---\n'
    printf 'mode: agent\n'
    printf 'description: "%s"\n' "$desc"
    printf '---\n\n'
    printf '%s\n' "$body"
  } > "$dest"
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

CODEX_HOME_DEFAULT="$HOME/.codex"
CLAUDE_HOME_DEFAULT="$HOME/.claude"
GEMINI_HOME_DEFAULT="$HOME/.gemini"
GEMINI_CONTEXT_FILE_DEFAULT="AGENTS.md"

CODEX_HOME="$CODEX_HOME_DEFAULT"
CLAUDE_HOME="$CLAUDE_HOME_DEFAULT"
GEMINI_HOME="$GEMINI_HOME_DEFAULT"
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
    --cursor-skills-dir)
      CURSOR_SKILLS_DIR="$2"
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
    --copilot-skills-dir)
      COPILOT_SKILLS_DIR="$2"
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
  PROVIDERS=(codex claude gemini cursor copilot)
fi

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

if want_provider "codex"; then
  local_skills_dir="$ROOT/skills"
  local_prompts_dir="$ROOT/slash-commands"
  codex_skills_dir="$CODEX_HOME/skills"
  codex_prompts_dir="$CODEX_HOME/prompts"

  log_section "Codex"
  log_sub "Skills -> $codex_skills_dir"
  shopt -s nullglob
  for skill_dir in "$local_skills_dir"/*; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    run_sync_dir "$skill_dir" "$codex_skills_dir/$skill_name" "$skill_name"
  done

  log_sub "Prompts -> $codex_prompts_dir"
  for prompt in "$local_prompts_dir"/*.md; do
    [[ -f "$prompt" ]] || continue
    run_copy_file "$prompt" "$codex_prompts_dir/$(basename "$prompt")"
  done
  shopt -u nullglob
fi

if want_provider "claude"; then
  claude_commands_dir="$CLAUDE_HOME/commands"
  log_section "Claude"
  log_sub "Skills -> $CLAUDE_SKILLS_DIR"
  shopt -s nullglob
  for skill_dir in "$ROOT/skills"/*; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    run_sync_dir "$skill_dir" "$CLAUDE_SKILLS_DIR/$skill_name" "$skill_name"
  done
  shopt -u nullglob

  log_sub "Commands -> $claude_commands_dir"
  sync_markdown_tree "$ROOT/slash-commands" "$claude_commands_dir"
fi

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

if want_provider "cursor"; then
  if [[ -z "$CURSOR_COMMANDS_DIR" ]]; then
    CURSOR_COMMANDS_DIR="$RUN_DIR/.cursor/commands"
  fi
  if [[ -z "$CURSOR_SKILLS_DIR" ]]; then
    CURSOR_SKILLS_DIR="$RUN_DIR/.cursor/skills"
  fi

  log_section "Cursor"

  if scope_has "$CURSOR_SCOPE" "project"; then
    log_sub "Project skills -> $CURSOR_SKILLS_DIR"
    shopt -s nullglob
    for skill_dir in "$ROOT/skills"/*; do
      [[ -d "$skill_dir" ]] || continue
      skill_name="$(basename "$skill_dir")"
      run_sync_dir "$skill_dir" "$CURSOR_SKILLS_DIR/$skill_name" "$skill_name"
    done
    shopt -u nullglob

    log_sub "Project commands -> $CURSOR_COMMANDS_DIR"
    sync_markdown_tree "$ROOT/slash-commands" "$CURSOR_COMMANDS_DIR"
  fi

  if scope_has "$CURSOR_SCOPE" "global"; then
    global_cursor_skills_dir="$HOME/.cursor/skills"
    global_cursor_commands_dir="$HOME/.cursor/commands"
    log_sub "Global skills -> $global_cursor_skills_dir"
    shopt -s nullglob
    for skill_dir in "$ROOT/skills"/*; do
      [[ -d "$skill_dir" ]] || continue
      skill_name="$(basename "$skill_dir")"
      run_sync_dir "$skill_dir" "$global_cursor_skills_dir/$skill_name" "$skill_name"
    done
    shopt -u nullglob

    log_sub "Global commands -> $global_cursor_commands_dir"
    sync_markdown_tree "$ROOT/slash-commands" "$global_cursor_commands_dir"
  fi
fi

if want_provider "copilot"; then
  log_section "Copilot"

  if [[ -z "$COPILOT_SKILLS_DIR" ]]; then
    log_sub "Skipping skills: set COPILOT_SKILLS_DIR or --copilot-skills-dir."
  else
    log_sub "Skills -> $COPILOT_SKILLS_DIR"
    shopt -s nullglob
    for skill_dir in "$ROOT/skills"/*; do
      [[ -d "$skill_dir" ]] || continue
      skill_name="$(basename "$skill_dir")"
      run_sync_dir "$skill_dir" "$COPILOT_SKILLS_DIR/$skill_name" "$skill_name"
    done
    shopt -u nullglob
  fi

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
