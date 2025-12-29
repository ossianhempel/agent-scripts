#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Create a minimal test repo
TEST_REPO="$TMP_DIR/test-repo"
mkdir -p "$TEST_REPO"
(cd "$TEST_REPO" && git init -q)

cat <<'EOF' > "$TEST_REPO/README.md"
# Test Repo

## Running
npm start

## Building
npm build

## Testing
npm test
EOF

cat <<'EOF' > "$TEST_REPO/package.json"
{
  "name": "test-repo",
  "scripts": {
    "test": "jest"
  }
}
EOF

# Test 1: Run with just a path argument (no extra args)
# This is the case that triggered the EXTRA_ARGS[@] unbound variable bug
echo "Test 1: Running with path argument only..."
OUTPUT=$("$ROOT/scripts/readiness.sh" "$TEST_REPO" 2>&1) || {
  echo "FAIL: Script failed with path argument only" >&2
  echo "Output: $OUTPUT" >&2
  exit 1
}

if [[ "$OUTPUT" != *"Agent Readiness Report"* ]]; then
  echo "FAIL: Expected report output" >&2
  echo "Output: $OUTPUT" >&2
  exit 1
fi

# Test 2: Run with default path (current directory)
echo "Test 2: Running from test repo directory..."
ERROR_OUTPUT=$(cd "$TEST_REPO" && "$ROOT/scripts/readiness.sh" 2>&1) || {
  echo "FAIL: Script failed when run from repo directory" >&2
  echo "Error: $ERROR_OUTPUT" >&2
  exit 1
}

# Test 3: Run with extra arguments
echo "Test 3: Running with extra arguments..."
FORMAT=json "$ROOT/scripts/readiness.sh" "$TEST_REPO" > /dev/null 2>&1 || {
  echo "FAIL: Script failed with extra arguments" >&2
  exit 1
}

echo "ok"
