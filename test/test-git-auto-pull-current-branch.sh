#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

HOOK="$ROOT/hooks/scripts/git-auto-pull-current-branch.sh"

assert_contains() {
  local expected="$1"
  local output="$2"
  if [[ "$output" != *"$expected"* ]]; then
    echo "Expected output to contain: $expected" >&2
    echo "--- output ---" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi
}

REPO_NO_UPSTREAM="$TMP_DIR/no-upstream"
mkdir -p "$REPO_NO_UPSTREAM"
(
  cd "$REPO_NO_UPSTREAM"
  git init -q
  git config user.email test@example.com
  git config user.name Test
  printf 'hello\n' > README.md
  git add README.md
  git commit -q -m initial
)

OUTPUT="$(cd "$REPO_NO_UPSTREAM" && "$HOOK" 2>&1)"
assert_contains "agent-scripts auto-pull: skip, " "$OUTPUT"
assert_contains "has no upstream" "$OUTPUT"

REPO_DIRTY="$TMP_DIR/dirty"
REMOTE="$TMP_DIR/remote.git"
git init -q --bare "$REMOTE"
git clone -q "$REMOTE" "$REPO_DIRTY"
(
  cd "$REPO_DIRTY"
  git config user.email test@example.com
  git config user.name Test
  printf 'hello\n' > README.md
  git add README.md
  git commit -q -m initial
  git push -q -u origin HEAD
  printf 'local\n' >> README.md
)

OUTPUT="$(cd "$REPO_DIRTY" && "$HOOK" 2>&1)"
assert_contains "agent-scripts auto-pull: skip, worktree has local changes" "$OUTPUT"

echo "ok"
