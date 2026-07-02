---
summary: Local private work-migration system for moving Notion and Things items into GitHub Issues.
read_when:
  - Migrating private tasks from Things or Notion into GitHub Issues.
  - Setting up scheduled task inbox processing from Things.
  - Mapping Things projects to private GitHub repositories.
---

# Work Migration

`work-migrate` is a local, idempotent migration command for moving private planning items into GitHub Issues.

It currently supports:

- Sources: Things projects/areas/tags/queries, Notion data sources
- Destination: GitHub Issues
- Safety: dry-run by default, agent-curated issue plans, JSON state ledger, source provenance in every created ticket

Azure DevOps and Jira are intentionally out of scope for this private flow. Keep those in a separate work pipeline later.

## Setup

Copy the example config and edit IDs/project mappings:

```bash
mkdir -p ~/.config/work-migrate
cp ~/Developer/agent-scripts/skills/work-migration/config/work-migrate.example.json ~/.config/work-migrate/config.json
chmod 600 ~/.config/work-migrate/config.json
```

The example includes the real Notion Tasks data source and starter Things project-to-repo mappings discovered from this machine. Edit the mappings before running with `--apply`.

Keep credentials out of the config:

- Notion: `~/.config/notion/api_key` or `NOTION_API_KEY`
- GitHub: `gh auth login`

## Run

List configured pipelines:

```bash
~/Developer/agent-scripts/bin/work-migrate list-pipelines
~/Developer/agent-scripts/bin/work-migrate validate-config
```

Preview a pipeline:

```bash
~/Developer/agent-scripts/bin/work-migrate run things-to-github --limit 10
```

Prepare an issue plan:

```bash
~/Developer/agent-scripts/bin/work-migrate prepare things-mejla-to-github --limit 10 --out /tmp/mejla-issue-plan.json
```

Then have the LLM/orchestrator rewrite `/tmp/mejla-issue-plan.json`:

- `issue.title`: concise GitHub issue title, not the raw Things/Notion dump.
- `issue.body`: useful issue description with context, desired outcome, acceptance criteria, and implementation notes when useful.
- `issue.labels`, `issue.assignees`, `issue.milestone`: adjusted for the destination repo.
- `source`, `sourceKey`, and `afterCreate`: left unchanged.

Preview and apply the curated plan:

```bash
~/Developer/agent-scripts/bin/work-migrate apply-plan /tmp/mejla-issue-plan.json
~/Developer/agent-scripts/bin/work-migrate apply-plan /tmp/mejla-issue-plan.json --apply
```

Raw `run --apply` and `run-all --apply` are blocked unless `--allow-raw` is supplied. That override is only for transport testing; normal migration should always go through a reviewed issue plan.

The state ledger defaults to `~/.local/state/work-migrate/state.json`. If a source item is already in the ledger, future runs skip it.

## Source Handling

Dry runs do not mutate anything.

After a successful `apply-plan --apply`:

- GitHub gets a new issue using the curated issue title/body/labels from the plan.
- The state ledger records the source item and destination issue.
- Notion source items are left unchanged by default. This makes batch migration auditable and avoids rewriting historical planning data.
- Things source items are post-processed by config. The private scheduled routes append the GitHub issue link to the Things notes and complete the Things task, which clears it from the project/inbox.

The state ledger, not source mutation, is the dedupe authority.

## Recommended System

Use Notion as a one-time migration source. Configure one pipeline per Notion data source or filtered view, run it once in dry-run mode, inspect the output, then run with `--apply`. For GainsLog, the starter pipeline is `notion-gainslog-to-github`, filtered to `Tags contains GainsLog` and `Status != Done`.

Use Things as the recurring inbox. Create one Things project per route and map that project to a GitHub repo, for example:

- `GainsLog Web 👨🏼‍💻` -> `ossianhempel/gainslog-web`
- `Android Payments` -> `ossianhempel/gainslog`
- `AgentWispr 🎙️` -> `ossianhempel/agent-wispr`
- `Mejla 📧` -> `ossianhempel/mejla`

Then schedule a Codex/agent task that runs `prepare`, rewrites the issue plan, and runs `apply-plan --apply`. Do not schedule raw `run-all --apply`; that would skip the issue-shaping step that makes the GitHub backlog usable. The command only migrates items that are not already in the state ledger.

Things tasks with a start/assigned date or a due/deadline date are excluded before issue plans are written. Scheduled Things work should stay in Things; this recurring inbox only migrates unscheduled backlog items.

## Launchd Schedule

Create `~/Library/LaunchAgents/com.ossian.work-migrate.dev-inbox.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.ossian.work-migrate.things-inbox</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Users/ossianhempel/Developer/agent-scripts/bin/work-migrate</string>
    <string>prepare</string>
    <string>things-mejla-to-github</string>
    <string>--out</string>
    <string>/Users/ossianhempel/.local/state/work-migrate/mejla-plan.json</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>9</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>/Users/ossianhempel/Library/Logs/work-migrate-things-inbox.log</string>
  <key>StandardErrorPath</key>
  <string>/Users/ossianhempel/Library/Logs/work-migrate-things-inbox.err.log</string>
</dict>
</plist>
```

This LaunchAgent only prepares raw source data. A Codex/agent automation should consume the plan, rewrite the issue fields, and call `apply-plan --apply`.

Load it:

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ossian.work-migrate.things-inbox.plist
launchctl kickstart gui/$(id -u)/com.ossian.work-migrate.things-inbox
```

## Notes

- Keep Things source projects small and intentional. This is an execution handoff, not a full task sync.
- Prefer one-way migration. Bidirectional sync between personal task managers and issue trackers creates conflict handling and status semantics that are usually not worth the complexity.
- Do not route work DevOps/Jira/H&M through this config. Treat that as a separate system with separate credentials, schedules, and state.
