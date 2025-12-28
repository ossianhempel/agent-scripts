# Syncing Agent Scripts

Use `scripts/sync-agent-scripts.sh` to copy the skills and slash commands in this
repo into each agent runtime’s standard locations.

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
/path/to/agent-scripts/scripts/sync-agent-scripts.sh --providers codex,claude
```

## Default destinations

Global (user) locations:
- Codex: `~/.codex/skills` and `~/.codex/prompts`
- Claude Code: `~/.claude/skills` and `~/.claude/commands`
- Gemini CLI: `~/.gemini/commands` (slash commands are converted to `.toml`)

Cursor locations:
- Global skills: `~/.cursor/skills`
- Global commands: `~/.cursor/commands`
- Project skills (optional): `./.cursor/skills`
- Project commands (optional): `./.cursor/commands`

Copilot locations:
- Workspace skills: `./.github/skills`
- Workspace prompts: `./.github/prompts`
- User prompts: stored in the current VS Code profile folder (path varies)

## Overrides

- `--codex-home`, `--claude-home`, `--gemini-home`
- `--claude-skills-dir`
- `--cursor-commands-dir`, `--cursor-skills-dir`, `--cursor-scope`
- `--copilot-skills-dir`, `--copilot-prompts-dir`, `--copilot-user-prompts-dir`, `--copilot-scope`
- Or set `CODEX_HOME`, `CLAUDE_HOME`, `GEMINI_HOME`, `CURSOR_COMMANDS_DIR`,
  `COPILOT_PROMPTS_DIR`, `COPILOT_USER_PROMPTS_DIR`, `CURSOR_SCOPE`,
  `COPILOT_SCOPE`

## Notes

- Cursor supports both project and global skills/commands; the script defaults
  to global-only. Use `--cursor-scope project` or `--cursor-scope both` to
  include project targets.
- Copilot supports workspace and user prompt scopes; the script defaults to
  none and only syncs prompts when you pass `--copilot-scope` and a prompts
  directory.
- Copilot skills are repository-scoped; the script only syncs skills when you
  set `--copilot-skills-dir` or `COPILOT_SKILLS_DIR`.
- Gemini also supports project-local commands in `./.gemini/commands`. If you
  want that, run with `--gemini-home .gemini`.
- `--dry-run` prints every file that would be created or updated.
