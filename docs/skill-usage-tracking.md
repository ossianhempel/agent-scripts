---
summary: How skill usage is tracked across Claude Code and Codex via PostToolUse hooks, and how to read the report.
read_when:
  - Wanting to know which skills are actually used, per repo or agent.
  - Adding skill tracking to another agent runtime.
  - Debugging why a skill invocation did or didn't get logged.
---

# Skill Usage Tracking

A local, network-free record of which skills get used, by which agent, in which
repo. Built on the `PostToolUse` hook that both Claude Code and Codex support.

## How it works

`hooks/scripts/track-skill-usage.py` is wired as a `PostToolUse` hook in both
runtimes. On each matching tool call it reads the hook payload from stdin,
decides whether a skill was touched, and appends one JSON line per skill to:

```
~/.local/share/agent-skill-usage/events.jsonl
```

(Override with `AGENT_SKILL_USAGE_FILE`. Honors `XDG_DATA_HOME`.)

Detection is agent-aware because the runtimes expose skills differently:

| Agent | Matcher | Signal | `source` |
|-------|---------|--------|----------|
| Claude Code | `Skill` | the `Skill` tool's `input.skill` | `skill_tool` |
| Codex | `Stop` (transcript scan) | `exec_command` / `Bash` reads of `.../skills/<name>/SKILL.md` in the rollout JSONL | `skill_md` (one) / `skill_scan` (many) |
| Codex | `Bash` (`PostToolUse`, optional) | same path pattern in `tool_input.command` when simple Bash hooks fire | `skill_md` / `skill_scan` |

A single tool call that touches **many** `SKILL.md` files is a catalog scan (the
agent listing what's available), not real use of each — those are tagged
`skill_scan` and excluded from the report by default.

The hook never blocks or fails the agent: parse/git errors degrade to a partial
event or a silent skip, and it always exits 0.

**Codex + `unified_exec`:** Codex's `PostToolUse` hooks do not fire for the
`unified_exec` / `exec_command` shell path yet (only simple `Bash`). With
`unified_exec = true` in `~/.codex/config.toml`, live Codex capture relies on a
`Stop` hook that scans the session transcript for `SKILL.md` reads at the end of
each turn. The dashboard also runs a lightweight transcript backfill on refresh.

### Event shape (schema 1)

```json
{"ts":"2026-06-02T21:21:03Z","schema":1,"agent":"codex","skill":"release-flow",
 "source":"skill_md","repo":"gainslog","repo_path":"/Users/.../gainslog",
 "cwd":"/Users/.../gainslog","session_id":"...","tool":"exec_command"}
```

## Reading the report

```bash
bin/skill-usage                  # last 7 days, all agents/repos, by skill
bin/skill-usage --since 30d      # window: Nd / Nh / Nw / all
bin/skill-usage --agent codex    # one agent
bin/skill-usage --repo gainslog  # one repo
bin/skill-usage --by repo        # group by repo (or: agent)
bin/skill-usage --include-scans  # count catalog scans too
bin/skill-usage --include-authoring   # count loads inside agent-scripts too
bin/skill-usage --json           # machine-readable aggregate
```

By default the report **excludes** two kinds of noise:
- `skill_scan` events (catalog listings).
- Loads inside the `agent-scripts` repo — that's almost always *authoring* a
  skill, not using one.

## Visual dashboard (local-only)

Double-click **`Skill Dashboard.command`** at the repo root (or run
`bin/skill-dashboard`). It starts a tiny localhost server
(`scripts/skill-dashboard-server.py`) that reads the event log live and opens a
single-page dashboard (`dashboard/index.html`) in your browser: KPI cards, top
skills (stacked per agent), per-repo bars, an activity-over-time sparkline, and a
recent-invocations table. Filters for window (7/30/90/all), agent, and the
scans/authoring toggles work instantly client-side.

It is **deliberately local-only** — binds to `127.0.0.1`, reads
`~/.local/share` only, commits and sends nothing. That's why it's not on GitHub
Pages: the event log carries repo/client names and local paths, and
`agent-scripts` is a public repo. The dashboard has a **Refresh** button and a
20s auto-refresh; both just re-read the file, so no terminal commands are needed
while it's open. Close the window (or Ctrl-C) to stop the server.

## Wiring (already installed)

- **Claude Code** — `~/.claude/settings.json`, `hooks.PostToolUse`, matcher
  `Skill`, command `track-skill-usage.py claude`.
- **Codex** — `~/.codex/hooks.json`:
  - `Stop` → `track-skill-usage.py codex-transcript` (primary with `unified_exec`)
  - `PostToolUse` matcher `Bash` → `track-skill-usage.py codex` (when simple Bash hooks fire)
- Reinstall with `hooks/scripts/install-skill-usage-hooks.py` or
  `scripts/sync-agent-scripts.sh --provider codex`.

Both reference the script by absolute path, so no skill sync is involved.

## Caveats / limits

- **Hook-based tracking only reaches Claude + Codex.** Per
  [supported-agents.md](supported-agents.md), the other runtimes don't expose a
  comparable `PostToolUse` hook. To add one later, give it a new `agent` label
  and an appropriate matcher/signal; the schema is versioned.
- **Codex hook trust.** Codex requires a trusted sha256 for hook commands. The
  first launch after install (or after the script changes) will prompt to trust
  it — approve once. Until then the Codex hook won't run.
- **Config changes need a fresh session.** Each runtime loads hook config at
  startup, so the first captures land on the next new Claude/Codex session.
- **Codex captures real skill *loads*, not a discrete "invoke".** Codex has no
  skill tool; it loads a skill by reading its `SKILL.md`. If a skill is used
  without re-reading the file, that reuse isn't separately counted.
- **Historical Codex catch-up:** `bin/skill-usage-backfill` scans recent Codex
  rollout JSONL files and appends any missing events (default last 30 days).
