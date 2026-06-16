---
summary: Date-stamped log of user-facing changes to agent-scripts — skills added/removed/renamed, sync/audit behavior, AGENTS guidance, profile mechanics.
read_when:
  - Before adding/removing/renaming a skill — drop a CHANGELOG entry the same commit.
  - When asked "what changed recently in agent-scripts".
---

# Changelog

A running log of meaningful changes to this toolkit — skills, profiles, sync/audit behavior, AGENTS guidance. One section per change, reverse-chronological. Add an entry whenever you ship something another agent or future-you needs to know about. Curate with the `update-changelog` skill.

## 2026-06-16 — Archive dev-mechanics + frontend-design profile skills; rely on official plugins

- Strategic shift: iOS/macOS/Expo build-run-debug and Stripe now rely on **directly-installed agent plugins** (`swift-lsp`, `build-ios-apps`, `expo`, `stripe`) in Claude Code / Codex instead of skills vendored into repos. Profiles keep only bespoke "meta" skills with no plugin equivalent. Global `skills/` untouched.
- Archived to `archived-skills/` (recoverable, not deleted):
  - **iOS dev** (`swift-app-developer`): `ios-app-intents`, `ios-ettrace-performance`, `ios-memgraph-leaks`, `ios-simulator-browser`, `swiftui-liquid-glass`, `swiftui-ui-patterns`, `swiftui-view-refactor`.
  - **macOS dev** (`macos-swift-app-developer` body): `appkit-interop`, `build-run-debug`, `liquid-glass`, `packaging-notarization`, `signing-entitlements`, `swiftpm-macos`, `swiftui-patterns`, `telemetry`, `test-triage`, `view-refactor`, `window-management`.
  - **Expo/RN dev** (`rn-app-developer`): `building-native-ui`, `codex-expo-run-actions`, `expo-api-routes`, `expo-cicd-workflows`, `expo-deployment`, `expo-dev-client`, `expo-module`, `expo-tailwind-setup`, `expo-ui-jetpack-compose`, `expo-ui-swift-ui`, `native-data-fetching`, `react-native-skills`, `upgrading-expo`, `use-dom`. (`convex-expo-skill` kept — Convex family.)
  - **Frontend web-design** (`web-base`): `design-taste-frontend`, `frontend-app-builder`, `frontend-testing-debugging`, `gpt-taste`, `high-end-visual-design`, `image-to-code-skill`, `industrial-brutalist-ui`, `minimalist-ui`, `redesign-existing-projects`, `shadcn`.
  - **Shared iOS/Swift dev** (`_shared`): `swift-concurrency-expert`, `swiftui-performance-audit`, `ios-debugger-agent`.
  - **Payments** (`payments-stripe`): `stripe-best-practices` — profile emptied and removed; `payments-stripe` stripped from all `profile-assignments.json` entries.
- Kept (bespoke, no official plugin): `asc-*`, RevenueCat, Convex, Clerk, better-auth, ASO/marketing (`app-store-*`, `app-icon-optimization`, `ios-marketing-capture`, `baguette`, `onboarding-flow`, `create-onboarding-video`, `remotion-best-practices`), `release-ios-app`, `release-mac-app`, `asc-version-guard`, web framework/tooling (`fw-*`, `web-monorepo`, `web-tooling`), `data-analytics` (standalone, unassigned).
- Profile sync (`--provider profiles`) prunes the archived copies out of the assigned repos on next run.

## 2026-06-15 — Delete Playwright skill, archive grill-with-docs, trim macOS ASO bundle

- Deleted the `playwright` skill entirely; `agent-browser` is the sole browser-automation skill.
- Archived `grill-with-docs` to `archived-skills/` and removed it from all profiles (`web-base`, `swift-app-developer`, `rn-app-developer`, `macos-swift-app-developer`).
- Removed legacy ASO skills (`app-icon-optimization`, `app-store-optimization`, `app-store-screenshots`) from `macos-swift-app-developer` — direct-download macOS apps don't need them. The consolidated 4-skill ASC bundle (`asc-release`, `asc-metadata`, `asc-pricing`, `asc-version-guard`) remains on iOS/RN profiles only.

## 2026-06-15 — Scope release and Playwright skills to profiles

- Moved `release-ios-app` out of global `skills/` into `profiles/_shared/skills/` and linked it from `swift-app-developer` and `rn-app-developer`.
- Moved `release-mac-app` out of global `skills/` into `profiles/_shared/skills/` and linked it from `macos-swift-app-developer` (replacing the stale shared copy).
- Moved `playwright` out of global `skills/` into `web-base`; `agent-browser` remains the global browser-automation skill.
- Updated release skill command examples to use project-local `./.agents/skills/...` paths.

