#!/usr/bin/env bash
set -euo pipefail

# Accepts two optional parameters: starting ref (tag or commit) and ending ref (defaults to HEAD)
START_REF="${1:-}"
END_REF="${2:-HEAD}"

# If no starting ref provided, try to find the most recent tag
if [ -z "$START_REF" ]; then
  if git describe --tags --abbrev=0 >/dev/null 2>&1; then
    START_REF=$(git describe --tags --abbrev=0)
  else
    # No tags exist, use full history
    START_REF=""
  fi
fi

# Construct the git range
if [ -z "$START_REF" ]; then
  RANGE="$END_REF"
else
  RANGE="$START_REF..$END_REF"
fi

# Display repository root
echo "Repository: $(git rev-parse --show-toplevel)"
echo ""

# Display commit range
echo "Commit range: $RANGE"
echo ""

# Display commits with hash, date, and message
echo "=== Commits ==="
git log "$RANGE" --pretty=format:"%h | %ad | %s" --date=short
echo ""
echo ""

# Display all modified files
echo "=== Modified Files ==="
git log "$RANGE" --name-only --pretty=format: | sort -u | sed '/^$/d'
echo ""
