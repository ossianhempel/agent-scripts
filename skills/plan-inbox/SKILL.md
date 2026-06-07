---
name: plan-inbox
description: Find saved implementation plans and brainstorm requirements docs that still need attention. Use this whenever the user asks about unimplemented plans, unfinished saved plans, stale plan docs, open brainstorms, planning backlog, docs/plans status, docs/brainstorms status, or wants to run a project or global inventory of plan/brainstorm artifacts.
---

# Plan Inbox

Use this skill to surface saved work that might otherwise disappear: unfinished
`docs/plans/` implementation plans and upstream `docs/brainstorms/`
requirements docs that have not become plans yet.

The bundled script does the repetitive scan. Run it first, then interpret the
results for the user.

```bash
node skills/plan-inbox/scripts/plan-inbox.js
```

## Modes

Current project:

```bash
node skills/plan-inbox/scripts/plan-inbox.js
```

Specific project:

```bash
node /path/to/agent-scripts/skills/plan-inbox/scripts/plan-inbox.js --project /path/to/project
```

Global scan across sibling projects under `~/Developer` and `~/repos`:

```bash
node /path/to/agent-scripts/skills/plan-inbox/scripts/plan-inbox.js --global
```

Plans plus brainstorm backlog:

```bash
node skills/plan-inbox/scripts/plan-inbox.js --brainstorms
```

JSON for another script:

```bash
node skills/plan-inbox/scripts/plan-inbox.js --json --brainstorms
```

## What To Report

Default output focuses on plans whose status is not complete. Report:

- project
- status
- date/type from filename when available
- title
- path

If `--brainstorms` is relevant, include brainstorm docs that still have
`Requirements` or `Unknown` status and are not linked from any plan.

## Status Model

Use these plan statuses:

- `Draft` — written but not committed to
- `Ready` — approved / ready to implement
- `In Progress` — actively being implemented
- `Blocked` — waiting on something
- `Completed` — implemented and verified
- `Superseded` — replaced by another plan
- `Abandoned` — intentionally not doing it
- `Unknown` — missing or unrecognized status

Treat only `Completed`, `Superseded`, and `Abandoned` as closed. Everything else
belongs in the plan inbox.

Use these brainstorm statuses:

- `Requirements` — captured, no plan yet
- `Planned` — linked to a plan
- `Superseded` — replaced by another brainstorm or plan
- `Dropped` — intentionally not pursuing
- `Unknown` — missing or unrecognized status

Treat only `Planned`, `Superseded`, and `Dropped` as closed for brainstorms.

## Updating Docs

When implementation finishes, update the plan line:

```markdown
> **Status:** Completed
```

When a brainstorm becomes a plan, update the brainstorm line and add the plan
path near the top:

```markdown
> **Status:** Planned  ·  **Depth:** Standard
> **Plan:** docs/plans/YYYY-MM-DD-001-feature-topic-plan.md
```

Do not mark a plan `Completed` unless the implementation has actually landed
and been verified. If the work was replaced or intentionally dropped, use
`Superseded` or `Abandoned` instead so it leaves the active inbox without
pretending it shipped.