- Added `bin/browser-tools` bash shim that executes the underlying `scripts/browser-tools.ts` DevTools helper using `tsx`, `bun`, or `npx` automatically.
- Updated `tools.md` to point to `bin/browser-tools` as the canonical location and entrypoint.
- Added a `### Browser Control` section to the global `AGENTS.md` instructions file directing agents to use `bin/browser-tools` for lightweight browser tasks.

## 2026-06-15 — Restore `oracle` global skill

- Restored `skills/oracle/` to global skills (moved from `archived-skills/oracle/`) and updated it with the latest upstream changes from `@steipete/oracle`.

## 2026-06-14 — Add `release-ios-app` global skill

- New global `skills/release-ios-app/` orchestrating the iOS/Expo release flow (version-bump policy, `develop`→`main` promotion PR, Xcode Cloud vs EAS build, version-must-exceed-live gate, promote-the-validated-build golden rule, Convex backend-deploy safeguard, App Store submission via the `asc` flow). Mirrors `release-mac-app`: global skill + repo-owned `.ios-release.env` manifest.
- Ships `references/{manifest,native-xcodecloud,expo-eas}.md` and an executable `scripts/ios-release`. Hands off final readiness/submission to `asc-release` and What's New to `asc-whats-new-writer`.

## 2026-06-14 — Add `zoom-out` skill

- Added `skills/zoom-out/` (from Matt Pocock). Backfilled this CHANGELOG entry — the skill reached `main` without one.

## 2026-06-14 — Tighten global AGENTS guidance

- Condensed verbose handoff and verification rules into shorter operational bullets.
- Added confidentiality, secrets, public GitHub body, repo package-manager/runtime, and skill-frontmatter hygiene rules.
- Replaced the long inline sync/profile/plugin manual with pointers to `docs/syncing.md`, `docs/supported-agents.md`, and `docs/subagents.md`.

## 2026-06-14 — Promote `clerk-cli` and `convex-cli` to global skills

- Moved `clerk-cli` and `convex-cli` from `profiles/_shared/skills/` to `skills/` so operational CLI guidance is always available (matches `readwise-cli` / AGENTS.md tools pattern).
- Removed profile symlinks from `auth-clerk`, `convex`, `swift-app-developer`, and `rn-app-developer`; profile sync prunes stale project copies.
- Added `tools.md` entries for both CLIs. Setup/auth/framework Convex and Clerk skills stay profile-scoped.

## 2026-06-14 — Consolidate 9 ASC skills into 3 (release / metadata / pricing)

- Merged the App Store Connect skill fleet from 11 → 4. Nine `asc-*` skills collapsed into three router skills under `profiles/_shared/skills/`, each a short `SKILL.md` that routes to the original bodies moved **verbatim** into `reference/`:
  - `asc-release` ← `asc-cli-usage` + `asc-xcode-build` + `asc-release-flow` + `asc-workflow`
  - `asc-metadata` ← `asc-aso-audit` (+ `aso_rules.md`, `experiments.md`) + `asc-localize-metadata` + `asc-whats-new-writer` (+ `release_notes_guidelines.md`)
  - `asc-pricing` ← `asc-ppp-pricing` + `asc-revenuecat-catalog-sync` (+ `examples.md`, `references.md`)
- `asc-version-guard` kept standalone — it's runnable install infra (shell lib + CI scripts), not guidance.
- Motivation: skills audit showed the always-loaded description budget at ~105% of the Codex 2% cap. Collapsing 9 descriptions → 3 reclaims budget; no body content lost (progressive disclosure via reference files).
- Profile wiring: `asc` profile gets `asc-release` + `asc-metadata` (never had pricing); `swift-app-developer` and `rn-app-developer` get all three. Symlinks repointed; old shared dirs removed.

## 2026-06-14 — Add `release-mac-app` global skill

- Added global `skills/release-mac-app/`, adapted from Peter Steinberger's macOS release helper, for Sparkle appcasts, Developer ID signing, notarization, GitHub Release assets, appcast verification, and release closeout.
- Adapted the launcher for Ossian's `~/Developer/agent-scripts` layout, repo-local SwiftPM Sparkle tools, system Python appcast parsing, and Homebrew Bash re-exec when needed.

## 2026-06-14 — Add `convex-cli` skill

- New `profiles/_shared/skills/convex-cli/` for operating `npx convex` (dev/deploy/run/data/env/logs/insights/import/export). Mirrors the `clerk-cli` pattern — operational CLI work, not backend code authoring.
- Symlinked into `convex`, `swift-app-developer`, and `rn-app-developer` profiles. Never existed before; CLI bits were scattered across `convex-quickstart` and `convex-performance-audit` only.

## 2026-06-10 — Add 3 build-web-apps skills to web-app-developer
- Vendored `frontend-app-builder`, `frontend-testing-debugging`, and `stripe-best-practices` from the OpenAI `build-web-apps` plugin into `profiles/web-app-developer/skills/` (11 files) with `metadata.source`. Skipped `react-best-practices` and `shadcn-best-practices` (duplicates of existing `vercel-react-best-practices` / `shadcn`) and `supabase-best-practices` (not wanted). `stripe-best-practices` was previously dropped as Codex-bundled; re-added by request so all tools get it.

