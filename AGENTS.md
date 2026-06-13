# Global Agent Instructions

Ossian owns this. Work style: telegraph; noun-phrases ok; min tokens.
Default web stack: TanStack Start, PGlite/SQLite → PG when needed, single-container fullstack, deploy to Coolify. Avoid Next.js (Vercel lock-in).

When communicating your results back to me, explain what you did and what happened in plain, clear English. Avoid jargon, technical implementation details, and code-speak in your final responses. Write as if you're explaining to a smart person who isn't looking at the code. Your actual work (how you think, plan, write code, debug, and solve problems) should stay fully technical and rigorous. This only applies to how you talk to me about it.

Before reporting back to me, if at all possible, verify your own work. Don't just write code and assume it's done. Actually test it using the tools available to you. If possible, run it, check the output, and confirm it does what was asked. If you're building something visual like a web app, view the pages, click through the flows, and check that things render and behave correctly. If you're writing a script, run it against real or representative input and inspect the results. If there are edge cases you can simulate, try them.

Define finishing criteria for yourself before you start: what does "done" look like for this task? Use that as your checklist before you come back to me. If something fails or looks off, fix it and re-test. Don't just flag it and hand it back. The goal is to keep me out of the loop on iteration. I want to receive finished, working results, not a first draft that needs me to spot-check it. Only come back to me when you've confirmed things work, or when you've genuinely hit a wall that requires my input.

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

## Important Locations
- Personal Website repo: ~/Developer/ossianhempel_com
- Obsidian vault: /Users/ossianhempel/ossians-second-brain-sync
- Claude app scheduled tasks (local routines): prompts in `~/.claude/scheduled-tasks/<name>/SKILL.md`; cron registry in `~/Library/Application Support/Claude/claude-code-sessions/<account>/<session>/scheduled-tasks.json` (cron in local time). Separate from remote routines (claude.ai/code/routines, managed via `/schedule`).
- Codex scheduled jobs: no local storage — cloud-side only, managed in the Codex app UI

## Notes Lookup
- If I say "check my notes", "read what I've written about this", "research this in my notes", or similar, search the Obsidian vault first. Use web search or other sources second unless I explicitly ask for them.

## Docs
- Start: run docs list (docs:list script, or bin/docs-list here if present; ignore if not installed); open docs before coding.
- Keep notes short; update docs when behavior/API changes.
- Add read_when hints on cross-cutting docs.

### Knowledge objects (when a repo uses them)
- `docs/brainstorms/` — requirements docs shaping the WHAT (the `brainstorm` skill). The upstream a plan traces to.
- `docs/plans/` — implementation plans (the `plan` skill: `YYYY-MM-DD-NNN-<type>-<slug>-plan.md`). Check for a current plan before starting multi-step work.
- `docs/solutions/` — solved-problem & learning writeups (the `compound` skill). **Search here before debugging** — surface prior fixes via the learnings-researcher rather than re-discovering them.
- `CONCEPTS.md` — domain glossary (the `grill-with-docs` skill; multi-context via `CONCEPTS-MAP.md`). Use its exact terms; don't coin synonyms.
- After finishing non-trivial work, `compound` to capture the learning, fence off recurrence, and refresh stale docs.

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
- Don't edit/touch source code; keep it vanilla for upstream updates.
- Personal AI assistant on Mac Mini.
- Current service is the OpenClaw launch agent `ai.openclaw.gateway`; runtime
  state lives in `~/.openclaw` (`~/.clawdbot` is a symlink on this Mac).
- If Telegram stops responding, read `docs/openclaw-operations.md` before
  guessing. Check the launch agent, `~/Library/Logs/openclaw/gateway.log`, and
  `~/.openclaw/telegram/ingress-spool-default/` first.
- Set up/configure with `openclaw` commands unless an older install explicitly
  only has `clawdbot`.

### Docs Discovery
At session start in this repo, run `bin/docs-list` (or `tsx scripts/docs-list.ts`). It prints every `docs/*.md` with its `summary:` and `read_when:` hints so you know which playbook to open before coding — that's the discovery mechanism for repo-local docs (changelog curation, supported agents, release flow, etc.). New docs MUST carry `summary:` + `read_when:` frontmatter to show up.

### Changelog
`CHANGELOG.md` at the repo root logs meaningful changes (skills added/removed/renamed, sync/audit behavior, AGENTS guidance). When you ship something another agent or future-you needs to know about, add a date-stamped section. See `docs/update-changelog.md` (surfaced by `bin/docs-list`) for the curation checklist when the file falls behind several commits.

