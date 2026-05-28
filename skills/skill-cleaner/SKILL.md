---
name: skill-cleaner
description: "Audit skills across supported agents: loaded roots, duplicate skills, unused skills, prompt-budget costs, compact descriptions."
---

# Skill Cleaner

Use this when trimming skill prompt budget, finding duplicate skills, auditing enabled/disabled skill roots, or deciding which skills/plugins to remove.

## Scanned Roots

Scans the repo source of truth and every supported-agent skill root (see `docs/supported-agents.md`):

- **Repo source:** `~/Developer/agent-scripts/skills` (or `~/repos/...`), plus `profiles/<name>/skills` and `profiles/_shared/skills`.
- **Agent installs:** `~/.claude/skills` (Claude Code), `~/.agents/skills` (Codex/Gemini/Cursor/Copilot/Windsurf), `~/.gemini/antigravity-cli/skills` (Antigravity), `~/.codex/skills`, `~/.codex/plugins/cache`.
- **Project installs:** `<project>/.agents/skills` under each workspace dir.

Skills the sync script fans out as byte-identical copies are collapsed into one logical skill, always keeping the repo source — so managed fan-out is never flagged as a duplicate to delete. Genuine drift (same name, different body) and project-only skills still surface.

## Workflow

1. Run the analyzer from this skill directory or repo root:

```bash
node --experimental-strip-types skills/skill-cleaner/scripts/skill-cleaner.ts --months 3
```

Useful variants:

```bash
node --experimental-strip-types skills/skill-cleaner/scripts/skill-cleaner.ts --no-logs
node --experimental-strip-types skills/skill-cleaner/scripts/skill-cleaner.ts --months 6 --max-log-mb 800 --deep-logs
node --experimental-strip-types skills/skill-cleaner/scripts/skill-cleaner.ts --context-tokens 272000 --budget-percent 2 --no-logs
node --experimental-strip-types skills/skill-cleaner/scripts/skill-cleaner.ts --root ~/Dropbox/boxd/skills --no-logs
```

2. Read the report in this order:
- `Skill Budget`: GPT-5.5 context size, 2% skills budget, Codex-budgeted usage, and pre-budget full-list pressure.
- `Description candidates`: long descriptions where relaxed grammar saves prompt budget.
- `Duplicates`: same skill name or near-identical description/body across Codex, plugin cache, repo siblings, and personal skill roots.
- `Unused candidates`: no recent `$skill` mention, `SKILL.md` read, or explicit skill-use trace in recent Codex/OpenClaw logs.
- `Root summary`: where skills came from and whether config marks them disabled.

3. Before deleting or editing:
- Verify the kept copy exists and is loaded.
- Prefer deleting repo-local or `agent-scripts` duplicates when Codex built-ins cover them.
- Keep repo-local OpenClaw maintainer skills when they encode repo policy or live operations.
- Preserve trigger nouns in descriptions: product, tool, action, object.

## Analyzer Notes

- The script mirrors Codex's model-visible line shape: `- name: description (file: path)`.
- It applies Codex-like frontmatter rules: YAML frontmatter only, default name from parent dir, single-line sanitized `name` and `description`.
- It follows Codex `core-skills/src/render.rs`: 2% of raw `context_window`, token cost `ceil(utf8_bytes / 4)`, then full descriptions -> equal description truncation -> omitted minimum lines.
- It reads `~/.codex/models_cache.json` for GPT-5.5 `context_window`; fallback is 272,000 tokens and 2%.
- It scans the supported-agent skill roots above by default (see Scanned Roots). Extra folders such as Dropbox archives are included only with `--root <path>`.
- It realpath-dedupes roots and collapses byte-identical sync fan-out, so symlinked roots and managed copies do not create false duplicates.
- For duplicate names, it reports description/body similarity and suggests deletion candidates only when bodies are near copies. Keep priority: Codex system skills, then the agent-scripts repo source (skills/ and profiles/), then plugin skills, then fanned-out agent copies.
- Usage evidence comes from `~/.codex/history.jsonl`, recent `~/.codex/sessions/**/*.jsonl`, and `~/.claude/projects/**/*.jsonl` (Claude Code + Codex are the only transcript-capable supported agents). Add `--deep-logs` for archived sessions and OpenClaw/Clawd folders.
- Usage evidence is heuristic: `$skill`, `Use $skill`, and paths like `skills/<name>/SKILL.md`.

## Output Policy

- Suggest first; edit only when the user asks.
- If asked to apply cleanup, make small grouped commits: descriptions, deletes, config disables.
- Do not delete ignored/untracked skill dirs without naming the destination or confirming they are disposable.
