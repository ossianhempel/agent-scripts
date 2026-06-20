#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_contains() {
  local expected="$1"
  local file="$2"
  if ! rg -F --quiet -- "$expected" "$file"; then
    echo "Expected to find: $expected" >&2
    echo "--- output ---" >&2
    cat "$file" >&2
    exit 1
  fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

"$ROOT/bin/mcp-as-cli" > "$TMP_DIR/help.txt"
assert_contains "run MCP tools on demand through mcporter" "$TMP_DIR/help.txt"

if "$ROOT/bin/mcp-as-cli" list --persist "$TMP_DIR/mcporter.json" > "$TMP_DIR/persist.txt" 2>&1; then
  echo "Expected --persist guard to fail" >&2
  exit 1
fi
assert_contains "refusing persistent mcporter config writes" "$TMP_DIR/persist.txt"

if "$ROOT/bin/mcp-as-cli" daemon status > "$TMP_DIR/daemon.txt" 2>&1; then
  echo "Expected daemon guard to fail" >&2
  exit 1
fi
assert_contains "refusing persistent mcporter 'daemon' mode" "$TMP_DIR/daemon.txt"

echo "ok"
