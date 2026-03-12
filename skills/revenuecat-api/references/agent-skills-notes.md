# Agent Skills notes

This skill follows the open Agent Skills layout:

- `SKILL.md` is required.
- `scripts/`, `references/`, and `assets/` are optional supporting directories.
- The skill name must match the directory name and use lowercase letters, numbers, and hyphens only.

## Why the files are arranged this way

- `SKILL.md` stays short and action-oriented so agents can load it quickly.
- `references/` stores longer material that agents can read only when needed.
- `scripts/` contains deterministic helpers for direct execution.
- `agents/openai.yaml` adds Codex-specific UI metadata and declares the RevenueCat MCP dependency.

## Installation targets

### Claude Code
Common locations:
- personal: `~/.claude/skills/revenuecat-api/`
- project: `.claude/skills/revenuecat-api/`

### OpenAI Codex
Common locations:
- user: `$HOME/.agents/skills/revenuecat-api/`
- repo: `.agents/skills/revenuecat-api/`

## Design choices in this skill

- Uses only open-skill frontmatter fields in `SKILL.md` for portability.
- Places Codex-specific policy in `agents/openai.yaml`.
- Avoids hard-coding tool approvals so the skill remains portable across agents.
- Treats RevenueCat MCP as the preferred path and raw HTTP as the fallback path.
