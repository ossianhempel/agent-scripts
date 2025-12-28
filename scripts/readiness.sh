#!/usr/bin/env bash
set -euo pipefail

ROOT_ARG="${1:-.}"
FORMAT="${FORMAT:-markdown}"
OUT="${OUT:-.agent-readiness/latest.json}"

if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$ROOT_ARG"
fi

cd "$REPO_ROOT"

CLI_PATH="tools/agent-readiness/dist/cli.js"
SRC_DIR="tools/agent-readiness/src"
NEEDS_BUILD=0

if [[ ! -f "$CLI_PATH" || ! -d "tools/agent-readiness/node_modules" ]]; then
  NEEDS_BUILD=1
elif find "$SRC_DIR" -type f -newer "$CLI_PATH" -print -quit | grep -q .; then
  NEEDS_BUILD=1
fi

if [[ "$NEEDS_BUILD" -eq 1 ]]; then
  echo "Building agent-readiness CLI..." >&2
  (cd tools/agent-readiness && npm install && npm run build)
fi

node "$CLI_PATH" report --format "$FORMAT" --out "$OUT"
