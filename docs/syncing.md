---
summary: Guide for syncing skills and commands to agent runtime locations
read_when:
  - Using sync-agent-scripts.sh to deploy skills/commands
  - Setting up agent skills across Codex, Claude Code, Gemini, Cursor, or Copilot
---

# Syncing Agent Scripts

> **Note:** Slash commands (in `slash-commands/`) are deprecated in Codex. Use skills instead. Claude Code still supports slash commands, but skills work everywhere and are the recommended approach.

Use `scripts/sync-agent-scripts.sh` to copy the skills and slash commands in this
repo into each agent runtime's standard locations.

## Architecture

Skills sync to two locations:

- **`~/.agents/skills`** — cross-tool standard read by Codex, Gemini CLI, Cursor,
  Copilot, Windsurf, and others. One copy serves all these tools.
- **`~/.claude/skills`** — Claude Code only (does not yet support `.agents/`).

Commands and prompts sync to each tool's native location since formats differ.

## Quickstart

From the repo you want to receive project-local commands (Cursor/Copilot):

```sh
/path/to/agent-scripts/scripts/sync-agent-scripts.sh
```

Preview changes only:

```sh
/path/to/agent-scripts/scripts/sync-agent-scripts.sh --dry-run
```

Limit providers:

```sh
/path/to/agent-scripts/scripts/sync-agent-scripts.sh --providers agents,claude
```

## Auto-sync via Git hooks (local only)

If you want local auto-sync on pull/checkout/rebase:

```sh
./scripts/install-hooks.sh
```

This installs repo-local hooks (via `core.hooksPath`) that run
`scripts/sync-agent-scripts.sh` when changes are detected under
`skills/`, `slash-commands/`, or `scripts/`.

To remove the hooks:

```sh
git config --unset core.hooksPath
```

## Default destinations

Skills:

- Cross-tool: `~/.agents/skills` (Codex, Gemini, Cursor, Copilot, Windsurf)
- Claude Code: `~/.claude/skills`

Commands/prompts:

- Codex: `~/.codex/prompts`
- Claude Code: `~/.claude/commands`
- Gemini CLI: `~/.gemini/commands` (slash commands converted to `.toml`)
- Cursor: `~/.cursor/commands` (global) or `./.cursor/commands` (project)
- Copilot: `./.github/prompts` (workspace) or VS Code profile folder (user)

## Overrides

- `--agents-home`, `--agents-skills-dir`, `--agents-scope`
- `--claude-home`, `--claude-skills-dir`
- `--codex-home`, `--gemini-home`
- `--cursor-commands-dir`, `--cursor-scope`
- `--copilot-prompts-dir`, `--copilot-user-prompts-dir`, `--copilot-scope`
- Or set env vars: `AGENTS_SCOPE`, `CURSOR_COMMANDS_DIR`, `CURSOR_SCOPE`,
  `COPILOT_PROMPTS_DIR`, `COPILOT_USER_PROMPTS_DIR`, `COPILOT_SCOPE`

## Notes

- The `agents` provider handles skills for all tools except Claude Code, syncing
  once to `~/.agents/skills` instead of separate per-tool directories.
- Use `--agents-scope project` or `--agents-scope both` to also sync skills to
  `./.agents/skills` in the current directory (for project-local skills).
- Cursor commands support both project and global scopes; the script defaults to
  global-only. Use `--cursor-scope project` or `--cursor-scope both`.
- Copilot supports workspace and user prompt scopes; the script defaults to none
  and only syncs prompts when you pass `--copilot-scope` and a prompts directory.
- Gemini also supports project-local commands in `./.gemini/commands`. If you
  want that, run with `--gemini-home .gemini`.
- `--dry-run` prints every file that would be created or updated.
