#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

POINTER="READ $ROOT/GLOBAL_AGENTS.md BEFORE ANYTHING (skip if missing)."

REPO_ONE="$TMP_DIR/repo-one"
REPO_TWO="$TMP_DIR/repo-two"
REPO_THREE="$TMP_DIR/repo-three"
mkdir -p "$REPO_ONE/.git" "$REPO_TWO/.git" "$REPO_THREE/.git" "$REPO_ONE/.github"

cat <<'TXT' > "$REPO_ONE/AGENTS.md"
Local instructions for repo one.
TXT

cat <<'TXT' > "$REPO_ONE/CLAUDE.md"
Some Claude notes.
TXT

cat <<'TXT' > "$REPO_ONE/.github/copilot-instructions.md"
Copilot rules.
TXT

cat <<TXT > "$REPO_TWO/AGENTS.md"
$POINTER

Existing local instructions.
TXT

# Dry run should not change files
BEFORE_HASH=$(shasum -a 256 "$REPO_ONE/AGENTS.md" | awk '{print $1}')
"$ROOT/scripts/sync-agent-instructions.sh" --root "$TMP_DIR" --dry-run > "$TMP_DIR/output.txt"
AFTER_HASH=$(shasum -a 256 "$REPO_ONE/AGENTS.md" | awk '{print $1}')
if [[ "$BEFORE_HASH" != "$AFTER_HASH" ]]; then
  echo "Dry run modified file" >&2
  exit 1
fi

# Real run
"$ROOT/scripts/sync-agent-instructions.sh" --root "$TMP_DIR" > /dev/null

if [[ -f "$REPO_THREE/AGENTS.md" ]]; then
  echo "Unexpected file creation without --create-missing" >&2
  exit 1
fi

assert_pointer_first() {
  local file="$1"
  local first_line
  first_line=$(head -n 1 "$file")
  if [[ "$first_line" != "$POINTER" ]]; then
    echo "Pointer not first in $file" >&2
    exit 1
  fi
}

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! rg -F --quiet -- "$expected" "$file"; then
    echo "Expected content missing in $file" >&2
    exit 1
  fi
}

assert_pointer_first "$REPO_ONE/AGENTS.md"
assert_contains "$REPO_ONE/AGENTS.md" "Local instructions for repo one."

assert_pointer_first "$REPO_ONE/CLAUDE.md"
assert_contains "$REPO_ONE/CLAUDE.md" "Some Claude notes."

assert_pointer_first "$REPO_ONE/.github/copilot-instructions.md"
assert_contains "$REPO_ONE/.github/copilot-instructions.md" "Copilot rules."

assert_pointer_first "$REPO_TWO/AGENTS.md"
assert_contains "$REPO_TWO/AGENTS.md" "Existing local instructions."

# Create-missing run
"$ROOT/scripts/sync-agent-instructions.sh" --root "$TMP_DIR" --create-missing > /dev/null

assert_pointer_first "$REPO_THREE/AGENTS.md"

echo "ok"
