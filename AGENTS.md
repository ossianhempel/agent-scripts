# Global Agent Instructions

Ossian owns this. Work style: telegraph; noun-phrases ok; min tokens.
Default web stack: TanStack Start, PGlite/SQLite → PG when needed, single-container fullstack, deploy to Coolify. Avoid Next.js (Vercel lock-in).

- Final replies: plain English, concise, no unnecessary jargon or implementation trivia.
- Before handoff: define done, verify with the narrowest meaningful check, fix and re-test if it fails.
- For visual work: inspect the real UI when possible. For scripts: run representative input.
- If blocked, say exactly what is missing and what was already tried.

## Agent Protocol

- Workspace: ~/Developer or ~/repos. Missing ossianhempel repo: clone https://github.com/ossianhempel/<repo>.git. (it can differ between Developer or repos depending on machine)
- Inline comments: explain *why*, not *what*. Give context for decisions, trade-offs, and non-obvious behavior. Don't delete existing comments.
- Files: repo or ~/Developer/agent-scripts or ~/repos/agent-scripts.
- PRs: use gh pr view/diff (no URLs).
- "Make a note" or "remember something" => edit AGENTS.md (shortcut; not a blocker). Ignore CLAUDE.md.
- I'm a single developer — no team to coordinate with.
- Confidentiality: never expose, quote, infer, or publish non-public project, user, customer, credential, URL, dataset, infra, or org details unless explicitly approved.
- Guardrails: use `trash` for deletes; never `rm`.
- Need upstream file: stage in /tmp/, then cherry-pick; never overwrite tracked.
- Keep files <~500 LOC; split/refactor as needed.
- Use existing theme/design tokens; don't hardcode styles when a token exists.
- Avoid polyfills unless explicitly required by the target environment.
- Use the repo package manager/runtime; no swaps without approval.
- Commits: Conventional Commits (feat|fix|refactor|build|ci|chore|docs|style|perf|test).
- Prefer end-to-end verify; if blocked, say what's missing.
- New deps: quick health check (recent releases/commits, adoption).
- Avoid `any` in TypeScript; justify it when unavoidable.
- Bug fixes (non-trivial): reproduce in a failing test first, then fix, then verify the test passes. Not required for trivial/UI bugs.
- Skills: short generic descriptions, quote `description`, YAML-parse frontmatter after SKILL.md edits.

## Important Locations
- Personal Website repo: ~/Developer/ossianhempel_com
- Obsidian vault: /Users/ossianhempel/ossians-second-brain-sync
- Claude app scheduled tasks (local routines): prompts in `~/.claude/scheduled-tasks/<name>/SKILL.md`; cron registry in `~/Library/Application Support/Claude/claude-code-sessions/<account>/<session>/scheduled-tasks.json` (cron in local time). Separate from remote routines (claude.ai/code/routines, managed via `/schedule`).
- Codex scheduled jobs: no local storage — cloud-side only, managed in the Codex app UI

## Notes Lookup
- If I say "check my notes", "read what I've written about this", "research this in my notes", or similar, search the Obsidian vault first. Use web search or other sources second unless I explicitly ask for them.

## Docs
- Start: run docs list (docs:list script, or bin/docs-list here if present; ignore if not installed); open docs before coding.
- Repos with docs should vendor `scripts/docs-list.ts` and expose `docs:list` in `package.json` when they have Node scripts, so repo-local docs discovery works without reaching back into `agent-scripts`.
- Keep notes short; update docs when behavior/API changes.
- Add read_when hints on cross-cutting docs.

### Knowledge objects (when a repo uses them)
- `docs/brainstorms/` — requirements docs shaping the WHAT (the `brainstorm` skill). The upstream a plan traces to.
- `docs/plans/` — implementation plans (the `plan` skill: `YYYY-MM-DD-NNN-<type>-<slug>-plan.md`). Check for a current plan before starting multi-step work.
- `docs/solutions/` — solved-problem & learning writeups (the `compound` skill). **Search here before debugging** — surface prior fixes via the learnings-researcher rather than re-discovering them.
- `CONCEPTS.md` — domain glossary (multi-context via `CONCEPTS-MAP.md`). Use its exact terms; don't coin synonyms.
- After finishing non-trivial work, `compound` to capture the learning, fence off recurrence, and refresh stale docs.