## 2026-06-10 — Add Expo plugin skills to rn-app-developer
- Vendored all 13 skills from the OpenAI `expo` plugin into `profiles/rn-app-developer/skills/` as real dirs (61 files) with `metadata.source`: `building-native-ui`, `codex-expo-run-actions`, `expo-api-routes`, `expo-cicd-workflows`, `expo-deployment`, `expo-dev-client`, `expo-module`, `expo-tailwind-setup`, `expo-ui-jetpack-compose`, `expo-ui-swift-ui`, `native-data-fetching`, `upgrading-expo`, `use-dom`. (These were dropped in an earlier restructure as Codex-plugin-bundled; re-vendored so all tools — incl. Claude — get them. Coexist with the Convex/project-specific `react-native-skills`/`convex-expo-skill`.)

## 2026-06-10 — Add data-analytics profile (build-web-data-visualization)
- New `profiles/data-analytics/` profile for data analytics / data-science / data-viz work. Vendored all 18 skills from the `build-web-data-visualization` OpenAI plugin as real dirs with `metadata.source` (119 files): `data-visualization` (router), `d3-`, `threejs-`, `canvas2d-`, `react-and-nextjs-`, `geospatial-`, `statistical-and-uncertainty-`, `grammar-of-graphics-`, `node-link-and-diagram-layout`, `gantt-chart-`, `uml-and-software-architecture-`, `dashboards-and-real-time-`, `scrollytelling-and-parallax-`, `accessibility-and-inclusive-`, `reports-pdfs-and-slide-automation`, `testing-data-visualizations`, `typescript-data-visualization-engineering`, `visualization-strategy-and-critique`.
- Not yet assigned to any project in `profile-assignments.json` (no target project given) — assign it there to start syncing.

## 2026-06-10 — Profile skills install as copies, not symlinks
- **Reverted profile install from symlinks back to self-contained copies.** Project-scoped profile skills now land in `<project>/.agents/skills/<skill>/` and `<project>/.claude/skills/<skill>/` as real directories (`cp -RL`, dereferencing the in-repo `_shared` symlinks) instead of relative symlinks into agent-scripts. Reason: symlinks into agent-scripts break the moment an app repo is cloned, run in CI, or opened on another machine, and some editors/indexers won't traverse them. agent-scripts is no longer a runtime dependency of assigned projects. Tradeoff: editing a skill now requires a re-sync to push it. **Global skills are unchanged — they stay symlinks** (home dir, never committed, no portability problem). AGENTS.md↔CLAUDE.md symlinks unchanged.
- **In-repo `_shared` model kept** as the single source of truth; the sync dereferences it at install time. Edit a shared skill once.
- **Safe prune for project copies.** Each project skill dir carries an `.agent-scripts-managed` manifest listing what the sync owns. Removing a skill from a profile prunes its stale copy on the next sync, plus any dangling symlinks; project-authored skills (never in the manifest) are never touched. `scripts/sync-agent-scripts.sh` rewritten accordingly (`copy_skill_dir`, `prune_managed_skills`, `sync_profiles_to_project` with by-project grouping + union for multi-profile projects).
- **`skills-audit.py` updated to match:** "managed" is now determined by the `.agent-scripts-managed` manifest (via `managed_names_in`), not by symlink shape. Removed `is_managed_symlink`/`all_profile_skills`. Orphan/native classification and `prune --profiles` safety preserved and re-verified.
- **build-ios-apps fully vendored** into `swift-app-developer` — all 9 skills (`ios-app-intents`, `ios-debugger-agent`, `ios-ettrace-performance`, `ios-memgraph-leaks`, `ios-simulator-browser`, `swiftui-liquid-glass`, `swiftui-performance-audit`, `swiftui-ui-patterns`, `swiftui-view-refactor`) as real dirs with upstream exec bits + `metadata.source`. Fixed broken `_shared` symlinks left by an earlier refactor (`rn-app-developer/ios-debugger-agent`, `macos-swift-app-developer/swiftui-performance-audit`).
- **Clerk for macOS:** promoted `clerk-swift` from `swift-app-developer` into `_shared` (now shared by swift + macos) and added it to `macos-swift-app-developer`. (`clerk-custom-ui` was added then dropped — web-oriented, not native-macOS relevant.)
- Docs (`AGENTS.md`, `docs/syncing.md`, `profiles/README.md`, `README.md`) and the sync test suite updated; added regression coverage for copy install + prune safety.

