---
name: compound
description: Close out a session by capturing what was learned, preventing recurrence, and refreshing stale docs. Answers "what did we learn?", "how do we stop this happening again?", and "are the docs up to date?" — routing each learning to a durable solution doc, an agent instruction rule, or the CONCEPTS.md glossary. Use after solving a problem or finishing a chunk of work, or when the user says "what did we learn", "compound this", "prevent this next time", "did we update the docs". Auto-fits moments like "that worked", "it's fixed", "finally".
---

Turn a just-finished piece of work into compounding knowledge. The mistake you debugged for an hour should cost the next session zero minutes — because the fix is written down, the recurrence is fenced off by a rule, and the docs that went stale got refreshed. You are not implementing anything here; you are harvesting what the session already produced and routing it to where future-you (or the next agent) will actually find it.

Run this when work is **solved and verified**, not mid-flight, and when there's something non-trivial to capture (skip pure typos).

This skill is free-standing — no other skill or project setup is required. It is **loosely coupled** to your toolkit where that helps: it can hand prevention rules to `review-agent-md`, writes glossary entries in the `grill-with-docs` `CONCEPTS.md` format, and complements `plan` (a recurring miss may mean a planning gap). None of those need to be present.

It has one companion: the **learnings-researcher** subagent — the *read* side of the loop. `compound` writes solution docs; the researcher surfaces them again later. It's a registered cross-tool subagent (defined in `agent-scripts/subagents/learnings-researcher.md`, generated into each harness's native agents dir), so invoke it by name where the runtime supports subagents, or do its grep-and-distill inline if it doesn't. It's also valuable **outside** this skill — run it before starting work (or from `plan`) to ask "what has this repo already learned about this?" so you don't re-debug a solved problem.

## The three questions

Every run answers the user's standing trio, and each answer has a home:

1. **What did we learn?** → a durable **solution doc** in `docs/solutions/`.
2. **How do we prevent recurrence?** → a **prevention rule** in the right agent instruction file (`CLAUDE.md` / `AGENTS.md`).
3. **Are the docs current?** → a **freshness sweep** of the docs the session's changes touched, including `CONCEPTS.md` vocabulary.

A given session might feed one, two, or all three. Route by fit — don't force an empty section.

## Phase 0 — Frame the session

Reconstruct, from the conversation and the diff, three things:

- **What changed** — the actual edit/fix/feature that landed (repo-relative files).
- **What problem it solved** — the symptom, the root cause, and what the resolution was. This is the durable knowledge.
- **What cost time or went sideways** — the wrong turn, the wrong assumption, the missing context, the footgun. This is the preventable part.

If the work isn't actually finished or verified, say so and stop — there's nothing solid to compound yet.

## Phase 1 — Extract & classify learnings

Sort what you found into the routes below. A learning can produce more than one artifact.

- **Solved problem / reusable knowledge** → solution doc. "Here's a problem, here's why it happened, here's the fix and why it works."
- **Preventable mistake** (the agent or the process did something wrong that a rule would have caught) → prevention rule. Distinguish:
  - **Repo-specific** ("in this project, migrations must run before X") → the project's instruction file.
  - **Cross-cutting habit** ("always check Y before Z", true everywhere) → the workspace-global instruction file if one exists, else the project file.
- **New domain vocabulary** (a term got coined or sharpened this session) → `CONCEPTS.md`.
- **Docs that no longer match reality** (a README, guide, ADR, or `CONCEPTS.md` entry the change contradicts) → freshness sweep.

## Phase 2 — Write the artifacts

### Solution doc

Write to `docs/solutions/<category>/<slug>.md` (create dirs lazily). Pick a category that fits — e.g. `build-errors/`, `runtime-errors/`, `database/`, `performance/`, `integration/`, `architecture/`, `conventions/`, `tooling/`, `workflow/`. Invent one if none fits; consistency matters more than the exact taxonomy.

**Before writing, check for an existing doc on the same problem.** Invoke the **learnings-researcher** subagent in `overlap-check` mode (greps `docs/solutions/` and returns either a doc to update or "no overlap — create new") — or grep inline if subagents aren't available. If a doc overlaps heavily, **update it** rather than duplicate; if it's adjacent, cross-link.

Use this lightweight, greppable shape:

```markdown
---
title: <one-line problem statement>
date: <YYYY-MM-DD>
category: <category>
tags: [<keyword>, <keyword>]
type: <bug | knowledge>
---

## Problem
<symptom — what was observed, in searchable terms>

## Root cause
<why it happened>

## Solution
<what fixed it — repo-relative files, prose, no need to paste full diffs>

## Why this works
<the mechanism, so the reader can adapt it rather than cargo-cult it>

## Prevention
<the rule / check / signal that catches this earlier next time — and a link to the instruction-file rule if one was added>
```

### Prevention rule

For each preventable mistake, draft the **smallest** rule that would have caught it — one line, imperative, concrete. Then place it:

- Find the substantive instruction file (project `CLAUDE.md`/`AGENTS.md`; for a cross-cutting rule, the workspace-global one if it exists). Prefer **adding one line to an existing relevant section** over creating a new section.
- For rules about how the *agent* should behave (not domain facts), you may delegate to `review-agent-md` if available — it specializes in mining history and editing the instruction file. Otherwise write the line directly.
- **Editing an instruction file changes future agent behavior — get the user's consent before writing**, showing the exact line and where it goes. (One exception: if the user explicitly asked you to "just do it" / run headless, apply it and report what you added.)

### CONCEPTS.md

If a domain term was coined or sharpened, add/refine it in `CONCEPTS.md` using the `grill-with-docs` glossary format (`skills/grill-with-docs/CONCEPTS-FORMAT.md`): tight definition, `_Avoid_:` synonyms, project-specific terms only — no general programming concepts. Create the file lazily only if a qualifying term actually surfaced. In a multi-context repo (`CONCEPTS-MAP.md` present), write to the right context's file.

## Phase 3 — Freshness sweep

The work just changed how something behaves; some prose now lies. Find the docs the change touches — `README`, `docs/`, setup/usage guides, ADRs, `CONCEPTS.md` entries — and reconcile them:

- Small, clearly-stale lines → fix them in place.
- Larger drift (a guide that needs real rework) → flag it with a precise note rather than silently rewriting.
- **Discoverability:** if you created the first `docs/solutions/` entry and the instruction file never mentions that a knowledge store exists, offer to add a one-line pointer so future agents search it. Same consent rule as prevention edits.

## Phase 4 — Report

Summarize tersely what landed and where:

```
Learned:    <one line>
Solution:   docs/solutions/<category>/<slug>.md  (created | updated | none)
Prevention: <instruction file>: "<rule>"  (added | proposed | none)
Concepts:   CONCEPTS.md  (updated <term> | none)
Docs:       <fixed N | flagged: <path> | clean>
```

Then offer the natural follow-ups: open a PR with the doc updates, run `review-agent-md` for a deeper instruction-file pass, or grill a flagged stale doc back into shape. Don't keep coding unless asked.
