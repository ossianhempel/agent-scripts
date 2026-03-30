# Global Agent Instructions

Ossian owns this. Work style: telegraph; noun-phrases ok; min tokens.

## Agent Protocol

- Workspace: ~/Developer or ~/repos. Missing ossianhempel repo: clone https://github.com/ossianhempel/<repo>.git. (it can differ between Developer or repos depending on machine)
- Inline comments: explain *why*, not *what*. Give context for decisions, trade-offs, and non-obvious behavior. Don't delete existing comments.
- Files: repo or ~/Developer/agent-scripts or ~/repos/agent-scripts.
- PRs: use gh pr view/diff (no URLs).
- "Make a note" or "remember something" => edit AGENTS.md (shortcut; not a blocker). Ignore CLAUDE.md.
- I'm a single developer — no team to coordinate with.
- Guardrails: use `trash` for deletes; never `rm`.
- Need upstream file: stage in /tmp/, then cherry-pick; never overwrite tracked.
- Keep files <~500 LOC; split/refactor as needed.
- Theme tokens live in constants/Theme.ts (or Theme.swift); use them for colors, fonts, spacing, radii, shadows. No hardcoded styles in components.
- Avoid polyfills unless explicitly required by the target environment.
- Commits: Conventional Commits (feat|fix|refactor|build|ci|chore|docs|style|perf|test).
- Prefer end-to-end verify; if blocked, say what's missing.
- New deps: quick health check (recent releases/commits, adoption).
- Don't use `any` in TypeScript.
- Bug fixes (non-trivial): reproduce in a failing test first, then fix, then verify the test passes. Not required for trivial/UI bugs.

### React-Specific

- Don't reach for `useEffect` by default; many things can be handled in render or via keys.
  - Before adding an effect: "Is this about synchronizing with something external?"
  - Shared logic → event handlers, not effects.
  - Effects that fetch/subscribe: manage cleanup and race conditions.
  - Use key or controlled remounting to reset state.
  - Abstract complex effect logic into custom hooks.

## Important Locations
- Personal Website repo: ~/Developer/ossianhempel_com
- Obsidian vault: /Users/ossianhempel/ossians-second-brain-sync

## Docs
- Start: run docs list (docs:list script, or bin/docs-list here if present; ignore if not installed); open docs before coding.
- Keep notes short; update docs when behavior/API changes.
- Add read_when hints on cross-cutting docs.

## Build/Test
- Before handoff: run full gate (lint/typecheck/tests/docs).
- CI red: gh run list/view, rerun, fix, push, repeat til green.
- Release: read docs/RELEASING.md (or find best checklist if missing).

## Git
- Safe by default: git status/diff/log. Push only when user asks.
- `git checkout` ok for PR review / explicit request.
- Branch changes require user consent.
- Destructive ops forbidden unless explicit (`reset --hard`, `clean`, `restore`, `rm`, …).
- Don't delete/rename unexpected stuff; stop + ask.
- No repo-wide S/R scripts; keep edits small/reviewable.
- Avoid manual git stash; if Git auto-stashes during pull/rebase, that's fine (hint, not hard guardrail).
- If user types a command ("pull and push"), that's consent for that command.
- No amend unless asked.
- Big review: `git --no-pager diff --color=never`.
- Multi-agent: check `git` status/diff before edits; ship small commits.

## Critical Thinking
- Conflicts: call out; pick safer path.
- Unrecognized changes: assume other agent; keep going; focus your changes. If it causes issues, stop + ask user.

## Tools

See `tools.md` for full CLI tool reference (oracle, gh, gog, committer, trash, docs-list, browser-tools, things, obsidian).

### Clawdbot
- Don't edit/touch source code; keep it vanilla for upstream updates.
- Personal AI assistant on Mac Mini.
- Set up with `clawdbot onboard`, configure with `clawdbot configure`.
- Update: `scripts/update-clawdbot.sh`.

## Design Guidelines

<frontend_aesthetics> Avoid generic "AI slop" UI. Be opinionated + distinctive.

Do:
- Typography: pick a distinctive font for consumer/marketing sites.
- Theme: commit to a palette; use CSS vars; bold accents > timid gradients.
- Use CSS animations/effects instead of custom hooks whenever suitable.
- Motion: 1–2 high-impact moments (staggered reveal beats random micro-anim).
- Background: add depth (gradients/patterns), not flat default.
Avoid: purple-on-white clichés, generic component grids, predictable layouts. </frontend_aesthetics>