## 2026-06-09 — Remove all agent hooks
- Removed all agent hook infrastructure: `hooks/scripts/git-auto-pull-current-branch.sh`, `hooks/scripts/track-skill-usage.py`, `hooks/scripts/install-skill-usage-hooks.py`, and the `hooks/` directory.
- Stripped `sync_codex_hook` and `sync_claude_hook` functions and all hook install code from `scripts/sync-agent-scripts.sh` (both Codex and Claude provider blocks). Sync no longer touches `~/.codex/hooks.json` or `~/.claude/settings.json` hooks.
- Removed the skill-usage reporting toolchain (`scripts/skill-usage-report.py`, `scripts/skill-dashboard-server.py`, `bin/skill-usage*`, `bin/skill-dashboard`), dashboard UI (`dashboard/index.html`, `Skill Dashboard.command`), tracking docs (`docs/skill-usage-tracking.md`), and the auto-pull test (`test/test-git-auto-pull-current-branch.sh`).
- Updated test assertions to reflect the removed hook output.

## 2026-06-09 — Clean duplicate profile skills and tighten descriptions
- Added `shadcn` and `turborepo` to the `web-app-developer` profile, assigned `ai-kanban`, `aso-screenshots`, and `company-brain` to that profile, and replaced copied project-local skill dirs with profile symlinks where they duplicated the profile source.
- Removed local profile copies that duplicated bundled Codex plugin skills (`stripe-best-practices`, Expo profile skills, and overlapping Build iOS Apps SwiftUI/iOS debugger skills) and pruned the resulting managed dangling project links.
- Shortened high-cost skill descriptions while preserving trigger nouns for planning, brainstorming, compounding, frontend, browser automation, Obsidian, shadcn, Turborepo, and related profile skills.

## 2026-06-08 — Move grill-with-docs into development profiles
- Moved `grill-with-docs` out of global skills and into `profiles/_shared/skills/grill-with-docs/`, then linked it into the Swift app, macOS Swift app, React Native app, and web app profiles. Updated active skill indexing and glossary-format references to the new shared profile path.
- Replaced the stale `~/Developer/voice-to-text` macOS profile assignment with `~/Developer/agent-wispr`, and added `~/Developer/agent-wispr-cloud` to the web app profile.

## 2026-06-08 — Archive Peekaboo global skill
- Moved the global `peekaboo` skill to `archived-skills/peekaboo/` so it no longer syncs as an active global skill. Kept the CLI reference in `tools.md` and pointed it at the archived skill.

## 2026-06-08 — Add TanStack Start web profile skill
- Added `tanstack-start-best-practices` to `profiles/web-app-developer/skills/`, covering TanStack Start routing, server functions, middleware, server routes, auth, deployment, migration, and verification guidance based on official TanStack docs.
- Assigned `~/Developer/tiktok-slides` to the `web-app-developer` profile so it receives the shared web app skills.
- Assigned `~/Developer/completia` to the `macos-swift-app-developer` profile so it receives the shared macOS app skills.

## 2026-06-08 — Add global teach skill
- Added Matt Pocock's `teach` skill as a global skill, including its mission, resource, glossary, and learning-record format files. Synced it to the global agent skill roots.

## 2026-06-08 — Add OpenAI macOS app skills to macOS profile
- Added the OpenAI `build-macos-apps` skills to `profiles/macos-swift-app-developer/`: AppKit interop, build/run/debug, Liquid Glass, packaging/notarization, signing/entitlements, SwiftPM macOS, SwiftUI patterns, telemetry, test triage, view refactor, and window management.
- Replaced the macOS profile's generic `swiftui-liquid-glass`, `swiftui-ui-patterns`, and `swiftui-view-refactor` links with the macOS-specific upstream skills to avoid duplicate SwiftUI triggers.

## 2026-06-08 — Add Better Auth web profile skills
- Added upstream Better Auth `organization` and `create-auth` skills to `profiles/web-app-developer/skills/`, alongside the existing `better-auth-best-practices` skill. The new skills cover organization/RBAC setup and full Better Auth scaffolding for TypeScript web apps.

## 2026-06-08 — Add macOS Swift app profile
- Added `profiles/macos-swift-app-developer/` for native macOS Swift apps and assigned `recalliq` plus `voice-to-text` to it. The profile includes shared SwiftUI/concurrency/build, App Store/legal/revenue skills, Convex/Clerk support, and the new `release-mac-app` Sparkle/notarization/GitHub release helper.
- Promoted the shared Swift/Xcode skills from `swift-app-developer` into `_shared/skills/` so mobile Swift and macOS Swift profiles use one canonical copy. Synced the new profile into both assigned projects.

## 2026-06-08 — Add profile-scoped MCP sync
- Extended the `profiles` provider so `profiles/<profile>/mcp.json` is merged into each assigned project's `.mcp.json`, preserving existing project servers and warning on same-name conflicts instead of overwriting. Added `swift-app-developer/mcp.json` with project-level `xcodebuildmcp` and RevenueCat, plus `rn-app-developer/mcp.json` with RevenueCat, so app-specific MCP startup can move out of global Codex config.

