#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ]; then
  echo "Not inside a git repository." >&2
  exit 1
fi

cd "$ROOT"

if [ ! -d "$ROOT/.githooks" ]; then
  echo "Missing .githooks directory." >&2
  exit 1
fi

git config core.hooksPath .githooks
chmod +x \
  "$ROOT/.githooks/post-merge" \
  "$ROOT/.githooks/post-checkout" \
  "$ROOT/.githooks/post-rewrite" \
  "$ROOT/.githooks/run-sync-if-needed.sh"

echo "Hooks installed: core.hooksPath=.githooks"
