---
summary: The subagents primitive — one canonical agent definition in subagents/, generated into each harness's native format (Claude .md, Codex .toml; more to come).
read_when:
  - Adding or editing a cross-tool subagent.
  - Extending the generator to a new harness (Copilot, Gemini, Cursor).
  - Debugging why a subagent didn't install or got pruned.
---

# Subagents

A **subagent** is a named, specialized agent a harness can delegate to — its own system prompt, scoped tools, isolated context. Every major harness now supports them, but **the formats differ** (Markdown+YAML vs TOML; prompt in the body vs in a field), and there is **no portable standard** (AGENTS.md is instructions-only). So unlike skills — which are byte-identical everywhere and sync by plain copy — subagents need a **generator**: one canonical source, transformed per target.

## Source of truth

Canonical definitions live in **`subagents/<name>.md`** (global). The format is Claude-Code-flavoured — YAML frontmatter + Markdown body-as-system-prompt — because it's the richest shape and the de-facto lingua franca (Cursor reads it natively).

```yaml
---
name: learnings-researcher          # slug; the invocation name
description: <when a harness should delegate to this agent>
access: read-only                   # read-only | edit | full   (see below)
model: inherit                      # inherit | <model-id>
---

<the system prompt — the agent's instructions>
```

Two axes don't port literally and are **abstracted** so the canonical file stays clean:

- **`access`** — harnesses model permissions differently (Claude named-tool allowlist, Codex `sandbox_mode`, Cursor a `readonly` bool). The generator expands one `access` enum into each tool's model:

  | `access` | Claude `tools` | Codex `sandbox_mode` |
  |----------|----------------|----------------------|
  | `read-only` | `Read, Grep, Glob` | `read-only` |
  | `edit` | (omitted — inherit all) | `workspace-write` |
  | `full` | (omitted — inherit all) | `danger-full-access` |

- **`model`** — `inherit` maps to Claude's `inherit` and is omitted for Codex (which then inherits the session model). An explicit id passes through (note: model *names* are tool-specific and don't cross ecosystems).

Default `access` is `edit` if omitted.

## Generation & sync

`scripts/gen-subagents.py` reads `subagents/*.md` and writes each harness's native file:

| Target | Output | Transform |
|--------|--------|-----------|
| Claude Code | `~/.claude/agents/<name>.md` | near-verbatim (+ `access`→`tools`) |
| Codex | `~/.codex/agents/<name>.toml` | TOML; body → `developer_instructions`, `access`→`sandbox_mode` |

It runs as the **`subagents`** provider inside `scripts/sync-agent-scripts.sh` (part of the default run, so the SessionStart and pre-push syncs regenerate automatically). Run it alone with:

```bash
scripts/sync-agent-scripts.sh --provider subagents      # or:
scripts/gen-subagents.py [--dry-run]
```

## Pruning is manifest-based

The generator writes a `.agent-scripts-manifest` in each target dir listing the files it created. On each run it removes previously-generated files that are no longer in `subagents/`, and **never touches files it didn't write** — hand-authored agents in `~/.claude/agents/` are safe. (This is separate from `skills-audit.py`, which prunes skills, not subagents.)

## Status & roadmap

- **v1 targets:** Claude Code, Codex.
- **Planned:** Copilot (`~/.copilot/agents/<name>.agent.md` — body moves into a `prompt:` frontmatter field), Gemini CLI (`~/.gemini/agents/` — near-verbatim `.md`), Cursor (`~/.cursor/agents/` — near-verbatim; also reads `.claude/agents/` natively).
- **Antigravity:** no file-based subagent format (runtime `define_subagent` / SDK only) — intentionally skipped.

## Known tradeoff

Permission fidelity degrades on tools with coarse models: a granular allowlist collapses to Cursor's `readonly` bool and Codex's sandbox tiers. Everything else round-trips cleanly. Keep canonical agents expressed via `access` rather than tool-name lists so the mapping stays lossless where it can.

## Subagents vs. skill-internal `agents/`

Some skills bundle prompt files under `skills/<skill>/agents/*.md` (e.g. `skill-creator`). Those are **inline-dispatch helpers** read by their parent skill — not registered subagents, not synced by the generator. The generator only reads the top-level `subagents/` (and, later, profile `agents/`). Promote a skill-internal helper to a real subagent by moving it into `subagents/` with proper frontmatter — as was done for `learnings-researcher`.
