# Agent Scripts - Agent Notes

## Purpose
This repo is a portable library of skills and slash commands that can be reused
across machines. Treat it as the source of truth for agent workflows.

## How to add or change things
- Skills go in `skills/<name>/` and must include `SKILL.md`.
- Slash commands go in `slash-commands/<name>.md`.
- Keep names in kebab-case.
- Keep instructions concise and scoped to the skill/command.
- Update `README.md` when you add or remove items.

## Repository expectations
- Prefer small, modular changes over large refactors.
- Avoid unnecessary dependencies; this repo should stay lightweight.
- Preserve existing structure unless there is a clear reason to change it.
