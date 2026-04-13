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
  "$ROOT/scripts/sync-agent-scripts.sh" --dry-run --providers agents,codex,claude,gemini,cursor,copilot
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

# Agents provider syncs skills to ~/.agents/skills
assert_contains "Global skills -> $HOME_DIR/.agents/skills"
assert_contains "- create skill ios-simulator ("

# Claude provider syncs skills to ~/.claude/skills and commands
assert_contains "Skills -> $HOME_DIR/.claude/skills"
assert_contains "- create $ROOT/slash-commands/commit.md -> $HOME_DIR/.claude/commands/commit.md"

# Codex provider syncs prompts only (no skills)
assert_contains "Prompts -> $HOME_DIR/.codex/prompts"
assert_not_contains "Skills -> $HOME_DIR/.codex/skills"

# Gemini provider syncs commands only (no skills)
assert_contains "- create $ROOT/slash-commands/commit.md -> $HOME_DIR/.gemini/commands/commit.toml"
assert_contains "- create contextFileName -> $HOME_DIR/.gemini/settings.json"
assert_not_contains "Skills -> $HOME_DIR/.gemini/skills"

# Cursor provider syncs global commands only (no skills)
assert_contains "Global commands -> $HOME_DIR/.cursor/commands"
assert_contains "- create $ROOT/slash-commands/commit.md -> $HOME_DIR/.cursor/commands/commit.md"
assert_not_contains "Global skills -> $HOME_DIR/.cursor/skills"

# No project-scoped files in workspace
assert_not_contains "$WORKSPACE_DIR/.cursor/commands"
assert_not_contains "$WORKSPACE_DIR/.agents/skills"

# Copilot defaults to no prompts
assert_contains "Skipping prompts: set --copilot-scope and a prompts dir."
assert_not_contains "$WORKSPACE_DIR/.github/prompts"

# --- Copilot prompts ---
OUTPUT_FILE="$TMP_DIR/output-prompts.txt"

(
  cd "$WORKSPACE_DIR"
  HOME="$HOME_DIR" \
  COPILOT_PROMPTS_DIR="$WORKSPACE_DIR/.github/prompts" \
  "$ROOT/scripts/sync-agent-scripts.sh" --dry-run --providers copilot --copilot-scope workspace
) > "$OUTPUT_FILE"

assert_contains "- create $ROOT/slash-commands/commit.md -> $WORKSPACE_DIR/.github/prompts/commit.prompt.md"

# --- Agents project scope ---
OUTPUT_FILE="$TMP_DIR/output-project.txt"

(
  cd "$WORKSPACE_DIR"
  HOME="$HOME_DIR" \
  "$ROOT/scripts/sync-agent-scripts.sh" --dry-run --providers agents --agents-scope project
) > "$OUTPUT_FILE"

assert_contains "Project skills -> $WORKSPACE_DIR/.agents/skills"
assert_contains "- create skill ios-simulator ("

# --- Copilot default scope ---
OUTPUT_FILE="$TMP_DIR/output-copilot-default.txt"

(
  cd "$ROOT"
  HOME="$HOME_DIR" \
  "$ROOT/scripts/sync-agent-scripts.sh" --dry-run --providers copilot
) > "$OUTPUT_FILE"

assert_contains "Skipping prompts: set --copilot-scope and a prompts dir."
assert_not_contains "Workspace prompts -> $ROOT/.github/prompts"
assert_not_contains "-> $ROOT/.github/prompts/"

# --- Idempotency: second sync produces no changes ---
OUTPUT_FILE="$TMP_DIR/output-skip-identical.txt"

(
  cd "$WORKSPACE_DIR"
  HOME="$HOME_DIR" \
  "$ROOT/scripts/sync-agent-scripts.sh" --providers agents,codex,claude,gemini,cursor
) >/dev/null

(
  cd "$WORKSPACE_DIR"
  HOME="$HOME_DIR" \
  "$ROOT/scripts/sync-agent-scripts.sh" --dry-run --providers agents,codex,claude,gemini,cursor
) > "$OUTPUT_FILE"

assert_not_contains "- create skill"
assert_not_contains "- update skill"
assert_not_contains "- create $ROOT/slash-commands/commit.md -> $HOME_DIR/.claude/commands/commit.md"
assert_not_contains "- update $ROOT/slash-commands/commit.md -> $HOME_DIR/.claude/commands/commit.md"
assert_not_contains "- create $ROOT/slash-commands/commit.md -> $HOME_DIR/.gemini/commands/commit.toml"
assert_not_contains "- update $ROOT/slash-commands/commit.md -> $HOME_DIR/.gemini/commands/commit.toml"
assert_not_contains "- create $ROOT/slash-commands/commit.md -> $HOME_DIR/.cursor/commands/commit.md"
assert_not_contains "- update $ROOT/slash-commands/commit.md -> $HOME_DIR/.cursor/commands/commit.md"

echo "ok"