## 2026-06-07 — Fix Codex skill-usage capture with unified_exec
- Codex `PostToolUse` hooks do not fire for `unified_exec` / `exec_command` shell calls yet, so skill tracking missed every Codex session with `unified_exec = true`. Added a `Stop` hook that scans rollout transcripts for `SKILL.md` reads, a `codex-backfill` mode for historical catch-up, and `hooks/scripts/install-skill-usage-hooks.py` (wired into `sync-agent-scripts.sh --provider codex`). The dashboard now backfills on refresh.

## 2026-06-07 — Exclude skill packages from staged LOC lint
- Tightened `setup-pre-commit` so the 500-line staged LOC guard applies only to source-code files outside `docs/` and `skills/`. Long docs, skill instructions, and skill helper packages no longer block commits created from this setup.

## 2026-06-07 — Use Codex hooks.json as the hook source
- Moved Codex hook sync to `~/.codex/hooks.json` so Codex no longer sees duplicate hook definitions in both `hooks.json` and `config.toml`. The JSON hook file remains the single source for Codex auto-pull and skill-usage tracking.

## 2026-06-07 — Add Git cleanup skill
- Added global skill `skills/git-cleanup/` for cleaning up merged, stale, gone, or explicitly abandoned local branches and worktrees. It classifies safe branch deletes separately from unmerged work, checks dirty worktrees before removal, and verifies the final branch/worktree state.

## 2026-06-07 — Remove unsupported Codex async hook config
- Updated Codex hook sync to omit the unsupported `async` key and scrub it from existing Codex hook entries when rewriting `~/.codex/config.toml`. This stops Codex startup from warning that async hooks are skipped while keeping the skill-usage and auto-pull hooks installed.

## 2026-06-06 — Add plan inbox skill
- Added global skill `skills/plan-inbox/` with a bundled scanner for unfinished `docs/plans/` artifacts and optional unresolved `docs/brainstorms/` backlog. It supports current-project, `--project`, `--global`, and `--json` modes, treats `Completed`/`Superseded`/`Abandoned` plans as closed, and treats brainstorms linked to plans as already planned.

## 2026-06-06 — Setup pre-commit adds staged LOC lint
- Updated `setup-pre-commit` so new hook installs add a `lint:max-lines:staged` gate with a 500-line source-file limit. The checker reads only staged added/copied/modified/renamed files, so existing oversized files do not block commits until they are touched.

## 2026-06-04 — Global skills install as symlinks; drop skill feedback logs
- **Global skills now sync as relative symlinks into the repo** instead of copies. `sync_skills_to` links each runtime's `<skill>` entry straight to `skills/<skill>` in agent-scripts (for `~/.agents/skills`, `~/.claude/skills`, and `~/.gemini/antigravity-cli/skills`), matching the model profiles already use. One source of truth, zero duplication, no drift — editing a skill no longer needs a re-sync (only add/move/delete does). Tradeoff: agent-scripts is now a hard runtime dependency of the home skill dirs; move or delete it and the links break. `make_relative_symlink` gained an opt-in `force` arg to replace the old real-dir copies (used only for fully sync-managed global dirs; profiles keep their refuse-to-clobber guard). Removed the now-dead `run_sync_dir`/`dirs_identical`/`log_sync_summary` copy helpers (−115 lines). Audit "drift" sections are now structurally always-empty.
- **Removed the per-skill `feedback.log` mechanism entirely.** Deleted all 5 (empty) `feedback.log` files and the "Feedback Log (DO THIS FIRST)" instruction blocks from `copywriter`, `onboarding-flow`, `building-native-ui`, `react-native-skills`, and archived `article-outline`. Stripped the feedback-preservation plumbing from `sync-agent-scripts.sh` and the ignore entry from `skills-audit.py`.

## 2026-06-04 — Document OpenClaw launch-agent recovery
- Added `docs/openclaw-operations.md` with the current macOS OpenClaw service facts: `ai.openclaw.gateway`, state under `~/.openclaw`, live logs under `~/Library/Logs/openclaw/gateway.log`, Telegram ingress spool checks, and the launchctl restart/verify flow.
- Removed the stale README reference to the missing `scripts/update-clawdbot.sh` helper, added README/AGENTS/tools pointers to the new operations checklist, and clarified that Telegram spool files mean Telegram delivered the message but local OpenClaw processing got stuck.

## 2026-06-04 — Local skill-usage dashboard
- Added a local-only visual dashboard for the skill-usage tracking: `scripts/skill-dashboard-server.py` (stdlib localhost server that reads the event log live), `dashboard/index.html` (self-contained, no CDNs — KPI cards, per-agent stacked top-skills bars, per-repo bars, activity sparkline, recent-invocations table, instant client-side filters), `bin/skill-dashboard`, and a double-clickable `Skill Dashboard.command` launcher.
- Deliberately **not** on GitHub Pages: the event log carries repo/client names + local paths and `agent-scripts` is public, so the dashboard binds to `127.0.0.1` and never commits/sends data. Refresh button + 20s auto-refresh re-read the file, so no terminal commands are needed during use. Documented in `docs/skill-usage-tracking.md`.

