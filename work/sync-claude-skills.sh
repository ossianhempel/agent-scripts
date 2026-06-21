#!/usr/bin/env bash
# Install work/<employer>/skills/* into ~/.claude/skills ONLY (Claude Code).
#
# These are employer/work skills (Rebtech, later H&M) that must load in Claude
# Code but NOT in Codex. The main agent-scripts sync populates ~/.agents/skills
# (read by Codex, Gemini, Cursor, Copilot, Windsurf) plus ~/.claude/skills; this
# helper deliberately touches ONLY ~/.claude/skills, so Codex never sees them.
#
# Idempotent. Re-run after adding a new employer dir (e.g. work/hm/skills/*).
#   ./work/sync-claude-skills.sh            install/update
#   ./work/sync-claude-skills.sh --dry-run  show what would change
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"          # .../agent-scripts/work
CLAUDE_SKILLS="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

mkdir -p "$CLAUDE_SKILLS"
shopt -s nullglob
found=0
for skill in "$ROOT"/*/skills/*/; do
  [[ -f "${skill}SKILL.md" ]] || continue
  found=1
  name="$(basename "$skill")"
  link="$CLAUDE_SKILLS/$name"
  rel="$(python3 -c 'import os,sys;print(os.path.relpath(sys.argv[1],sys.argv[2]))' "${skill%/}" "$CLAUDE_SKILLS")"
  if [[ -L "$link" && "$(readlink "$link")" == "$rel" ]]; then
    echo "ok    $name"
    continue
  fi
  if [[ -e "$link" && ! -L "$link" ]]; then
    echo "skip  $name (real dir/file at $link -- refusing to clobber)" >&2
    continue
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "would link  $name -> $rel"
  else
    ln -sfn "$rel" "$link"
    echo "link  $name -> $rel"
  fi
done
[[ "$found" -eq 1 ]] || { echo "no work skills found under $ROOT/*/skills/" >&2; exit 1; }
echo "done (Claude Code only; Codex untouched)"
