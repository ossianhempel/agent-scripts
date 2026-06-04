---
summary: Date-stamped log of user-facing changes to agent-scripts — skills added/removed/renamed, sync/audit behavior, AGENTS guidance, profile mechanics.
read_when:
  - Before adding/removing/renaming a skill — drop a CHANGELOG entry the same commit.
  - When asked "what changed recently in agent-scripts".
---

# Changelog

A running log of meaningful changes to this toolkit — skills, profiles, sync/audit behavior, AGENTS guidance. One section per change, reverse-chronological. Add an entry whenever you ship something another agent or future-you needs to know about. Curate with the `update-changelog` skill.

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
