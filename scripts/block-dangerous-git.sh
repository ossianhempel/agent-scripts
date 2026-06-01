#!/usr/bin/env bash
#
# block-dangerous-git.sh — agent-agnostic guardrail for destructive git commands.
#
# STATUS: stored for reference / future use. NOT wired into any agent.
# Adapted from mattpocock/skills (git-guardrails-claude-code) to work for both
# Claude Code and Codex, and to allow plain `git push` (only history-destroying
# / unrecoverable ops are blocked).
#
# WHAT IT DOES
#   Reads a shell command from CLI args, raw stdin, or an agent's tool-call JSON,
#   matches it against a denylist of irreversible git operations, and exits 2
#   (with an explanation on stderr) if it matches. Exit 0 = allowed.
#
#   Exit 2 is the convention both Claude Code and Codex treat as "block this
#   tool call and surface stderr to the model."
#
# HOW IT READS INPUT (first match wins)
#   1. CLI args:        block-dangerous-git.sh "git push --force"
#   2. stdin as JSON:   tries these paths, in order, joining arrays with spaces:
#                         .tool_input.command   (Claude Code PreToolUse)
#                         .command              (Codex shell tool; string OR array)
#                         .params.command / .parameters.command / .input.command
#                         .arguments.command    (Codex function-call arguments)
#   3. stdin as raw text: the whole stdin is treated as the command.
#   (jq is used if available; without jq it falls back to raw stdin/args.)
#
# WHEN/IF YOU DECIDE TO WIRE IT UP
#   Claude Code  — .claude/settings.json:
#     {
#       "hooks": {
#         "PreToolUse": [{
#           "matcher": "Bash",
#           "hooks": [{ "type": "command",
#             "command": "/abs/path/to/scripts/block-dangerous-git.sh" }]
#         }]
#       }
#     }
#     (Claude pipes the tool-call JSON on stdin; this reads .tool_input.command.)
#
#   Codex — same hook schema as Claude Code (stdin .tool_input.command,
#     exit 2 + stderr to deny). Add to ~/.codex/config.toml (or .codex/config.toml):
#         [[hooks.PreToolUse]]
#         matcher = "^Bash$"
#         [[hooks.PreToolUse.hooks]]
#         type = "command"
#         command = '/abs/path/to/scripts/block-dangerous-git.sh'
#     Codex requires command hooks to be reviewed/trusted before they run.
#     (Codex also accepts a JSON {"permissionDecision":"deny",...} on stdout;
#     this script uses the simpler exit-2 path, which both agents honor.)
#
# NOTE: this is a guardrail against accidents, NOT a security boundary. Substring
#   matching is bypassable (aliases, `git -C`, odd spacing). Don't treat it as one.

set -euo pipefail

# --- config -----------------------------------------------------------------
# Plain `git push` is ALLOWED on purpose (recoverable; part of normal workflow).
# Only unrecoverable / history-rewriting operations are blocked.
DANGEROUS_PATTERNS=(
  'reset[[:space:]]+--hard'                 # git reset --hard  (discards commits + worktree)
  'clean[[:space:]]+-[a-z]*f'               # git clean -f / -fd / -fdx  (deletes untracked files)
  'branch[[:space:]]+-D'                    # git branch -D  (force-delete unmerged branch)
  'checkout[[:space:]]+(--[[:space:]]+)?\.' # git checkout . / checkout -- .  (discards worktree)
  'restore[[:space:]]+(--[a-z]+[[:space:]]+)*\.'  # git restore .  (discards worktree)
  'push.*(--force([^-]|$)|[[:space:]]-f([[:space:]]|$))'  # force push (-f / --force)
  'reflog[[:space:]]+(delete|expire)'       # git reflog delete/expire  (destroys recovery net)
  'update-ref[[:space:]]+-d'                # git update-ref -d  (deletes refs directly)
)
# `--force-with-lease` is the safe variant of force-push and is allowed.
ALLOW_PATTERNS=(
  'force-with-lease'
)
# ---------------------------------------------------------------------------

extract_command() {
  # 1. Prefer CLI args.
  if [ "$#" -gt 0 ]; then
    printf '%s' "$*"
    return 0
  fi

  # 2/3. Read stdin (may be empty if invoked with neither args nor a pipe).
  local input
  input="$(cat 2>/dev/null || true)"
  [ -z "$input" ] && return 0

  # If it looks like JSON and jq is available, try known command paths.
  if command -v jq >/dev/null 2>&1 && printf '%s' "$input" | jq -e . >/dev/null 2>&1; then
    local cmd
    cmd="$(printf '%s' "$input" | jq -r '
      ( [ .tool_input.command,
          .command,
          .params.command,
          .parameters.command,
          .input.command,
          .arguments.command,
          .tool_input.cmd ]
        | map(select(. != null)) | .[0] ) as $c
      | if   ($c | type) == "array"  then ($c | join(" "))
        elif ($c | type) == "string" then $c
        else empty end
    ' 2>/dev/null || true)"
    if [ -n "$cmd" ]; then
      printf '%s' "$cmd"
      return 0
    fi
  fi

  # Fallback: treat the raw stdin as the command string.
  printf '%s' "$input"
}

COMMAND="$(extract_command "$@")"

# Nothing to check — allow.
[ -z "$COMMAND" ] && exit 0

# Only inspect git invocations.
if ! printf '%s' "$COMMAND" | grep -qE '(^|[^[:alnum:]_-])git([[:space:]]|$)'; then
  exit 0
fi

# Explicit allows take precedence (e.g. --force-with-lease).
for ok in "${ALLOW_PATTERNS[@]}"; do
  if printf '%s' "$COMMAND" | grep -qE "$ok"; then
    exit 0
  fi
done

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if printf '%s' "$COMMAND" | grep -qE "git[[:space:]].*$pattern|$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous git pattern '$pattern'." >&2
    echo "This operation is irreversible and has been blocked by block-dangerous-git.sh." >&2
    exit 2
  fi
done

exit 0
