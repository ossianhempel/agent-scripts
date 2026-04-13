---
name: update-agent-scripts
description: >
  Sync this repo's skills and slash commands into local/global agent settings.
  Skills go to ~/.agents/skills (cross-tool) and ~/.claude/skills (Claude Code).
  Commands/prompts go to each tool's native location. Use when asked to update
  or sync agent-scripts on the current machine.
---

# Update Agent Scripts

When asked to update or sync agent-scripts:

1. Run `scripts/sync-agent-scripts.sh --dry-run` (from any directory).
2. Ask for confirmation before running the real sync.
3. If the user wants specific providers, pass `--providers`.
4. Cursor defaults to global (`~/.cursor/commands`) targets.
5. Copilot prompts are opt-in: require `--copilot-scope` plus an explicit path
   for workspace or user prompts.
6. Use `--agents-scope both` to also deploy skills to `./.agents/skills` in the
   current project directory.
7. Summarize what was updated and any providers skipped.
