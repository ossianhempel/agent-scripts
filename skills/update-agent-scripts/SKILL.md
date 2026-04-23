---
name: update-agent-scripts
description: >
  Manage this repo's skill ecosystem: sync to global installs, or audit + prune
  orphans, duplicates, and drift across global/local installations. Sync pushes
  skills/ and slash-commands/ into ~/.agents, ~/.claude, Codex, Gemini, Cursor,
  Copilot. Audit scans global installs vs repo source-of-truth and surfaces
  stale/orphan/duplicate skills for cleanup. Use when asked to update, sync,
  audit, clean up, prune, or reconcile agent-scripts installations.
---

# Manage Agent Scripts

Two workflows live here: **sync** (push repo → installs) and **audit** (compare installs ↔ repo, clean up).

## Workflow: Sync

When asked to update or sync agent-scripts:

1. Run `scripts/sync-agent-scripts.sh --dry-run` (from any directory).
2. Ask for confirmation before running the real sync.
3. If the user wants specific providers, pass `--providers`.
4. Cursor defaults to global (`~/.cursor/commands`) targets.
5. Copilot prompts are opt-in: require `--copilot-scope` plus an explicit path
   for workspace or user prompts.
6. Use `--agents-scope both` to also deploy skills to `./.agents/skills` in the
   current project directory.
7. Summarize what was updated and any providers skipped.

## Workflow: Audit & Clean Up

When asked to audit, clean up, prune, or reconcile skills:

1. Run `scripts/skills-audit.py scan` and read all four sections.
2. Walk each finding with the user and decide an action before touching anything.
3. Execute the chosen actions, then re-run `scan` to confirm a clean state.

### Scan sections and what each means

**Orphans** — skill exists in a global install (`~/.agents`, `~/.claude`,
`~/.codex`, `~/.gemini`, `~/.cursor`) but **not** in `skills/`. The repo is the
source of truth, so each orphan is either:
- A skill that belongs in the repo and needs to be added back (useful, manually
  installed, from upstream, etc.)
- A stale/duplicate/obsolete skill that should be pruned

**Content drift (global copies differ)** — same skill exists in two global
scopes but the files don't match (e.g. `~/.agents/skills/foo` vs
`~/.claude/skills/foo` diverged). Fix by running the sync to re-align them.

**Repo/global drift** — installed global copy differs from the repo copy. Fix
with sync.

**Local shadows** — a project-scoped skill
(`~/Developer/*/.{agents,claude,cursor}/skills/`) has the same name as a
globally-installed skill. This is **informational**, not a problem — it usually
means a project intentionally overrides the global version. Only act if the
user asks to consolidate.

### Decision tree for each orphan

Walk every orphan with the user and pick one:

| Situation | Action |
|---|---|
| Stale/duplicate (e.g. older version of a skill already renamed in repo) | **Prune** — delete from global |
| Useful skill manually installed, missing from repo | **Add to repo** — `cp -RL` from global to `skills/`, then re-sync |
| Project-specific (only relevant inside one repo) | **Move to that repo** — `cp -R` into `<repo>/.claude/skills/<name>/`, then prune globally. If the repo already tracks it under git, use `git rm -r` instead of plain `rm` so the deletion is staged for review. |
| Broken (no `SKILL.md`, empty dir) | **Delete from repo and global** |
| Upstream-sourced (from a public skills repo like github.com/Leonxlnx/taste-skill) | Clone upstream, match directory name to `name:` in frontmatter (they often differ), `cp -R` each wanted skill into `skills/`, then re-sync |

### What counts as a "skill"

A directory is a skill only if it contains `SKILL.md` directly. The audit
script already enforces this; do not second-guess:
- Codex's `~/.codex/skills/.system/` (hidden, marker file) is Codex-managed,
  not user content — leave alone
- `~/.codex/skills/codex-primary-runtime/` is a namespace container (skills
  nested one level deeper), not a skill — leave alone
- Any directory starting with `.` is skipped

### Symlinks in global installs

Global skills are sometimes symlinked across scopes (e.g.
`~/.claude/skills/postiz` → `~/.agents/skills/postiz`). When copying from
`~/.claude/skills/<name>` into the repo, use `cp -RL` (follow symlinks) or
copy from the real target in `~/.agents/skills/` instead. A plain `cp -R`
will copy the symlink and then break when relative paths don't resolve from
the new location.

### Prune (destructive — dry-run first)

- `scripts/skills-audit.py prune` — dry-run, lists what would be deleted
- `scripts/skills-audit.py prune --execute` — actually deletes

Prune only removes global orphans (skills missing from `skills/`). It never
touches project-scoped skills in `~/Developer/*/.{agents,claude,cursor}/skills/`.
Safety invariant: it refuses to delete anything outside the five known global
scope roots.

Only run `--execute` after walking every orphan with the user — there's no
recovery beyond pulling the repo again for skills that were previously synced
out.

### After cleanup

1. If any skills were added to the repo, run the sync workflow above to
   propagate them to all global installs.
2. Re-run `scripts/skills-audit.py scan` — it should report "none" for
   orphans, drift, and repo/global drift.
3. Commit any staged deletions in project repos (the audit flow uses `git rm`
   for tracked project-scoped skills; those show up in `git status` but are
   not auto-committed).