### Skill Sync & Audit
Skills live in `agent-scripts/skills/` and are mirrored into `~/.agents/skills/` (cross-tool), `~/.claude/skills/` (Claude Code), and `~/.gemini/antigravity-cli/skills/` (Antigravity CLI).

Small CLI tools that need a "when to use this" trigger should usually have a companion skill in `skills/<tool-name>/` plus a short entry in `tools.md`. The binary gives agents capability; the skill description gives agents the trigger surface.

**Subagents** (named cross-tool agents a harness delegates to) live in `subagents/<name>.md` — one canonical Claude-flavoured definition that `scripts/gen-subagents.py` transforms into each harness's native format (Claude `.md`, Codex `.toml`; more planned). Unlike skills, they can't be plain-copied — formats differ. Add or edit a subagent there, never in `~/.claude/agents/` directly; the `subagents` sync provider regenerates and self-prunes (manifest-based). See `docs/subagents.md`.

**Supported agents** (the runtimes sync/prune target, their skill roots, and which keep usable session transcripts) are documented in `docs/supported-agents.md`. Read it before making any skill or script "work across all the agents we support" — e.g. session-log discovery (`agent-transcript`, `session-viewer`) or skill-root scanning (`skill-cleaner`). Only Claude Code and Codex keep full-turn JSONL transcripts; the rest log user prompts only or use binary/SQLite.

**Where to add a new skill — read this carefully:** When working in this repo (`agent-scripts/`) and the user asks to add, install, or vendor a new skill, the skill MUST be created inside `agent-scripts/skills/<name>/` (global) or `agent-scripts/profiles/<profile>/skills/<name>/` (project-scoped — see Profiles below). Never drop it directly into `~/.claude/skills/`, `~/.agents/skills/`, `~/.codex/skills/`, or any repo-local `.claude/skills` / `.agents/skills` / `.codex/skills` folder. The repo is the single source of truth; the sync script fans it out everywhere else. Putting it in a global or project-local cache instead breaks that sync and the skill will get pruned or shadowed. If in doubt, ask — but the default is always `agent-scripts/skills/`.

Two scripts manage sync:
- `scripts/sync-agent-scripts.sh` — propagates repo skills (as relative symlinks back into this repo — one source of truth, no re-sync needed after *editing* a skill) + slash-commands (copied) to all agent runtimes. Run after creating, moving, or deleting a skill. Does NOT prune skills. Does NOT sync profiles or plugins unless you pass `--provider profiles` / `--provider plugins`. For plugins, `--prune` additionally disables managed plugins removed from the manifest (see Plugins below).
- `scripts/skills-audit.py scan` — reports orphans (global links/dirs missing from repo), drift (structurally impossible now that global skills are symlinks — the section stays for back-compat and is normally empty), local shadows, and the profile sections (assignments, profile drift, profile orphans, project-native skills, name collisions). Run when in doubt about what's installed.
- `scripts/skills-audit.py prune --execute` — deletes global skills that no longer exist in the repo. Default is dry-run; pass `--execute` to actually remove. Never touches project-local `.claude/skills` or `.agents/skills` inside repos. Add `--profiles` to also prune profile orphans from assigned project scopes — but **only** skills the profile system manages elsewhere (installed by a different profile); skills authored inside a project that the repo has never seen are reported under "Project-local skills not in any repo profile" and are never pruned.
Use these instead of `rm -rf` on cached skill directories.

#### Profiles (project-scoped skill packages)
The skills in `skills/` are **global** — synced to every runtime everywhere. To keep that set small, focused skills live in **profiles** and install only into the projects that need them.

Keep platform profiles lean — only core platform skills. Optional services (Clerk, Convex, RevenueCat, Stripe) live in their own profiles; projects opt in individually via `profile-assignments.json`.

- **Layout:** `profiles/<name>/skills/<skill>/` (e.g. `swift-app-developer`, `rn-app-developer`). Same `SKILL.md` format as a global skill.
- **Shared skills use symlinks.** A skill that belongs to two-plus profiles but not global lives once in `profiles/_shared/skills/<skill>/`; each profile that uses it holds a symlink `profiles/<profile>/skills/<skill> -> ../../_shared/skills/<skill>`. One source of truth, no duplication. Sync resolves the symlink and copies the real contents into the target project. Prefer this over copying a skill into multiple profiles.
- **Targeting:** `profile-assignments.json` maps project paths (`~` expanded) to a profile name or list of names.
- **The default sync never touches profiles.** `scripts/sync-agent-scripts.sh` with no args only fans out global `skills/`. Sync profiles explicitly with the non-default `profiles` provider:
  - `scripts/sync-agent-scripts.sh --provider profiles` — sync every assignment in the manifest.
  - `scripts/sync-agent-scripts.sh --provider profiles --profile <name> --project <path>` — one-off.
