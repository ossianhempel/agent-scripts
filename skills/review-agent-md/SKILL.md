---
name: review-agent-md
description: Review and improve an agent's instruction file (CLAUDE.md or AGENTS.md) by mining recent conversation history for rule violations, missing patterns, and stale guidance. Takes a `claude` or `codex` argument to choose which agent's history and instruction file to analyze. Use when the user wants to review/improve CLAUDE.md or AGENTS.md, audit their agent instructions, or learn from past sessions.
---

# Review Agent Instruction File (CLAUDE.md / AGENTS.md)

Mine recent conversation history to improve the instruction file the agent reads.
Works for **both Claude Code and Codex** — the `$ARGUMENTS` value selects which.

Adapted from ykdojo's `review-claudemd`, generalized to be agent-agnostic.

## Step 0 — Resolve the target agent

Read the argument (`claude` or `codex`). If none was given, ask which one — do not
guess. The choice fixes two things:

| Agent    | History store                                  | Project instruction file                 | Global instruction file        |
|----------|------------------------------------------------|------------------------------------------|--------------------------------|
| `claude` | `~/.claude/projects/<dashed-cwd>/*.jsonl`      | `./CLAUDE.md` (may symlink to AGENTS.md) | `~/.claude/CLAUDE.md`          |
| `codex`  | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` | `./AGENTS.md`                            | `~/.codex/AGENTS.md`           |

Notes for this workspace:
- `CLAUDE.md` is frequently a **symlink to `AGENTS.md`** (e.g. `~/Developer/CLAUDE.md`).
  When suggesting edits, resolve the symlink and edit the real file.
- The repo-level guardrails live in `~/Developer/agent-scripts/AGENTS.md`. Treat that
  as the "global" file for project work in this workspace if the local one defers to it.

## Step 1 — Read the current instruction file(s)

Read the project instruction file and the global one for the chosen agent (skip any
that don't exist). These are the rubric you'll judge history against. If neither
exists, tell the user and offer to bootstrap one instead.

## Step 2 — Gather recent conversation history

Run the bundled gatherer. It handles the per-agent store layout and JSON shape
(including Codex's old flat and 2026 `response_item` schemas), writes one plain-text
transcript per session, and prints the temp dir on its last line.

The script lives next to this SKILL.md. Resolve its absolute path first (runtime cwd
is the project, not the skill dir):

```bash
# Primary location in this workspace; fall back to a search if the skill was synced elsewhere.
GATHER=~/Developer/agent-scripts/skills/review-agent-md/scripts/gather-history.sh
[ -x "$GATHER" ] || GATHER=$(find ~ -path '*review-agent-md/scripts/gather-history.sh' 2>/dev/null | head -1)

DIR=$("$GATHER" <claude|codex> "$PWD" 8 | tail -1)
ls -la "$DIR"
```

- Arg 2 is the project cwd (defaults to `$PWD`); arg 3 is how many recent sessions.
- For `claude`, the current live session (newest file) is automatically skipped.
- If `$DIR` is empty, there's no history for this project/agent — say so and stop.

Each transcript is `NN-<sessionid>.txt`, newest first, with `[user]`/`[assistant]`
turns. Tool-result noise and instruction-injection preambles are already stripped.

## Step 3 — Analyze in parallel with subagents

Spawn `Explore` (or general) subagents — one per batch of transcripts — so analysis
runs concurrently. Batch by file size: large (>100KB) 1–2 per agent, medium
(10–100KB) 3–5, small (<10KB) 5–10.

Give each subagent: the current instruction file(s) from Step 1 and its batch of
transcript paths. Ask it to return findings in these four buckets:

1. **Violated instructions** — places where the agent broke an existing rule. Quote
   the rule and the moment it was violated. These signal weak/ambiguous wording.
2. **Project-local suggestions** — recurring project-specific patterns, corrections,
   or preferences worth codifying in the *project* file.
3. **Global suggestions** — universal patterns worth promoting to the *global* file.
4. **Outdated content** — existing guidance contradicted by how work actually went,
   or referencing files/flags/commands that no longer exist.

Tell subagents their final message IS the structured result (raw findings, no
preamble), so you can aggregate cleanly.

## Step 4 — Aggregate and present

Merge all subagent findings, de-duplicate, and present as four sections (or a table)
for the user to review. For each suggestion include: the proposed wording, which file
it belongs in, and the evidence (which session it came from). Rank by how often the
pattern recurred.

**Do not edit any instruction file yet.** Let the user pick what to apply. Once they
choose, make the edits (resolving symlinks to the real file) and show a diff.

## Notes

- The gatherer is read-only over history; it only writes transcripts to a temp dir.
- Codex history isn't organized by project on disk — the gatherer greps the whole
  sessions tree for the cwd marker (fast, fixed-string), so the first run on a large
  history takes ~1s.
- Reviewing the *other* agent's file is fine: run from inside Claude Code with the
  `codex` argument to audit `AGENTS.md` from Codex history, or vice versa.