## 2026-06-04 — New primitive: cross-tool subagents (Claude + Codex)
- Added a **subagents** primitive: canonical agent definitions in `subagents/<name>.md` (Claude-flavoured `.md` + YAML), transformed per harness by `scripts/gen-subagents.py` into native formats — v1 targets **Claude Code** (`~/.claude/agents/<name>.md`) and **Codex** (`~/.codex/agents/<name>.toml`, body → `developer_instructions`). Wired as the `subagents` sync provider (in the default run). Skills can't model this because the formats genuinely differ (TOML vs MD, prompt-in-body vs prompt-in-field) and there's no portable standard. Permission model abstracted via an `access` enum (`read-only|edit|full`) expanded into each tool's model (Claude `tools` allowlist / Codex `sandbox_mode`). Pruning is manifest-based — only ever removes files the generator wrote, never hand-authored agents. Full design + roadmap (Copilot/Gemini/Cursor planned; Antigravity has no file format) in `docs/subagents.md`.
- **Promoted `learnings-researcher`** from a skill-internal inline-dispatch prompt (`skills/compound/agents/`) to a real registered subagent (`subagents/learnings-researcher.md`); `compound` now invokes it by name with an inline fallback. Researched current subagent support across Claude Code, Codex, Copilot, Gemini CLI, Cursor, Antigravity to ground the format choices (all but Antigravity ship file-based custom subagents as of mid-2026).

## 2026-06-04 — Merge `to-prd` into `plan`; retire `to-prd`
- Resolved the decisions-layer overlap between `to-prd` and `plan` by collapsing the doc set to two rungs: **brainstorm → plan**. `plan` gained an optional **Specification** section (exhaustive user stories + a behavioral contract at module/interface altitude — the old PRD layer), included only for behavior-heavy/spec'd work; it stays implementation-agnostic (no file paths) so it doesn't re-collide with the file-level Implementation Units below. Testing split kept clean: the spec names **seams**, the units write concrete **scenarios**. `plan`'s description/triggers now absorb PRD/spec/user-story requests.
- Retired `to-prd` → moved to `archived-skills/to-prd/` (history preserved via `git mv`); pruned its fanned-out copies from all runtimes. Updated `brainstorm`'s handoff/coupling refs (now point at `plan`'s spec mode) and the `README.md` skills list.
- Net pipeline: **brainstorm (why/what) → plan (spec + how) → execute → compound (learnings)**.

## 2026-06-04 — Add `brainstorm` skill (fuzzy front-end / idea exploration)
- Added global skill `skills/brainstorm/` — explores a raw, unformed idea through one-question-at-a-time dialogue and shapes it into a WHAT, writing a requirements doc to `docs/brainstorms/<YYYY-MM-DD>-<topic>-requirements.md`. Free-standing port of EveryInc's `ce-brainstorm`: keeps the rigor probes (evidence / counterfactual / specificity / minimal-version / durability), the diverge→converge flow, 2–3 approach options with a simplicity-grounded recommendation, and write-only-when-durable; drops HTML/config/pipeline machinery and non-software templates. Fills the gap the grill skills don't: grill-me *stress-tests an existing plan* (convergent), brainstorm *shapes an idea from nothing* (divergent→convergent). Complements `to-prd` (synthesize-known vs interview-to-form).
- Completes the upstream chain **brainstorm → grill → plan → execute → compound**. Wired `plan` to read a matching `docs/brainstorms/` requirements doc as its settled WHAT and trace to it, and to suggest `brainstorm` (not grill) when the idea itself is unformed. Added `docs/brainstorms/` to the global `AGENTS.md` knowledge-objects block.