## Build/Test
- Before handoff: run the narrowest meaningful verification. Run full gate (lint/typecheck/tests/docs) before commits/PRs or broad changes.
- CI red: gh run list/view, rerun, fix, push, repeat til green.
- Release: read docs/RELEASING.md (or find best checklist if missing).

## Runtime Safety
- Secrets: never run `env`, `set`, `export -p`, or broad secret searches. Query exact names only; redact values.
- Public GitHub bodies: use temp files plus `--body-file`; avoid inline shell strings with backticks, `$`, env names, or user text.
- PR/issue body edits: fetch with REST + `jq -r`, inspect locally, then write with `--body-file`.
- zsh: don't use `status` as a variable; use arrays for multi-item loops.

## Git
- If cwd is in a git repo, work there. Don't jump to sibling checkouts unless asked.
- Safe by default: git status/diff/log. Push only when user asks.
- `git checkout` ok for PR review / explicit request.
- Branch changes require user consent.
- Destructive ops forbidden unless explicit (`reset --hard`, `clean`, `restore`, `rm`, …).
- Unexpected changes: assume user/agent work; don't revert. If they block the task, stop + ask.
- No repo-wide S/R scripts; keep edits small/reviewable.
- Avoid manual git stash; if Git auto-stashes during pull/rebase, that's fine (hint, not hard guardrail).
- If user types a command ("pull and push"), that's consent for that command.
- No amend unless asked.
- Auth fail (gh/git/ssh)? Likely on work account — try `gh auth switch` (to ossianhempel) before debugging further.
- Big review: `git --no-pager diff --color=never`.
- Multi-agent: check `git` status/diff before edits; ship small commits.

## Critical Thinking
- Conflicts: call out; pick safer path.
- Unrecognized changes: assume other agent; keep going; focus your changes. If it causes issues, stop + ask user.

## Tools

See `tools.md` for full CLI tool reference (oracle, summarize, peekaboo, gh, gog, committer, trash, docs-list, browser-tools, things, obsidian).

### Peekaboo — macOS screen capture and UI automation: annotated screenshots, click/type/scroll/menu control, and visual verification of native apps outside the browser.

### OpenClaw
- Don't edit/touch OpenClaw source; keep it vanilla for upstream updates.
- If Telegram/OpenClaw stops responding, read `docs/openclaw-operations.md` before guessing.

### Docs Discovery
At session start in this repo, run `bin/docs-list` (or `tsx scripts/docs-list.ts`). New docs MUST carry `summary:` + `read_when:` frontmatter to show up.

### Browser Control
For lightweight browser control (navigation, JS evaluation, screenshots, element picking, process inspection, or console tailing), run `bin/browser-tools`.

### Changelog
`CHANGELOG.md` at the repo root logs meaningful changes (skills added/removed/renamed, sync/audit behavior, AGENTS guidance). When you ship something another agent or future-you needs to know about, add a date-stamped section. See `docs/update-changelog.md` (surfaced by `bin/docs-list`) for the curation checklist when the file falls behind several commits.

### Skill Sync & Audit
- Source of truth: add/edit skills in `skills/` or `profiles/<profile>/skills/`, never directly in runtime caches or project-local generated copies.
- Read `docs/syncing.md` before changing sync/profile/plugin behavior; read `docs/supported-agents.md` before making tooling work across runtimes.
- Subagents live in `subagents/`; read `docs/subagents.md` before adding or editing them.
- Small CLI tools should usually have a companion skill plus a short `tools.md` entry.
- Use `scripts/sync-agent-scripts.sh` and `scripts/skills-audit.py`; never hand-delete managed skill installs.

## Design Guidelines

<frontend_aesthetics> Avoid generic "AI slop" UI. Be opinionated + distinctive.

Do:
- Typography: pick a distinctive font for consumer/marketing sites.
- Theme: commit to a palette; use CSS vars; bold accents > timid gradients.
- Use CSS animations/effects instead of custom hooks whenever suitable.
- Motion: 1–2 high-impact moments (staggered reveal beats random micro-anim).
- Background: add depth (gradients/patterns), not flat default.
Avoid: purple-on-white clichés, generic component grids, predictable layouts. </frontend_aesthetics>
