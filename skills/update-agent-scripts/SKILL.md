---
name: update-agent-scripts
description: >
  Sync this repo's skills and slash commands into local/global agent settings
  (Codex, Claude, Gemini, Cursor, Copilot). Use when asked to update or sync
  agent-scripts on the current machine.
---

# Update Agent Scripts

When asked to update or sync agent-scripts:

1. Run `scripts/sync-agent-scripts.sh --dry-run` (from any directory).
2. Ask for confirmation before running the real sync.
3. If the user wants specific providers, pass `--providers`.
4. Cursor defaults to global (`~/.cursor/commands`) targets.
5. Copilot prompts are opt-in: require `--copilot-scope` plus an explicit path
   for workspace or user prompts, and skills are opt-in via `--copilot-skills-dir`.
6. If custom paths are needed, ask for `CURSOR_COMMANDS_DIR`,
   `COPILOT_PROMPTS_DIR`, `COPILOT_USER_PROMPTS_DIR`, or `COPILOT_SKILLS_DIR`
   and re-run.
7. Summarize what was updated and any providers skipped.
