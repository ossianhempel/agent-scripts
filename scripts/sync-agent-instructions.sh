#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=0
CREATE_MISSING=0
INCLUDE_SELF=0
ROOT_DIR=""
POINTER_PATH="${POINTER_PATH:-$ROOT/GLOBAL_AGENTS.md}"
POINTER_LINE="READ $POINTER_PATH BEFORE ANYTHING (skip if missing)."

INSTRUCTION_FILES_DEFAULT=(
  "AGENTS.md"
  "CLAUDE.md"
  ".github/copilot-instructions.md"
)
INSTRUCTION_FILES=()
REPOS=()

usage() {
  cat <<'USAGE'
Usage: scripts/sync-agent-instructions.sh [options]

Insert or update the pointer line in instruction files across repos.

Options:
  --root <dir>                Scan for git repos under this directory
  --repo <path>               Add a repo path (repeatable)
  --repos <list>              Comma-separated repo paths
  --files <list>              Comma-separated instruction filenames
  --pointer-path <path>       Override pointer target path
  --create-missing            Create instruction files if missing
  --include-self              Include this agent-scripts repo
  --dry-run                   Print actions without writing files
  -h, --help                  Show this help

Examples:
  scripts/sync-agent-instructions.sh --root ~/code --dry-run
  scripts/sync-agent-instructions.sh --repo ~/code/my-app --create-missing
USAGE
}

log() {
  printf '%s\n' "$*"
}

log_section() {
  printf '== %s ==\n' "$1"
}

log_action() {
  local verb="$1"
  local target="$2"
  printf '  - %s %s\n' "$verb" "$target"
}

normalize_list() {
  local list="$1"
  local -a out=()
  IFS=',' read -r -a out <<< "$list"
  for item in "${out[@]}"; do
    if [[ -n "$item" ]]; then
      printf '%s\n' "$item"
    fi
  done
}

collect_repos_from_root() {
  local base="$1"
  local -a found=()
  local git_path
  while IFS= read -r git_path; do
    found+=("$(dirname "$git_path")")
  done < <(find "$base" -name .git -print)

  if [[ ${#found[@]} -eq 0 ]]; then
    return 0
  fi

  printf '%s\n' "${found[@]}" | awk '!seen[$0]++'
}

prepare_instruction_files() {
  if [[ ${#INSTRUCTION_FILES[@]} -eq 0 ]]; then
    INSTRUCTION_FILES=("${INSTRUCTION_FILES_DEFAULT[@]}")
  fi
}

ensure_pointer() {
  local repo="$1"
  local rel_path="$2"
  local file="$repo/$rel_path"
  local exists=0
  local content=""
  local filtered=""
  local new_content=""
  local verb=""

  if [[ -f "$file" ]]; then
    exists=1
    content=$(cat "$file")
  else
    if [[ "$CREATE_MISSING" -eq 0 ]]; then
      return 0
    fi
  fi

  filtered=$(printf '%s\n' "$content" | awk -v pointer="$POINTER_LINE" '$0 != pointer {print}')
  filtered=$(printf '%s\n' "$filtered" | awk 'BEGIN{skip=1} {if (skip && $0=="") next; skip=0; print}')

  if [[ -n "$filtered" ]]; then
    new_content="${POINTER_LINE}"$'\n\n'"$filtered"
  else
    new_content="${POINTER_LINE}"$'\n'
  fi

  if [[ "$exists" -eq 1 && "$content" == "$new_content" ]]; then
    log_action "skip" "$rel_path"
    return 0
  fi

  if [[ "$exists" -eq 1 ]]; then
    verb="update"
  else
    verb="create"
  fi

  log_action "$verb" "$rel_path"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$file")"
  printf '%s' "$new_content" > "$file"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --root)
      ROOT_DIR="$2"
      shift 2
      ;;
    --repo)
      REPOS+=("$2")
      shift 2
      ;;
    --repos)
      while IFS= read -r item; do
        REPOS+=("$item")
      done < <(normalize_list "$2")
      shift 2
      ;;
    --files)
      while IFS= read -r item; do
        INSTRUCTION_FILES+=("$item")
      done < <(normalize_list "$2")
      shift 2
      ;;
    --pointer-path)
      POINTER_PATH="$2"
      POINTER_LINE="READ $POINTER_PATH BEFORE ANYTHING (skip if missing)."
      shift 2
      ;;
    --create-missing)
      CREATE_MISSING=1
      shift
      ;;
    --include-self)
      INCLUDE_SELF=1
      shift
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

prepare_instruction_files

if [[ ${#REPOS[@]} -eq 0 ]]; then
  if [[ -z "$ROOT_DIR" ]]; then
    log "No repos specified. Provide --root or --repo."
    exit 1
  fi
  while IFS= read -r repo; do
    REPOS+=("$repo")
  done < <(collect_repos_from_root "$ROOT_DIR")
fi

if [[ ${#REPOS[@]} -eq 0 ]]; then
  log "No repos found."
  exit 0
fi

for repo in "${REPOS[@]}"; do
  repo="$(cd "$repo" 2>/dev/null && pwd || true)"
  if [[ -z "$repo" ]]; then
    continue
  fi
  if [[ "$INCLUDE_SELF" -eq 0 && "$repo" == "$ROOT" ]]; then
    continue
  fi
  if [[ ! -e "$repo/.git" ]]; then
    continue
  fi

  log_section "Repo: $repo"
  for rel_path in "${INSTRUCTION_FILES[@]}"; do
    ensure_pointer "$repo" "$rel_path"
  done
  printf '\n'
done

log "Done."