## 2026-06-04 — Add `compound` skill + rename CONTEXT.md → CONCEPTS.md
- Added global skill `skills/compound/` — a session closeout that harvests learnings and routes each to a home: durable solution docs in `docs/solutions/<category>/`, prevention rules in the right `CLAUDE.md`/`AGENTS.md` (repo-specific vs cross-cutting; can delegate to `review-agent-md`), and `CONCEPTS.md` vocabulary, plus a doc-freshness sweep. A lean, free-standing port of EveryInc's `ce-compound` built around the user's standing trio: "what did we learn / how do we prevent recurrence / are the docs current". Dropped ce's YAML schema, validation script, category enum, and parallel-subagent machinery; kept overlap-aware writes and discoverability nudges. Instruction-file edits ask consent first.
- Bundled a companion subagent `skills/compound/agents/learnings-researcher.md` (port of ce's `ce-learnings-researcher`) — the *read* side of the loop: greps `docs/solutions/`, grounds in `CONCEPTS.md`, frontmatter-scores, returns ≤5 distilled prior learnings + conflict flags. Used inside compound for overlap detection (update-vs-duplicate) and standalone before new work / from `plan` to avoid re-discovering solved problems. Plain-prompt + inline-fallback pattern (matches `skill-creator`/`skill-cleaner` `agents/`), runtime-agnostic.
- Referenced the three knowledge objects (`docs/plans/`, `docs/solutions/`, `CONCEPTS.md`) in the global `AGENTS.md` Docs section so every agent knows to search prior solutions before debugging, check plans before multi-step work, and `compound` at the end.
- **Renamed `CONTEXT.md` → `CONCEPTS.md`** across all global skills (`grill-with-docs` incl. `CONTEXT-FORMAT.md` → `CONCEPTS-FORMAT.md`, `to-prd`, `plan`), and `CONTEXT-MAP.md` → `CONCEPTS-MAP.md`. The file is strictly a domain glossary, so "concepts" names it accurately; also aligns with `ce-compound`'s own `CONCEPTS.md` convention. Single source of truth, all consumers updated.

## 2026-06-03 — Add `plan` skill (free-standing implementation planner)
- Added global skill `skills/plan/` — produces a durable implementation plan and writes it to `docs/plans/<YYYY-MM-DD>-<NNN>-<type>-<slug>-plan.md`. A free-standing port of EveryInc's `ce-plan`: keeps the durable core (repo-relative paths, stable `U`-IDs, mandatory test scenarios, requirements traceability, no-code-in-plans) but cuts every hard ecosystem hook — no named subagents (uses whatever generic explore agent exists, or none), markdown-only, with Quick/Standard/Deep depth baked in. Drops into any repo.
- **Loosely coupled to `grill-me` / `grill-with-docs`** as the optional upstream "sharpen the WHAT" step that `ce-brainstorm` filled: plan suggests grilling first when the design tree is fuzzy, reads `CONTEXT.md`/`CONTEXT-MAP.md`/`docs/adr/` (grill-with-docs artifacts) to reuse domain vocabulary and honor settled ADRs, traces requirements back to grill sessions/ADRs, and offers `grill-me` to stress-test the finished plan. Coupling is one-directional and optional — plan still runs fully standalone.

## 2026-06-03 — Promote 4 web skills into web-app-developer profile
- Promoted `hono`, `better-auth-best-practices`, `vercel-composition-patterns`, and `vercel-react-best-practices` from project-native skills into `profiles/web-app-developer/skills/`. Every web-app-developer project now gets them on sync.
- Reconciled divergent copies found across projects: the canonical versions of `hono` (579-line inline-API variant) and the two `vercel-*` skills are `walkmon-web`'s superset (vercel-react-best-practices carries 72 rule files + generator scaffolding). `resume-builder`'s thinner copies and `platesnap-web`'s variant were superseded (platesnap had nothing unique).
- Replaced project-native copies in `resume-builder`, `walkmon-web`, and `platesnap-web` with the standard relative symlinks back into agent-scripts; fanned the profile out to all 11 assigned web projects. (Pre-existing project-native `stripe-best-practices` copies in walkmon-web/platesnap-web were left untouched — out of scope, flagged for later.)
- Assigned `resume-builder` and `top-of-class` to their profiles (`web-app-developer` / `swift-app-developer`) in `profile-assignments.json`.

## 2026-06-02 — Skill Usage Tracking (Claude + Codex)
- Added `hooks/scripts/track-skill-usage.py`, a `PostToolUse` hook wired into both Claude Code (`~/.claude/settings.json`, matcher `Skill`) and Codex (`~/.codex/config.toml`, matcher `exec_command`, async). It logs which skills get used to `~/.local/share/agent-skill-usage/events.jsonl` (network-free, local JSONL).
- Detection is agent-aware: Claude's `Skill` tool input vs Codex's `.../skills/<name>/SKILL.md` reads. Batch reads of many `SKILL.md` in one call are tagged `skill_scan` (catalog listing) and excluded from the report by default.
- Added `scripts/skill-usage-report.py` + `bin/skill-usage` wrapper — answers "which skills do I actually use, per repo/agent, this week?" with `--since/--agent/--repo/--by/--json` flags. By default excludes catalog scans and agent-scripts authoring noise.
- Documented in `docs/skill-usage-tracking.md`. Hook-based tracking only reaches Claude + Codex (the only supported runtimes with a comparable `PostToolUse` hook); Codex needs a one-time hook-trust approval on next launch.

## 2026-05-28 — Summarize and Peekaboo Skills
- Added global `summarize` skill for the `steipete/tap/summarize` CLI so agents know when to summarize/extract URLs, PDFs, local files, YouTube/videos, podcasts, transcripts, and stdin text.
- Added global `peekaboo` skill for the `steipete/tap/peekaboo` CLI so agents know when to inspect screenshots, verify native macOS UI, and automate apps/windows/menus/input.
- Updated `AGENTS.md` and `tools.md` to document the pattern: install the CLI for capability, add a companion skill for trigger behavior.

## 2026-05-28 — Project-Scoped Skill Profiles + Symlink Sync
- Added `profiles/<name>/skills/` layout for project-scoped skill packages, with `profiles/_shared/skills/` as a deduplicated store symlinked into the profiles that share a skill.
- Added `profiles/swift-app-developer/` (9 own iOS/SwiftUI/Xcode skills), `profiles/rn-app-developer/` (11 own Expo/RN skills promoted from gainslog), and `profiles/web-app-developer/` (14 `_shared` symlinks: convex-*, clerk + clerk-cli/setup/custom-ui, privacy-policy).
- Moved 41 platform-specific skills out of global `skills/` into the new profile layout; global is now 14 stack-agnostic skills only.
- Added `profile-assignments.json` mapping project paths to profile(s); 25 repos assigned.
- Added a non-default `profiles` provider to `scripts/sync-agent-scripts.sh` — the plain run still only fans out global `skills/`. Use `--provider profiles` (manifest-driven) or `--profile <name> --project <path>` (one-off).
- Refactored profile sync to install **relative symlinks** back into agent-scripts instead of copies — zero duplication, zero drift, edits in agent-scripts show up instantly in every assigned project.
- Extended `scripts/skills-audit.py` with profile-aware scan sections (assignments, profile orphans, project-native skills, name collisions) and a `--profiles` prune mode. Prune refuses to delete skills the repo has never seen — project-native skills are always safe.
- Documented the new system in `AGENTS.md`, `docs/syncing.md`, and `profiles/README.md`.
- Added `CHANGELOG.md` and refreshed `docs/update-changelog.md` — date-stamped log of meaningful toolkit changes, with a curation checklist (read_when-tagged doc, not a skill, mirroring steipete/agent-scripts) when the file falls behind.
- Wired up doc discovery: added `bin/docs-list` shim around the existing `scripts/docs-list.ts` so the workspace-level "run docs:list at start" convention resolves; added `summary:` + `read_when:` frontmatter to `docs/supported-agents.md` so it surfaces in the manifest; AGENTS.md now points at the tool.
- Hardened profile sync: `make_relative_symlink` now refuses to `rm -rf` a real directory or file at the target path (only replaces existing symlinks), preventing accidental loss of project-authored content that shares a name with a profile skill. Extended `is_managed_symlink` to recognize both `.claude` and `.agents` profile symlink patterns so dangling `.agents` links are now reported and prunable.
- Hardened profile prune: `prune_profiles` and `scan_profiles` now require an entry to be a managed symlink (one the profile sync created) before treating it as orphan/prunable. A real project-authored dir whose name collides with a managed profile skill stays classified as project-native and is never deleted — matches the documented "never pruned" guarantee. Also gated the `~/Developer` `CLAUDE.md ↔ AGENTS.md` symlink sweep behind the claude/agents providers so a targeted `--provider profiles` run no longer touches every other repo.

## 2026-05-24 — App Store Connect Version Guard Skill
- Added `asc-version-guard` skill for installing/repairing the App Store Connect version+build-number guard on Xcode Cloud iOS apps so a wrong `MARKETING_VERSION` or colliding build number can never reach App Store Connect.

## 2026-05-23 — Replaced `codex-review` With Upstream `autoreview`
- Replaced the local `codex-review` skill with the upstream `autoreview` skill, keeping Codex as the default/recommended review engine while adding structured findings, prompt/dataset inputs, and security-aware checks.

## 2026-05-22 — ASC Release Flow Versioning Policy
- Documented minor-vs-patch version-bump policy in the `asc-release-flow` skill.
- Added semantic versioning guidelines covering when to bump major/minor/patch for App Store releases.

## 2026-05-21 — Session Auto-Pull Hooks
- Added `SessionStart` hooks for Claude Code and Codex that fast-forward-pull the current Git branch when safe (clean tree, upstream set, no unpushed commits).
- Removed Codex CLI dependency from hook sync so the hook installs even on machines without Codex installed.

## 2026-05-15 — Antigravity CLI Sync Target
- Sync now mirrors skills to `~/.gemini/antigravity-cli/skills` in addition to `~/.agents/skills` and `~/.claude/skills`.

## How to read / add to this file

- One section per change. Header format: `## YYYY-MM-DD — Short title`.
- Bullets in past tense, user-facing impact only. Skip internal refactors and dependency bumps unless they change behavior.
- Group entries from the same day under one section if they're related.
- Don't include raw commit hashes; reference PRs/issues with `#NNN` when relevant.
- The `update-changelog` skill is the curation checklist when you've shipped several changes and need to catch the file up.
