#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ]; then
  exit 0
fi

cd "$ROOT"

SYNC_SCRIPT="$ROOT/scripts/sync-agent-scripts.sh"
if [ ! -f "$SYNC_SCRIPT" ]; then
  exit 0
fi

RANGE=""
if [ -n "${1-}" ] && [ -n "${2-}" ]; then
  if git cat-file -e "$1^{commit}" 2>/dev/null && git cat-file -e "$2^{commit}" 2>/dev/null; then
    RANGE="$1..$2"
  fi
fi

if [ -z "$RANGE" ] && git rev-parse --verify -q ORIG_HEAD >/dev/null; then
  RANGE="ORIG_HEAD..HEAD"
fi

if [ -n "$RANGE" ]; then
  if ! git diff --name-only "$RANGE" -- skills slash-commands scripts | grep -q .; then
    exit 0
  fi
fi

bash "$SYNC_SCRIPT"
