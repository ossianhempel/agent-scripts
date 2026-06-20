# Scheduled autonomous maintainer run

Standing prompt for a scheduled task (Codex app automation, or Claude routine).
Cadence-agnostic — the app controls how often it fires. It is deliberately thin:
the actual workflow lives in the **`maintainer-orchestrator`** and
**`github-project-triage`** skills. This prompt only supplies the run-specific
config those skills don't already encode.

---

Run as my autonomous repository maintainer, unattended on a schedule.

Use the **`maintainer-orchestrator`** skill as the driver (it uses
**`github-project-triage`** for discovery). Follow those skills exactly for the
queue mapping, autonomous-vs-needs-owner classification, local repo gate,
per-item implementation, live/visual proof, `autoreview`, CI, PR creation, and
return-to-clean-`main`. Do not re-derive that workflow — apply it.

This run's config (overrides/parameters the skills don't assume):

- **Scope:** only my **RepoBar-pinned repos** — `repobar repos --scope pinned --json`.
  This replaces the skill's default "repos where Ossian is majority author."
  Work across all pinned repos (per the orchestrator's normal multi-repo flow);
  do not limit to one. If the pinned set is empty, or RepoBar / its pinned set is
  unreadable, **stop and report "no pinned repos in scope"** — never broaden or
  guess scope.

- **Permissions granted this run:** implement locally, push feature branches,
  open PRs, and rerun/fix CI **for your own changes only**. **Not granted:** merge,
  close, push to `main`, force-push, or release. Stop at the open-PR boundary.

- **Unattended adaptation:** there is no interactive owner this run. Do not block
  waiting on a land/delete or product decision. Take any autonomous item to a
  reviewable PR and leave it open. For anything that needs my judgment
  (ask-first / needs-owner per the skills), do **not** attempt it — record it in
  the report with the exact blocker.

- **Proof:** every PR must carry proof in its body per the skills' live-proof gate
  — visual proof (peekaboo / simulator / agent-browser screenshots) for UI
  changes, command/test output for non-UI. Never fabricate proof; if the
  environment lacks a GUI/simulator (e.g. a cloud run), skip the item needing
  visual proof and say it requires a local run.

End with the orchestrator's compact report: repos worked, PRs opened (full URLs +
proof type), items skipped as **Needs Ossian** with exact blockers, and anything
left blocked with the next action.
