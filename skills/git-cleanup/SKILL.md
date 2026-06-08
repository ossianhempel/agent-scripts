---
name: git-cleanup
description: Clean up local Git branches and worktrees that are merged, stale, gone on the remote, or explicitly abandoned. Use this whenever the user asks to clean up merged branches, remove gone branches, tidy local branches, prune old worktrees, delete abandoned work, clean local git clutter, or inspect what branches/worktrees can safely be removed.
argument-hint: "[optional: --dry-run | --force-abandoned | branch/worktree names]"
---

# Git Cleanup

Use this skill to remove local Git clutter without losing work. Default to a
dry, evidence-first pass: inspect, classify, show the user what is safe, then
delete only the safe set unless the user explicitly asked to delete abandoned
work.

This skill is pure Git and works in any repository.

## Finishing Criteria

Before reporting back:

- stale remote refs were pruned or pruning was attempted
- current branch, protected branches, and dirty worktrees were excluded
- merged/gone branches were separated from unmerged branches
- worktrees were listed and stale/clean/dirty state was checked
- deletions, if any, were verified with `git branch --list` and
  `git worktree list`

## Workflow

1. **Inspect repository state.**

   ```bash
   git status --short
   git branch --show-current
   git remote -v
   git worktree list --porcelain
   ```

   If the current worktree has uncommitted changes, continue with inventory but
   do not remove the current worktree or switch branches as part of cleanup.

2. **Prune stale remote refs.**

   ```bash
   git fetch --prune
   git remote prune origin
   ```

   If there are multiple remotes, prune the tracked remote for the branches in
   question. If network/auth fails, continue with local evidence and say remote
   freshness could not be verified.

3. **Find local branch candidates.**

   Use these views together:

   ```bash
   git branch -vv
   git branch --merged
   git branch --no-merged
   git for-each-ref --format='%(refname:short) %(upstream:track) %(committerdate:short) %(subject)' refs/heads
   ```

   Classify:

   - **Safe delete**: local branch is merged into the current base or its
     upstream is `gone`, and `git branch -d <branch>` succeeds.
   - **Review first**: branch is gone upstream but not merged locally, has no
     upstream, or appears abandoned by age/name but contains unique commits.
   - **Never delete by default**: current branch, `main`, `master`, `develop`,
     `dev`, `trunk`, `release/*`, `production`, or any branch checked out by a
     worktree.

4. **Find worktree candidates.**

   ```bash
   git worktree list --porcelain
   git worktree prune --dry-run
   ```

   For each non-main worktree, inspect its path:

   ```bash
   git -C <worktree-path> status --short
   git -C <worktree-path> branch --show-current
   ```

   Classify:

   - **Stale metadata**: path is missing or `git worktree prune --dry-run`
     reports it. Safe to prune metadata with `git worktree prune`.
   - **Clean removable worktree**: path exists, is not the main worktree, and
     `status --short` is empty. Remove only if its branch is merged/gone or the
     user named it.
   - **Dirty worktree**: has uncommitted changes. Never remove unless the user
     explicitly confirms losing that work.

5. **Show the cleanup plan before deleting.**

   Report grouped candidates:

   - branches safe to delete
   - branches kept for review
   - worktrees safe to remove
   - worktrees kept because dirty/current/protected
   - stale worktree metadata to prune

   If the user asked for a dry run, stop here.

6. **Delete conservatively.**

   Branches:

   ```bash
   git branch -d <branch>
   ```

   Use `git branch -D <branch>` only when the user explicitly asks to abandon
   that branch or confirms that the unique commits can be lost.

   Worktrees:

   ```bash
   git worktree remove <worktree-path>
   git worktree prune
   ```

   Use `git worktree remove --force` only with explicit confirmation for a
   dirty or otherwise blocked abandoned worktree.

7. **Verify and report.**

   ```bash
   git branch --list
   git worktree list
   ```

   Tell the user what was removed, what was kept, and any branch/worktree that
   still needs a decision.

## Rules

- Never delete remote branches in this workflow.
- Never delete the current branch or protected branches by default.
- Never force-delete unique commits just because a branch is old.
- Never remove a dirty worktree without explicit confirmation.
- Prefer `trash` for non-Git filesystem deletes; use Git worktree commands for
  Git worktree removal.
- Keep the final response plain: what was cleaned, what remains, and why.
