#!/usr/bin/env bash
# gather-history.sh — extract recent conversation transcripts for an agent + project.
#
# Usage:
#   gather-history.sh <claude|codex> [project-cwd] [limit]
#
# Defaults: project-cwd = $PWD, limit = 8 (most recent sessions for this project).
#
# Behaviour:
#   - Finds the sessions that belong to <project-cwd> for the chosen agent.
#   - Writes each as a plain-text transcript ([user]/[assistant] turns) into a
#     fresh temp dir, newest-first, named NN-<sessionid>.txt.
#   - Prints the temp dir path on the LAST line (everything before it is progress
#     on stderr). Consumers read $(tail -1) to get the dir.
#
# Claude store:  ~/.claude/projects/<dashed-cwd>/<sessionId>.jsonl
# Codex store:   ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl  (cwd is inside the file)
set -euo pipefail

AGENT="${1:-}"
PROJECT="${2:-$PWD}"
LIMIT="${3:-8}"

if [[ "$AGENT" != "claude" && "$AGENT" != "codex" ]]; then
  echo "usage: gather-history.sh <claude|codex> [project-cwd] [limit]" >&2
  exit 2
fi

# Normalise project path (strip trailing slash).
PROJECT="${PROJECT%/}"

OUTDIR="$(mktemp -d "${TMPDIR:-/tmp}/review-agent-md.XXXXXX")"
n=0

emit() { # role-tagged transcript -> file; skip if empty
  local src="$1" dst="$2" jq_prog="$3"
  jq -r "$jq_prog" "$src" 2>/dev/null > "$dst" || true
  if [[ ! -s "$dst" ]]; then rm -f "$dst"; fi
}

if [[ "$AGENT" == "claude" ]]; then
  DASHED="${PROJECT//\//-}"
  CDIR="$HOME/.claude/projects/$DASHED"
  if [[ ! -d "$CDIR" ]]; then
    echo "no claude history for $PROJECT (looked in $CDIR)" >&2
    echo "$OUTDIR"; exit 0
  fi
  # Newest first. The single most-recent file is the *current* live session — skip it.
  mapfile -t FILES < <(ls -t "$CDIR"/*.jsonl 2>/dev/null)
  CLAUDE_JQ='
    select(.type=="user" or .type=="assistant")
    | ((.message.content) // .content) as $c
    | (.message.role // .role // .type) as $role
    | (
        if ($c|type)=="string" then $c
        elif ($c|type)=="array" then
          ([$c[] | (.text // .content // empty) | select(type=="string")] | join("\n"))
        else "" end
      ) as $t
    | select(($t|length) > 0)
    | select(($t|startswith("[\"tool_result\"]"))|not)
    | "[\($role)] " + $t'
  first=1
  for f in "${FILES[@]}"; do
    if [[ $first -eq 1 && "$PROJECT" == "$PWD" ]]; then first=0; continue; fi
    first=0
    [[ $n -ge $LIMIT ]] && break
    sid="$(basename "$f" .jsonl)"
    emit "$f" "$OUTDIR/$(printf '%02d' "$n")-$sid.txt" "$CLAUDE_JQ"
    [[ -f "$OUTDIR/$(printf '%02d' "$n")-$sid.txt" ]] && n=$((n+1))
  done

else # codex
  SROOT="$HOME/.codex/sessions"
  if [[ ! -d "$SROOT" ]]; then
    echo "no codex sessions dir at $SROOT" >&2
    echo "$OUTDIR"; exit 0
  fi
  # Newest rollout files first; grep for this project's cwd marker. Bound the scan
  # to the most recent 400 files so a huge history doesn't make this crawl.
  # Handle both layouts: old flat {type:message,...} and 2026 {type:response_item,payload:{...}}.
  CODEX_JQ='
    (.payload // .) as $m
    | select(($m.type=="message") and ($m.role=="user" or $m.role=="assistant"))
    | $m.role as $role
    | ([$m.content[]? | (.text // empty) | select(type=="string")] | join("\n")) as $t
    | select(($t|length) > 0)
    | select(($t|startswith("<environment_context>"))|not)
    | select(($t|startswith("<user_instructions>"))|not)
    | select(($t|startswith("# AGENTS.md instructions"))|not)
    | "[\($role)] " + $t'
  marker="<cwd>$PROJECT</cwd>"
  # grep -rlF over the whole tree is fast (fixed string). Sort the *matches* by
  # mtime so we transcribe newest-first, then take LIMIT of them.
  while IFS= read -r f; do
    [[ $n -ge $LIMIT ]] && break
    [[ -z "$f" ]] && continue
    sid="$(basename "$f" .jsonl)"
    emit "$f" "$OUTDIR/$(printf '%02d' "$n")-$sid.txt" "$CODEX_JQ"
    [[ -f "$OUTDIR/$(printf '%02d' "$n")-$sid.txt" ]] && n=$((n+1))
  done < <(grep -rlF "$marker" "$SROOT" 2>/dev/null | xargs ls -t 2>/dev/null)
fi

echo "gathered $n session(s) into $OUTDIR" >&2
echo "$OUTDIR"
