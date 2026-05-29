#!/usr/bin/env bash
set -euo pipefail

log() {
  printf 'agent-scripts auto-pull: %s\n' "$*"
}

if ! command -v git >/dev/null 2>&1; then
  log "skip, git not found"
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  exit 0
fi

cd "$repo_root"

head_ref="$(git symbolic-ref --quiet HEAD 2>/dev/null || true)"
branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [[ -z "$branch" ]]; then
  log "skip, detached HEAD in $repo_root"
  exit 0
fi

upstream="$(git for-each-ref --format='%(upstream:short)' "$head_ref" 2>/dev/null || true)"
if [[ -z "$upstream" || "$upstream" == '@{u}' || "$upstream" == '@{upstream}' ]]; then
  log "skip, $branch has no upstream"
  exit 0
fi

if [[ -n "$(git status --porcelain)" ]]; then
  log "skip, worktree has local changes in $repo_root"
  exit 0
fi

remote="${upstream%%/*}"
remote_ref="${upstream#*/}"

if [[ -z "$remote" || "$remote" == "$upstream" || -z "$remote_ref" ]]; then
  log "skip, could not parse upstream $upstream"
  exit 0
fi

if ! git fetch --quiet "$remote" "$remote_ref"; then
  log "skip, fetch failed for $upstream"
  exit 0
fi

counts="$(git rev-list --left-right --count HEAD..."$upstream" 2>/dev/null || true)"
if [[ -z "$counts" ]]; then
  log "skip, could not compare with $upstream"
  exit 0
fi

ahead="${counts%%[[:space:]]*}"
behind="${counts##*[[:space:]]}"

if [[ "$ahead" != "0" ]]; then
  log "skip, $branch has $ahead local commit(s) not on $upstream"
  exit 0
fi

if [[ "$behind" == "0" ]]; then
  log "up to date: $branch"
  exit 0
fi

if git pull --ff-only --quiet; then
  log "pulled $behind commit(s) into $branch from $upstream"
else
  log "skip, fast-forward pull failed for $branch"
fi
