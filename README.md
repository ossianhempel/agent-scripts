# Agent Scripts

```
                    _______________________________________________
                   /                                               \
                  /    █████╗  ██████╗ ███████╗███╗   ██╗████████╗ \
                 |    ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝  |
                 |    ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║     |
                 |    ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║     |
                 |    ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║     |
                 |    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝     |
                 |                                                   |
                 |    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗  |
                 |    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝  |
                 |    ███████╗██║     ██████╔╝██║██████╔╝   ██║     |
                 |    ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║     |
                 |    ███████║╚██████╗██║  ██║██║██║        ██║     |
                  \   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝    /
                   \_______________________________________________ /
```

Portable, versioned collection of my personal agent skills and slash commands.

This repo is a single source of truth that I can reuse across machines and plug
into whichever agent runtime I’m using (Codex CLI or others).

## Syncing With Other Repos
- Treat this repo as the canonical mirror for shared agent helpers. When you
  update a skill or command in another repo, copy the change here and then back
  out to every other repo that carries the same helper so they stay identical.
- When someone says “sync agent scripts,” pull latest changes here, ensure
  downstream repos have the pointer-style `AGENTS.md`, copy helper updates into
  place, and reconcile differences before moving on.
- Keep everything dependency-free and portable. Avoid project-specific imports
  or config expectations so the helpers run in isolation across repos.

## Pointer-Style AGENTS
- Shared agent instructions live only inside this repo: `AGENTS.md`.
- Every consuming repo’s `AGENTS.md` should be reduced to a single pointer line:
  `READ ~/path/to/agent-scripts/AGENTS.md BEFORE ANYTHING (skip if missing).`
  Place any repo-specific rules **after** that line if truly needed.
- When updating shared instructions, edit `agent-scripts/AGENTS.md`, mirror the
  change into your global agent location (if you keep one), and let downstream
  repos keep the pointer.

## Goals
- Keep skills and commands modular and easy to copy or symlink
- Version changes so I can sync updates across computers
- Make each skill/command self-contained and discoverable

## Repository Layout
- `skills/`: skill folders. Each skill lives in its own directory and includes
  a `SKILL.md` entry point plus optional `references/`, `assets/`, or `scripts/`.
- `slash-commands/`: markdown files that define reusable agent commands.
- `scripts/`: utilities for syncing and maintenance.
- `docs/`: lightweight documentation.

## Getting Started
1. Clone this repo on a new machine.
2. Point your agent/runtime to this repo (or copy/symlink `skills/` and
   `slash-commands/` into whatever location your agent expects).
3. Keep this repo up to date with `git pull` and commit changes as you add or
   refine skills/commands.

## Sync to Global Agent Settings
Run `scripts/sync-agent-scripts.sh` to copy/update skills and slash commands into
local/global agent runtimes.
See `docs/syncing.md` for examples and provider details.

Defaults:
- Codex: `~/.codex/skills` and `~/.codex/prompts`
- Claude Code: `~/.claude/skills` and `~/.claude/commands`
- Gemini CLI: `~/.gemini/commands` (converted to `.toml`)
- Cursor: `~/.cursor/skills` and `~/.cursor/commands` (global)
- Copilot: prompts and skills are repo-scoped and require explicit paths

Overrides:
- `CODEX_HOME`, `CLAUDE_HOME`, `CLAUDE_SKILLS_DIR`, `GEMINI_HOME`
- `CURSOR_COMMANDS_DIR`, `CURSOR_SKILLS_DIR`, `CURSOR_SCOPE`
- `COPILOT_SKILLS_DIR`, `COPILOT_PROMPTS_DIR`, `COPILOT_USER_PROMPTS_DIR`,
  `COPILOT_SCOPE`

## Provider Slash Command Docs
- Codex CLI: https://developers.openai.com/codex/guides/slash-commands
- Claude Code: https://docs.anthropic.com/en/docs/claude-code/slash-commands
- Cursor: https://docs.cursor.com/en/agent/chat/commands
- Copilot prompt files: https://docs.github.com/en/copilot/tutorials/customization-library/prompt-files
- Gemini CLI custom commands: https://geminicli.com/docs/cli/custom-commands/

## Provider Skill Docs
- Codex skills: https://developers.openai.com/codex/skills
- Claude Code skills: https://docs.claude.com/en/docs/claude-code/skills
- Cursor skills: https://cursor.com/docs/context/skills
- Copilot agent skills: https://docs.github.com/copilot/concepts/agents/about-agent-skills

## Tests
- `scripts/test-sync-agent-scripts.sh`

## Linting
This repo uses `pre-commit` with Markdown linting via `markdownlint-cli2`.

Setup:
1. Install pre-commit.
2. Run `pre-commit install`.

Run manually:
`pre-commit run --all-files`

## Contents
Skills
- `create-cli`
- `frontend-design`
- `oracle`
- `revenuecat`
- `update-agent-scripts`

Slash commands
- `commit`
- `draft-pr`
- `update-agent-scripts`

## Conventions
- Use kebab-case for new skill and command names.
- Put the primary instructions for each skill in `SKILL.md`.
- Update the lists above when adding or removing items.
