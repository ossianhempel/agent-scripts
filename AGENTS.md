# Global Agent Instructions

Ossian owns this. Start: say hi + 1 motivating line. Work style: telegraph; noun-phrases ok; drop grammar; min tokens.

## Agent Protocol

- Workspace: ~/Developer or ~/repos. Missing ossianhempel repo: clone https://github.com/ossianhempel/<repo>.git. (it can differ between Developer or repos depending on machine)
- Files: repo or ~/Developer/agent-scripts or ~/repos/agent-scripts.
- PRs: use gh pr view/diff (no URLs).
- "Make a note" => edit AGENTS.md (shortcut; not a blocker). Ignore CLAUDE.md.
- No ./runner. Guardrails: use trash for deletes.
- Need upstream file: stage in /tmp/, then cherry-pick; never overwrite tracked.
- Bugs: add regression test when it fits.
- Keep files <~500 LOC; split/refactor as needed.
- Avoid polyfills unless explicitly required by the target environment.
- Commits: Conventional Commits (feat|fix|refactor|build|ci|chore|docs|style|perf|test).
- CI: gh run list/view (rerun/fix til green).
- Prefer end-to-end verify; if blocked, say what’s missing.
- New deps: quick health check (recent releases/commits, adoption).
- Slash cmds: ~/.codex/prompts/.
- Web: search early; quote exact errors; prefer 2024–2025 sources.
- Oracle: run npx -y @steipete/oracle --help once/session before first use.
- Style: telegraph. Drop filler/grammar. Min tokens (global AGENTS + replies).
- Don't reach for `useEffect` by default; many things you think require an effect
  can be handled in render or via keys.
  - Before adding an effect, ask: "Is this really about synchronizing with something external?"
  - Move shared logic to event handlers, not effects.
  - Be careful with effects that fetch / subscribe; manage cleanup and race conditions.
  - Use key or controlled remounting to reset state.
  - Abstract complex effect logic into custom hooks.
  - Don't use `any` in TypeScript.

## Screenshots ("use a screenshot")
- Pick newest PNG in ~/Desktop or ~/Downloads.
- Verify it’s the right UI (ignore filename).
- Size: `sips -g pixelWidth -g pixelHeight <file> (prefer 2×).
- Optimize: `imageoptim <file> (install: brew install imageoptim-cli).
- Replace asset; keep dimensions; commit; run gate; verify CI.

## Important Locations
- Personal Website repo: ~/Developer/ossianhempel_com
- Obsidian vault: /Users/ossianhempel/ossians-second-brain-sync

## Docs
- Start: run docs list (docs:list script, or bin/docs-list here if present; ignore if not installed); open docs before coding.
- Follow links until domain makes sense; honor Read when hints.
- Keep notes short; update docs when behavior/API changes (no ship w/o docs).
- Add read_when hints on cross-cutting docs.

## Build/Test
- Before handoff: run full gate (lint/typecheck/tests/docs).
- CI red: gh run list/view, rerun, fix, push, repeat til green.
- Keep it observable (logs, panes, tails, MCP/browser tools).
- Release: read docs/RELEASING.md (or find best checklist if missing).

## Git
- Safe by default: git status/diff/log. Push only when user asks.
- `git checkout` ok for PR review / explicit request.
- Branch changes require user consent.
- Destructive ops forbidden unless explicit (`reset --hard`, `clean`, `restore`, `rm`, …).
- Don’t delete/rename unexpected stuff; stop + ask.
- No repo-wide S/R scripts; keep edits small/reviewable.
- Avoid manual git stash; if Git auto-stashes during pull/rebase, that’s fine (hint, not hard guardrail).
- If user types a command (“pull and push”), that’s consent for that command.
- No amend unless asked.
- Big review: `git --no-pager diff --color=never`.
- Multi-agent: check `git` status/diff before edits; ship small commits.

## Critical Thinking
- Fix root cause (not band-aid).
- Unsure: read more code; if still stuck, ask w/ short options.
- Conflicts: call out; pick safer path.
- Unrecognized changes: assume other agent; keep going; focus your changes. If it causes issues, stop + ask user.
- Leave breadcrumb notes in thread.

## Tools

### Oracle
- Bundle prompt+files for 2nd model. Use when stuck/buggy/review.
- Run `npx -y @steipete/oracle --help` once/session (before first use).

### gh
- GitHub CLI for PRs/CI/releases. Given issue/PR URL (or /pull/5): use gh, not web search.
- Examples: `gh issue view <url> --comments -R owner/repo`, `gh pr view <url> --comments --files -R owner/repo`.

### committer
- Commit helper (PATH). Stages only listed paths; required here. Repo may also ship ./scripts/committer.

### trash
- Move files to Trash: trash … (system command).

### docs-list
- Lists docs/ + enforces front-matter. Ignore if bin/docs-list not installed. Rebuild: bun build scripts/docs-list.ts --compile --outfile bin/docs-list.

### browser-tools
- Chrome DevTools helper. Cmds: start, nav, eval, screenshot, pick, cookies, inspect, kill.
- Rebuild: bun build scripts/browser-tools.ts --compile --target bun --outfile bin/browser-tools.

## Design Guidelines

<frontend_aesthetics> Avoid “AI slop” UI. Be opinionated + distinctive.

Do:
- Typography: pick a real font; avoid Inter/Roboto/Arial/system defaults.
- Theme: commit to a palette; use CSS vars; bold accents > timid gradients.
- Use CSS animations/effects instead of custom hooks whenever suitable.
- Motion: 1–2 high-impact moments (staggered reveal beats random micro-anim).
- Background: add depth (gradients/patterns), not flat default.
Avoid: purple-on-white clichés, generic component grids, predictable layouts. </frontend_aesthetics>
