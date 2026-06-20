# Work-migration scheduled run prompt

Standing prompt for the scheduled Things → GitHub issue migration. This is
deliberately thin: the reusable workflow lives in the **`work-migration`** skill.
This file captures the run-specific configuration so the automation can be
recreated from git.

Automation id: `pinned-repo-things-to-issues`
Suggested cadence: once per day

---

Use the **`work-migration`** skill to migrate my Things tasks into GitHub issues,
fully autonomous and unattended on a schedule. Follow that skill exactly for the
prepare → curate → apply-plan flow, its Run Policy, and its Delegation model. Do
not re-derive the workflow — apply it.

**No human in the loop.** Never ask me anything, never wait on a decision. The
agent judges suitability itself. If a route can't run cleanly, skip it, record
the blocker, and continue the others.

This run's config:

- **Scope:** every pipeline in the `things-inbox` group of the skill config
  (`skills/work-migration/config/config.json`). Those routes are the
  RepoBar-pinned repos mapped to their Things project/area. Process all of them.

- **Delegation:** fan out one worker per route to `prepare` + curate and return a
  plan JSON (curation is read-only — workers do not apply). Then apply the plans
  **serially** from the root (`apply-plan --apply`, one route at a time) to keep
  the shared state ledger and Things writes safe. See the skill's Delegation
  section.

- **Per-repo cap:** at most **5** suitable issues per destination repo this run.
  Stop each route once its plan holds 5; the rest roll to the next run.

- **Suitability:** keep concrete, actionable work (bug, well-scoped feature,
  refactor, tech-debt, infra) and focused research/decision questions with a
  clear deliverable (label those `research`). Skip vague musings,
  marketing/social/strategy, personal reminders, pure content/data entry, and
  anything too underspecified to act on. Remove skipped entries from the plan so
  they stay untouched in Things.

- **Completion:** `apply-plan --apply` creates the issues (≤5 per repo), appends
  the issue link to each migrated Things task, and completes it. Confirm each
  route's `afterCreate.things.complete` is `true` first. Never leave a migrated
  item open in Things (no living in both places). Only migrated items get
  completed; skipped items stay open. Do not use raw `run --apply`.

End with a per-repo report: how many issues created, how many skipped, and the
issue URLs.
