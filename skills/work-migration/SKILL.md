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

1. **Cap at 5 issues per repo per run.** Create at most 5 GitHub issues per destination repo per run, regardless of how many source items are pending. Pull a larger candidate batch (the `prepare` default of 25 is fine), then keep at most 5 in the applied plan for that route. Remaining pending items are picked up on the next run.
2. **Evaluate suitability, skip if not a good issue.** The test is *"does it have a clear next action and definition of done?"* — not "is it a question?".
   - **Suitable:** concrete, actionable engineering work (bug, well-scoped feature, refactor, tech-debt, infra) **and** focused research/decision questions with a clear investigative deliverable (e.g. "investigate X, suggest 2–3 approaches"). Tag research/decision/spike items with a `research` label so they read differently from implementation work.
   - **Skip:** vague or unactionable musings (e.g. "dumb down the app", "remove decision fatigue"), marketing/social/strategy notes, personal reminders, pure content/data entry, and anything too underspecified to act on.
   When a candidate is unsuitable, **drop it from the plan and move to the next candidate** until you reach 5 suitable issues or exhaust the batch. Skipped items are left **untouched** in Things (not completed, not noted) so they stay in the queue.
3. **Migrated means done in Things — never live in both places.** Every item that becomes a GitHub issue must be **completed** in Things in the same run (`afterCreate.things.complete: true`). An item must never remain open in Things after its issue exists. Conversely, only items that actually became issues get completed; skipped items stay open.

Before `apply-plan --apply`, confirm `afterCreate.things.complete` is `true` for the route. If it is not, **skip that route and note it in the report** rather than creating issues that would leave items live in both places.

These runs are **fully autonomous — no human in the loop.** "Curated" means the agent judges suitability and rewrites issues; it never means waiting for owner review. Never ask the owner a question, never block on a decision. If a route cannot run cleanly (empty source, `complete` not set, `gh`/Things failure), skip it and record the exact blocker in the report, then continue the other routes.

For a recurring/scheduled run, the standing prompt encoding this policy lives in `automation/scheduled-work-migration-run.md` (alongside the maintainer automation prompt).

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
   - **Stop once the plan holds 5 suitable issues for that repo.** Remove any remaining entries beyond 5 so they are not created this run.
3. `apply-plan --apply` creates the destination issues (≤5 per repo), records state, and post-processes Things — appending the issue link and **completing** each migrated Things task. Skipped entries were removed from the plan, so they are never created and never touched in Things.

Do not use raw `run --apply` for normal migration. It is blocked unless `--allow-raw` is provided, and that override is only for emergency transport tests.

On successful `apply-plan --apply`:

- GitHub issue is created with source provenance in the body.
- State ledger records `source -> destination` in `~/.local/state/work-migrate/state.json`.
- Notion items are not changed by default. This keeps one-time batch migration auditable and reversible from the ledger.
- Things items are post-processed according to config. The private inbox routes append the GitHub issue link and complete the Things task, clearing it from the inbox/project.

The state ledger is the dedupe authority. If an item already exists in the ledger, reruns skip it even if the source remains visible in Notion or Things.

## Delegation (parallel curate, serial apply)

For a multi-route run (e.g. the scheduled `things-inbox` sweep), the root session is a light control plane — it delegates the heavy per-project judgment, then applies centrally. This is autonomous; the root never hands a decision back to a human.

1. **Build the work list.** Root reads the in-scope routes from config (`list-pipelines` / the `things-inbox` group).
2. **Fan out one worker per route, in parallel.** Each worker handles its route only: run `prepare <pipeline> --out <plan>`, curate per the Run Policy (judge suitability, rewrite ≤5 suitable, drop the rest), and return/save the validated plan JSON. **Workers do not call `apply-plan` and do not mutate GitHub or Things** — curation is read-only.
3. **Root applies the plans serially** — `apply-plan <plan> --apply`, one route at a time. Serial apply is **mandatory**: the state ledger (`state.json`) and the Things app are single shared resources, and concurrent `apply-plan` runs race — losing ledger entries (→ duplicate issues on the next run) or dropping Things completions. gh-issue-create + things-complete are fast, so serial apply across all routes is still quick.
4. **Root reports** per route: created count, skipped count, issue URLs, and any route skipped with its blocker.

Backend mapping (same logic either way):

| Concept | Codex | Claude Code |
| --- | --- | --- |
| Spawn a curate worker | New thread `<Project>: prepare+curate` | `Agent` tool with the worker brief below (`run_in_background: true`) |
| Continue a worker | Reuse the same thread | `SendMessage` to the same agent |
| Apply | Root runs `apply-plan --apply` serially | Root runs `apply-plan --apply` serially |

Workers do not subdelegate and do not apply. The worker brief is self-contained (a subagent does not have this SKILL.md in context):

> Curate one work-migration route into a GitHub issue plan. **Do not create issues or touch GitHub/Things — output only.**
> 1. Run `~/Developer/agent-scripts/bin/work-migrate prepare <PIPELINE> --out <PLAN_PATH>`.
> 2. For each candidate, judge suitability: keep concrete actionable work (bug, well-scoped feature, refactor, tech-debt, infra) and focused research/decision questions with a clear deliverable (label those `research`); skip vague musings, marketing/social/strategy, personal reminders, pure content/data entry, and underspecified items. Remove skipped entries from the plan JSON so they stay untouched in Things.
> 3. Rewrite each kept entry into a real issue (concise title, useful body, labels). Stop at **5** kept issues for this repo; remove the rest.
> 4. Save the plan to `<PLAN_PATH>` and report: pipeline, kept count, skipped count, plan path. Make no other changes. Ask nobody anything.

## Config

The config lives with the skill, in the repo:

```text
skills/work-migration/config/config.json
```

`work-migrate` reads it automatically (the script resolves it relative to its
own location), so no `--config` flag, symlink, or `~/.config` path is needed.
It is just the routing table: each pipeline maps a Things project/area (or a
Notion query) to a destination repo, plus labels and `afterCreate` behavior.

`work-migrate.example.json` in the same dir is the sanitized template/reference.

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
