---
name: work-migration
description: Operate the private Notion/Things to GitHub issue migration system. Use this whenever the user mentions migrating Notion tasks, Things inbox/project items, private GitHub issue intake, scheduled Things processing, work-migrate, or mapping Things projects to repos.
---

# work-migration

Use this skill for the private work migration pipe backed by `work-migrate`.

## Mental Model

There are two lanes:

- **Notion batch migration**: explicit one-time or occasional batch migration from Notion Tasks into GitHub Issues.
- **Things inbox migration**: scheduled migration from configured Things projects into mapped GitHub repos.

Do not route work DevOps, Jira, or H&M through this private config. Those belong in a separate pipeline with separate credentials and state.

## Run Policy

These three rules are non-negotiable for every migration run:

1. **Cap at 10 issues per run.** Create at most 10 GitHub issues per run, regardless of how many source items are pending. Pull a larger candidate batch (the `prepare` default of 25 is fine), then keep at most 10 in the applied plan. Remaining pending items are picked up on the next run.
2. **Evaluate suitability, skip if not a good issue.** The test is *"does it have a clear next action and definition of done?"* — not "is it a question?".
   - **Suitable:** concrete, actionable engineering work (bug, well-scoped feature, refactor, tech-debt, infra) **and** focused research/decision questions with a clear investigative deliverable (e.g. "investigate X, suggest 2–3 approaches"). Tag research/decision/spike items with a `research` label so they read differently from implementation work.
   - **Skip:** vague or unactionable musings (e.g. "dumb down the app", "remove decision fatigue"), marketing/social/strategy notes, personal reminders, pure content/data entry, and anything too underspecified to act on.
   When a candidate is unsuitable, **drop it from the plan and move to the next candidate** until you reach 10 suitable issues or exhaust the batch. Skipped items are left **untouched** in Things (not completed, not noted) so they stay in the queue.
3. **Migrated means done in Things — never live in both places.** Every item that becomes a GitHub issue must be **completed** in Things in the same run (`afterCreate.things.complete: true`). An item must never remain open in Things after its issue exists. Conversely, only items that actually became issues get completed; skipped items stay open.

Before `apply-plan --apply`, confirm `afterCreate.things.complete` is `true` for the route. If it is not, stop and fix the config rather than creating duplicates.

## Commands

List routes:

```bash
~/Developer/agent-scripts/bin/work-migrate list-pipelines
```

Validate config:

```bash
~/Developer/agent-scripts/bin/work-migrate validate-config
```

Preview Notion batch migration:

```bash
~/Developer/agent-scripts/bin/work-migrate run notion-gainslog-to-github --limit 10
```

Apply Notion batch migration:

```bash
~/Developer/agent-scripts/bin/work-migrate run notion-gainslog-to-github --limit 10 --apply
```

Preview scheduled Things routes:

```bash
~/Developer/agent-scripts/bin/work-migrate run-all --group things-inbox --limit 10
```

Prepare an agent-curated issue plan:

```bash
~/Developer/agent-scripts/bin/work-migrate prepare things-mejla-to-github --limit 10 --out /tmp/mejla-issue-plan.json
```

Apply a reviewed issue plan:

```bash
~/Developer/agent-scripts/bin/work-migrate apply-plan /tmp/mejla-issue-plan.json --apply
```

## Source Handling

Dry runs never mutate GitHub, Notion, or Things.

The normal creation flow is intentionally agent-curated:

1. `prepare` loads pending source items (default 25) and writes an issue-plan JSON file.
2. The LLM/orchestrator processes each draft in order:
   - **Evaluate suitability first** (see Run Policy rule 2). If the item is not a good fit for an issue tracker, **remove its entry from the plan JSON** and continue to the next candidate. Do not rewrite or apply it.
   - For suitable items, rewrite the draft into a proper issue: concise title, useful description, acceptance criteria or notes, and suitable labels/assignees/milestone.
   - **Stop once the plan holds 10 suitable issues.** Remove any remaining entries beyond 10 so they are not created this run.
3. `apply-plan --apply` creates the destination issues (≤10), records state, and post-processes Things — appending the issue link and **completing** each migrated Things task. Skipped entries were removed from the plan, so they are never created and never touched in Things.

Do not use raw `run --apply` for normal migration. It is blocked unless `--allow-raw` is provided, and that override is only for emergency transport tests.

On successful `apply-plan --apply`:

- GitHub issue is created with source provenance in the body.
- State ledger records `source -> destination` in `~/.local/state/work-migrate/state.json`.
- Notion items are not changed by default. This keeps one-time batch migration auditable and reversible from the ledger.
- Things items are post-processed according to config. The private inbox routes append the GitHub issue link and complete the Things task, clearing it from the inbox/project.

The state ledger is the dedupe authority. If an item already exists in the ledger, reruns skip it even if the source remains visible in Notion or Things.

## Config

Live config:

```text
~/.config/work-migrate/config.json
```

Repo template:

```text
skills/work-migration/config/work-migrate.example.json
```

When adding a private repo route:

1. Add or choose a Things project.
2. Add a pipeline with `group: "things-inbox"`.
3. Set `source.project` to the exact Things project title.
4. Set `destination.repo` to `owner/repo`.
5. Keep `afterCreate.things.complete: true` unless the user explicitly wants Things to retain imported items.

## Safety

- Always run without `--apply` first.
- Always prepare and rewrite an issue plan before creating GitHub issues.
- Never delete source items as part of this workflow.
- Do not print Notion tokens, GitHub tokens, or source item private notes unnecessarily.
- If changing source post-processing behavior, state exactly what will happen before running `--apply`.
