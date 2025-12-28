# Update Agent Scripts

You are given the following context:
$ARGUMENTS

## Instructions

Sync this repo's skills and slash commands into the local/global agent settings.

- Run `scripts/sync-agent-scripts.sh` (from any directory).
- If `$ARGUMENTS` lists providers (comma-separated), pass them via `--providers`.
- Cursor defaults to `~/.cursor/commands` (global). Use `--cursor-scope project`
  or `--cursor-scope both` to include project commands.
- Copilot prompts require `--copilot-scope` plus `--copilot-prompts-dir` or
  `--copilot-user-prompts-dir`.
- Copilot skills require `--copilot-skills-dir` (no default).
- If custom paths are needed, set `CURSOR_COMMANDS_DIR` or
  `COPILOT_PROMPTS_DIR` before running.
- Report what updated and any providers skipped.
