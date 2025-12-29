#!/usr/bin/env bash
set -euo pipefail

# Determine the agent-scripts repo root (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_SCRIPTS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ROOT_ARG="."
EXTRA_ARGS=()
if [[ $# -gt 0 && "${1:-}" != -* ]]; then
  ROOT_ARG="$1"
  shift
fi
EXTRA_ARGS=("$@")
FORMAT="${FORMAT:-markdown}"
OUT="${OUT:-.agent-readiness/latest.json}"

CLI_PATH="$AGENT_SCRIPTS_ROOT/tools/agent-readiness/dist/cli.js"
SRC_DIR="$AGENT_SCRIPTS_ROOT/tools/agent-readiness/src"
NEEDS_BUILD=0

if [[ ! -f "$CLI_PATH" || ! -d "$AGENT_SCRIPTS_ROOT/tools/agent-readiness/node_modules" ]]; then
  NEEDS_BUILD=1
elif find "$SRC_DIR" -type f -newer "$CLI_PATH" -print -quit | grep -q .; then
  NEEDS_BUILD=1
fi

if [[ "$NEEDS_BUILD" -eq 1 ]]; then
  echo "Building agent-readiness CLI..." >&2
  (cd "$AGENT_SCRIPTS_ROOT/tools/agent-readiness" && npm install && npm run build)
fi

node "$CLI_PATH" report --format "$FORMAT" --out "$OUT" --root "$ROOT_ARG" "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
