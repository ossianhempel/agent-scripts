# Agent Scripts

Inspired by https://github.com/steipete/agent-scripts

Portable, versioned collection of my personal agent skills and slash commands.
Source of truth on this machine: `~/Developer/agent-scripts`.

## Syncing With Other Repos
- Canonical mirror for shared helpers. When a helper changes elsewhere, copy it
  here and sync back out so files stay byte-identical.
- When someone says """sync agent scripts,""" pull latest changes here, ensure
  downstream repos have the pointer-style `AGENTS.md`, copy helper updates, and
  reconcile differences before moving on.
- Keep helpers dependency-free and portable; avoid project-specific imports or
  config expectations.

## Pointer-Style AGENTS
- Shared agent instructions live only inside this repo: `AGENTS.md`.
- Every consuming repo""'s `AGENTS.md` should be reduced to a single pointer line:
  `READ ~/path/to/agent-scripts/AGENTS.md BEFORE ANYTHING (skip if missing).`
  Place any repo-specific rules **after** that line if truly needed.
- When updating shared instructions, edit `agent-scripts/AGENTS.md`, mirror the
  change into your global agent location (if you keep one), and let downstream
  repos keep the pointer.
- Do not copy shared blocks into other repos; keep the pointer and sync instead.

## Sync Expectations
- This repo is the canonical mirror for guardrail helpers used across projects.
  When a helper changes elsewhere, copy it back here immediately (and vice versa).

## Repository Layout
- `skills/`: skill folders. Each skill lives in its own directory and includes
  a `SKILL.md` entry point plus optional `references/`, `assets/`, or `scripts/`.
- `slash-commands/`: markdown files that define reusable agent commands.
- `scripts/`: utilities for syncing and maintenance.
- `tools/`: standalone CLIs and evaluators used by agents.
- `docs/`: lightweight documentation.

## Getting Started
1. Clone this repo on a new machine.
2. Point your agent/runtime to this repo (or copy/symlink `skills/` and
   `slash-commands/` into whatever location your agent expects).
3. Keep this repo up to date with `git pull` and commit changes as you add or
   refine skills/commands.

## Core Helpers
- `scripts/committer`: safe commit helper that stages only listed paths.
- `scripts/docs-list.ts`: docs indexer enforcing `summary`/`read_when` front matter.
- `scripts/browser-tools.ts`: Chrome DevTools helper (see `tools.md`).
- `scripts/update-clawdbot.sh`: update + rebuild + restart Clawdbot app (macOS).

## Sync to Global Agent Settings
Run `scripts/sync-agent-scripts.sh` to copy/update skills and slash commands into
local/global agent runtimes. See `docs/syncing.md` for details.

Examples:
```sh
./scripts/sync-agent-scripts.sh --dry-run
./scripts/sync-agent-scripts.sh
./scripts/sync-agent-scripts.sh --providers codex,claude
COPILOT_PROMPTS_DIR=~/my-repo/.github/prompts ./scripts/sync-agent-scripts.sh --provider copilot --copilot-scope workspace
COPILOT_SKILLS_DIR=~/my-repo/.github/skills ./scripts/sync-agent-scripts.sh --provider copilot
```

## Sync Agent Instructions to Repos
Use `scripts/sync-agent-instructions.sh` to insert the shared pointer line into
instruction files across repos (preserving local rules below it).
See `docs/instructions-syncing.md` for examples and supported filenames.

By default it only updates files that already exist; use `--create-missing` to
create instruction files.

Examples:
```sh
./scripts/sync-agent-instructions.sh --root ~/Developer --dry-run
./scripts/sync-agent-instructions.sh --root ~/Developer
./scripts/sync-agent-instructions.sh --repo ~/Developer/my-repo --create-missing
```

Pointer target:
- `AGENTS.md` (shared cross-repo instructions)

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

## Provider Instruction Docs
- Codex AGENTS.md: https://developers.openai.com/codex/guides/agents-md
- Claude Code CLAUDE.md: https://www.anthropic.com/news/claude-code
- Cursor AGENTS.md: https://docs.cursor.com/en/context
- Copilot instructions: https://docs.github.com/en/copilot/how-tos/custom-instructions/adding-repository-custom-instructions
- Gemini CLI GEMINI.md: https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini.md

## Tests
- `test/test-sync-agent-scripts.sh`
- `test/test-sync-agent-instructions.sh`
- `test/test-readiness.sh`

## Linting
This repo uses `pre-commit` with Markdown linting via `markdownlint-cli2`.
Run: `pre-commit run --all-files`

## Conventions
- Skills go in `skills/<name>/` and must include `SKILL.md`.
- Slash commands go in `slash-commands/<name>.md`.
- Keep names in kebab-case.
- Keep instructions concise and scoped to the skill/command.
- Avoid unnecessary dependencies; keep helpers portable.
- Prefer small, modular changes over large refactors.
- Preserve existing structure unless there is a clear reason to change it.
- Update `README.md` when you add or remove items.

## Contents
Skills
- `agent-readiness`
- `convex-expo`
- `create-cli`
- `frontend-design`
- `ios-simulator`
- `markdown-converter`
- `notion`
- `oracle`
- `playwright`
- `revenuecat`
- `update-agent-scripts`

Slash commands
- `commit`
- `draft-pr`
- `agent-readiness`
- `update-agent-scripts`

Tools
- `agent-readiness`
- `sync-agent-scripts`
- `sync-agent-instructions`
- `committer`
- `docs-list`
- `browser-tools`
- `oracle`
- `gh`
- `gog`
- `things`

## Contents Maintenance
- Update the lists above when adding or removing items.
