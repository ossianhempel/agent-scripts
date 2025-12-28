#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

HOME_DIR="$TMP_DIR/home"
WORKSPACE_DIR="$TMP_DIR/workspace"
mkdir -p "$HOME_DIR" "$WORKSPACE_DIR"

OUTPUT_FILE="$TMP_DIR/output.txt"

(
  cd "$WORKSPACE_DIR"
  HOME="$HOME_DIR" \
  "$ROOT/scripts/sync-agent-scripts.sh" --dry-run --providers codex,claude,gemini,cursor,copilot
) > "$OUTPUT_FILE"

assert_contains() {
  local expected="$1"
  if ! rg -F --quiet -- "$expected" "$OUTPUT_FILE"; then
    echo "Expected to find: $expected" >&2
    echo "--- output ---" >&2
    cat "$OUTPUT_FILE" >&2
    exit 1
  fi
}

assert_not_contains() {
  local unexpected="$1"
  if rg -F --quiet -- "$unexpected" "$OUTPUT_FILE"; then
    echo "Expected not to find: $unexpected" >&2
    echo "--- output ---" >&2
    cat "$OUTPUT_FILE" >&2
    exit 1
  fi
}

assert_contains "Skills -> $HOME_DIR/.codex/skills"
assert_contains "Skills -> $HOME_DIR/.claude/skills"
assert_contains "Global skills -> $HOME_DIR/.cursor/skills"
assert_contains "- create skill create-cli ("
assert_contains "- create $ROOT/slash-commands/commit.md -> $HOME_DIR/.claude/commands/commit.md"
assert_contains "- create $ROOT/slash-commands/commit.md -> $HOME_DIR/.gemini/commands/commit.toml"
assert_contains "- create $ROOT/slash-commands/commit.md -> $HOME_DIR/.cursor/commands/commit.md"
assert_not_contains "$WORKSPACE_DIR/.cursor/commands"
assert_not_contains "$WORKSPACE_DIR/.codex"
assert_not_contains "$WORKSPACE_DIR/.claude"
assert_not_contains "$WORKSPACE_DIR/.gemini"
assert_not_contains "$WORKSPACE_DIR/.cursor"
assert_contains "Skipping skills: set COPILOT_SKILLS_DIR"
assert_contains "Skipping prompts: set --copilot-scope and a prompts dir."
assert_not_contains "$WORKSPACE_DIR/.github/skills"
assert_not_contains "$WORKSPACE_DIR/.github/prompts"

OUTPUT_FILE="$TMP_DIR/output-skills.txt"

(
  cd "$WORKSPACE_DIR"
  HOME="$HOME_DIR" \
  COPILOT_SKILLS_DIR="$WORKSPACE_DIR/.github/skills" \
  "$ROOT/scripts/sync-agent-scripts.sh" --dry-run --providers copilot
) > "$OUTPUT_FILE"

assert_contains "- create skill create-cli ("

OUTPUT_FILE="$TMP_DIR/output-prompts.txt"

(
  cd "$WORKSPACE_DIR"
  HOME="$HOME_DIR" \
  COPILOT_PROMPTS_DIR="$WORKSPACE_DIR/.github/prompts" \
  "$ROOT/scripts/sync-agent-scripts.sh" --dry-run --providers copilot --copilot-scope workspace
) > "$OUTPUT_FILE"

assert_contains "- create $ROOT/slash-commands/commit.md -> $WORKSPACE_DIR/.github/prompts/commit.prompt.md"

OUTPUT_FILE="$TMP_DIR/output-copilot-default.txt"

(
  cd "$ROOT"
  HOME="$HOME_DIR" \
  "$ROOT/scripts/sync-agent-scripts.sh" --dry-run --providers copilot
) > "$OUTPUT_FILE"

assert_contains "Skipping prompts: set --copilot-scope and a prompts dir."
assert_not_contains "Workspace prompts -> $ROOT/.github/prompts"
assert_not_contains "-> $ROOT/.github/prompts/"
assert_not_contains "-> $ROOT/.github/skills/"

echo "ok"
