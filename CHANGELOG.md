---
summary: Date-stamped log of user-facing changes to agent-scripts — skills added/removed/renamed, sync/audit behavior, AGENTS guidance, profile mechanics.
read_when:
  - Before adding/removing/renaming a skill — drop a CHANGELOG entry the same commit.
  - When asked "what changed recently in agent-scripts".
---

# Changelog

A running log of meaningful changes to this toolkit — skills, profiles, sync/audit behavior, AGENTS guidance. One section per change, reverse-chronological. Add an entry whenever you ship something another agent or future-you needs to know about. Curate with the `update-changelog` skill.

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
