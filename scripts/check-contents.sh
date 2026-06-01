#!/usr/bin/env bash
set -euo pipefail

# Enforces the consistency invariant borrowed from mattpocock/skills:
# every skill that lives in skills/<name>/SKILL.md must be listed in the
# README "## Contents > Skills" block, and nothing else may be listed there.
#
#   check-contents.sh           verify; exit 1 (and print the drift) on mismatch
#   check-contents.sh --fix     rewrite the README Skills list to match skills/
#
# Scope is intentionally limited to the Skills list, which has a single
# source of truth (skills/*/SKILL.md). Slash commands and tools have no such
# canonical directory, so they are left to manual maintenance.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$ROOT/README.md"

FIX=0
case "${1:-}" in
  --fix) FIX=1 ;;
  "" ) ;;
  -h|--help)
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "error: unknown argument '$1' (use --fix or --help)" >&2
    exit 2
    ;;
esac

# Actual skills: every directory under skills/ that has a SKILL.md, sorted.
actual="$(
  for d in "$ROOT"/skills/*/; do
    [ -f "$d/SKILL.md" ] && basename "$d"
  done | LC_ALL=C sort
)"

# Listed skills: the bullet items in the README "Skills" sub-block of "## Contents".
listed="$(
  awk '
    $0 == "Skills" { grab = 1; next }
    grab && /^- / { line = $0; sub(/^- `/, "", line); sub(/`.*/, "", line); print line; next }
    grab && !/^- / { exit }
  ' "$README" | LC_ALL=C sort
)"

if [ "$actual" = "$listed" ]; then
  echo "README Contents > Skills is in sync ($(echo "$actual" | grep -c . ) skills)."
  exit 0
fi

missing="$(LC_ALL=C comm -23 <(echo "$actual") <(echo "$listed"))"
extra="$(LC_ALL=C comm -13 <(echo "$actual") <(echo "$listed"))"

if [ "$FIX" -eq 0 ]; then
  echo "README Contents > Skills is OUT OF SYNC with skills/." >&2
  [ -n "$missing" ] && { echo "  missing from README:" >&2; echo "$missing" | sed 's/^/    + /' >&2; }
  [ -n "$extra" ]   && { echo "  listed but not in skills/:" >&2; echo "$extra" | sed 's/^/    - /' >&2; }
  echo "Run: scripts/check-contents.sh --fix" >&2
  exit 1
fi

# --fix: replace the Skills sub-block with the freshly generated list.
# The list is passed via a file because BSD awk rejects newlines in -v vars.
listfile="$(mktemp)"
echo "$actual" | sed 's/^/- `/; s/$/`/' > "$listfile"

tmp="$(mktemp)"
awk -v lf="$listfile" '
  $0 == "Skills" { print; while ((getline l < lf) > 0) print l; close(lf); skip = 1; next }
  skip && /^- / { next }
  skip && !/^- / { skip = 0 }
  { print }
' "$README" > "$tmp"

mv "$tmp" "$README"
rm -f "$listfile"
echo "Rewrote README Contents > Skills ($(echo "$actual" | grep -c .) skills)."
[ -n "$missing" ] && { echo "  added:"; echo "$missing" | sed 's/^/    + /'; }
[ -n "$extra" ]   && { echo "  removed:"; echo "$extra" | sed 's/^/    - /'; }
exit 0
