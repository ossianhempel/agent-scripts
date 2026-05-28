---
summary: Canonical list of agent runtimes this repo targets — their skill install roots and which keep usable session transcripts.
read_when:
  - Adding a new agent runtime to sync/prune.
  - Making a skill or script "work across all the agents we support".
  - Discovering session logs or scanning skill roots from a tool.
---

# Supported Agents

Canonical list of the agent runtimes this repo targets. The sync (`scripts/sync-agent-scripts.sh`)
and prune (`scripts/skills-audit.py`) scripts fan skills out to these roots, so any
skill that scans skill installs or agent session logs should align with this table.

## Skill install roots

The repo's `skills/` is the single source of truth. Sync copies it (real dirs, not
symlinks) into each runtime's skill root:

| Agent | Skill root | Notes |
|-------|-----------|-------|
| Claude Code | `~/.claude/skills` | Claude Code only |
| Codex | `~/.agents/skills` (also reads `~/.codex/skills`) | cross-tool standard |
| Gemini CLI | `~/.agents/skills` | cross-tool standard |
| Cursor | `~/.agents/skills` | cross-tool standard |
| Copilot CLI | `~/.agents/skills` | cross-tool standard |
| Windsurf | `~/.agents/skills` | cross-tool standard |
| Antigravity CLI | `~/.gemini/antigravity-cli/skills` | separate root |

Repo source of truth: `~/Developer/agent-scripts/skills` (this machine) or
`~/repos/agent-scripts/skills` (varies by machine — see AGENTS.md).

Project-scoped profile installs land in `<project>/.agents/skills` (real dirs) with
`<project>/.claude/skills` symlinks. See the Profiles section in `AGENTS.md`.

## Session / transcript logs

Where each runtime keeps conversation logs, and whether they can produce a usable
agent transcript (assistant decisions + tool summaries, not just user prompts):

| Agent | Log location | Format | Transcript-capable |
|-------|-------------|--------|--------------------|
| Claude Code | `~/.claude/projects/**/*.jsonl` | JSONL, full turns | ✅ yes |
| Codex | `~/.codex/sessions/**/*.jsonl` | JSONL, full turns | ✅ yes |
| Gemini CLI | `~/.gemini/tmp/<hash>/logs.json` | JSON array, **user prompts only** | ❌ no assistant content |
| Antigravity CLI | `~/.gemini/antigravity-cli/conversations/*.pb` | binary protobuf | ❌ not plain text |
| Antigravity CLI | `~/.gemini/antigravity-cli/history.jsonl` | JSONL, prompt display only | ❌ no assistant content |
| Cursor | `~/.cursor/projects/...` | opaque/internal | ❌ |
| Copilot CLI | `~/.copilot/session-store.db` | SQLite | ❌ not plain text |
| Windsurf | n/a | — | ❌ |

**Practical consequence:** the `agent-transcript` and `session-viewer` skills can only
render Claude Code and Codex sessions. The other supported runtimes either log only
user prompts or store conversations in binary/SQLite formats that carry no sanitizable
assistant transcript. When a new runtime gains a plain-text full-turn log, add it here
and wire it into those skills.