- **Project install is self-contained real-directory copies, not symlinks.** App repos must stay portable — a symlink into agent-scripts breaks on clone/CI/another machine and some editors won't traverse it — so each skill lands as real files:
  - `<project>/.agents/skills/<skill>/` (real dir, copied from the profile)
  - `<project>/.claude/skills/<skill>/` (real dir, copied from the profile)
  The in-repo `_shared/` model is still the single source of truth: a profile's `<skill>` may be a symlink to `_shared/skills/<skill>`, but the sync **dereferences** it (`cp -RL`) so the project gets real files, never a link. After *editing* a skill you must re-run the sync to push the copy out (that's the deliberate tradeoff vs. global symlinks). Each dest dir carries an `.agent-scripts-managed` manifest; removing a skill from a profile prunes its stale copy on the next sync, and project-authored skills (never in the manifest) are never touched. **Global skills differ:** they install into the home dir (never committed) and stay relative symlinks — see "propagates repo skills" above.
- **Global vs profile:** if nearly every project benefits, keep it in `skills/`. If it only matters for one platform/stack, put it in that profile. If two profiles share it but global doesn't, use `_shared` + symlinks (resolved to copies at install time).

#### Plugins (public agent plugins — declarative, nothing vendored)
Public plugins (e.g. Every's `compound-engineering`) are installed via each tool's own marketplace machinery, NOT vendored into this repo. We store only the *enable-config*; the tool fetches and **auto-updates** the plugin itself. This is deliberately different from skills: don't copy plugin files anywhere.

- **Manifests:** `plugins.json` at the repo root is the **global** set (installed for the current user across all projects). `profiles/<name>/plugins.json` is **per-profile** (installed only into that profile's assigned projects, Claude-only — Codex plugin enablement is inherently global).
- **Schema:** a `claude` section (`marketplaces` map + `enabled` list) and/or a `codex` section (`marketplaces` repos + `enabled` list + optional `installCommands` + `manualSteps`). See the `_comment` in `plugins.json`.
- **Apply (non-default provider):**
  - `scripts/sync-agent-scripts.sh --provider plugins` — apply the global manifest.
  - `scripts/sync-agent-scripts.sh --provider plugins --prune` — also DISABLE/REMOVE managed plugins no longer in the manifest. Profile plugins are applied by the normal `--provider profiles` run.
- **What each tool gets:**
  - **Claude** — fully declarative: `extraKnownMarketplaces` + `enabledPlugins` merged into `~/.claude/settings.json` (or `<project>/.claude/settings.json` for a profile). Claude installs/updates the marketplace on launch.
  - **Codex** — `codex plugin marketplace add <repo>` (CLI) + `[plugins."name@marketplace"] enabled = true` written into `~/.codex/config.toml` + any `installCommands` (e.g. CE's `bunx @every-env/compound-plugin … --to codex` for custom agents Codex can't yet register). No interactive `/plugins` TUI needed.
- **Pruning is scoped and safe:** `--prune` only ever touches plugins under marketplaces THIS manifest declares. Manually-installed plugins (e.g. `swift-lsp@claude-plugins-official`, `@openai-curated` Codex plugins) are never modified. Claude prune removes the `enabledPlugins` entry; Codex prune sets `enabled = false`. Marketplace *registrations* are left in place (harmless); remove a whole marketplace by hand or via `codex plugin marketplace remove`.
- **Updates:** Claude/Codex auto-update marketplace plugins through their own update flow (`/plugin marketplace update`, `codex plugin marketplace upgrade`). CE's bunx-installed Codex agents refresh on the next `--provider plugins` run (the install command re-runs).

## Design Guidelines

<frontend_aesthetics> Avoid generic "AI slop" UI. Be opinionated + distinctive.

Do:
- Typography: pick a distinctive font for consumer/marketing sites.
- Theme: commit to a palette; use CSS vars; bold accents > timid gradients.
- Use CSS animations/effects instead of custom hooks whenever suitable.
- Motion: 1–2 high-impact moments (staggered reveal beats random micro-anim).
- Background: add depth (gradients/patterns), not flat default.
Avoid: purple-on-white clichés, generic component grids, predictable layouts. </frontend_aesthetics>
