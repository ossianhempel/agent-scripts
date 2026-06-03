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
| Codex | `exec_command` | a `.../skills/<name>/SKILL.md` path in the command | `skill_md` (one) / `skill_scan` (many) |

A single tool call that touches **many** `SKILL.md` files is a catalog scan (the
agent listing what's available), not real use of each — those are tagged
`skill_scan` and excluded from the report by default.

The hook never blocks or fails the agent: parse/git errors degrade to a partial
event or a silent skip, and it always exits 0. Codex runs it `async`.

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

## Wiring (already installed)

- **Claude Code** — `~/.claude/settings.json`, `hooks.PostToolUse`, matcher
  `Skill`, command `track-skill-usage.py claude`.
- **Codex** — `~/.codex/config.toml`, `[hooks].PostToolUse`, matcher
  `exec_command`, command `track-skill-usage.py codex`, `async`.

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
