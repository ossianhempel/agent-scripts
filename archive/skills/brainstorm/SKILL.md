---
name: brainstorm
description: 'Shape a raw idea into a clear WHAT before planning. Triggers: "I have an idea", brainstorm, explore, unsure what to build, worth building. Writes docs/brainstorms/. Use grill-me for an existing plan.'
---

Take a half-formed idea and shape it into a clear **WHAT** worth building — or a clear "not worth it." This is the fuzzy front-end: you explore the problem, the value, and the boundaries *before* a plan exists. You define **what** to build and **why**; the `plan` skill later defines **how**. You do not write code or design implementation here.

The mode is **diverge then converge**: open the space up (is this real? what's the actual problem? what are the ways to solve it?), then narrow to a recommendation. This is the opposite of `grill-me`, which interrogates an *already-shaped* plan to poke holes in it. Brainstorm works when there's nothing shaped yet.

This skill is free-standing — no other skill or project setup required. It sits at the head of the chain and **loosely couples downstream**: its requirements doc is the upstream WHAT that `grill-me` can stress-test and that `plan` traces to (and feeds `plan`'s optional Specification section when a fuller spec is wanted); it writes vocabulary in the `grill-with-docs` `CONCEPTS.md` format. None need to be present.

## Interaction discipline

- **One question at a time.** Even tightly related sub-questions fire separately — ask, wait, integrate the answer, then ask the next. A wall of questions gets shallow answers.
- **Prefer a recommended answer with each question.** Don't just interrogate — propose where you lean and why, so the user reacts rather than starts from blank.
- **Explore the codebase instead of asking** when a question is answerable from the repo (existing patterns, prior art, constraints).
- **Don't pre-decide implementation.** Schemas, endpoints, class names, file layout — all of that is `plan`'s job. Here you settle mechanism-level trade-offs, not architecture.

## Phase 0 — Is brainstorming even needed?

1. **Fast-path check.** If the idea is already concrete and the scope is clear, say so and route onward (straight to `plan`, or just do it) — don't manufacture ceremony. Brainstorm earns its keep only when the idea is genuinely unformed.

2. **Pick a depth** (infer; confirm only if unclear):
   - **Light** — a small idea or a single open question. Brief dialogue, likely no file, verbal alignment.
   - **Standard** (default) — a real feature-shaped idea. Full rigor probes, approaches, a requirements doc.
   - **Deep** — a big or strategic bet. Add durability and positioning probes, more approaches, sharper scope boundaries.

3. **Scan for constraints.** Read what the repo already says: instruction files (`AGENTS.md`/`CLAUDE.md`), `CONCEPTS.md`, any `STRATEGY.md`/roadmap, and existing patterns or prior art in the area. Brainstorm inside the repo's reality, not in a vacuum.

## Phase 1 — Understand & pressure-test

Run the idea through these probes (open-ended — they surface real observation; don't scaffold them into yes/no). Skip the ones that obviously don't apply for a Light idea; run them all for Deep.

- **Evidence** — "Has this actually happened, or is it hypothetical? Who hit it, and when?" Separates a real itch from an imagined one.
- **Counterfactual** — "What's the workaround today? What happens if we *don't* build this?" If the do-nothing cost is low, that's a finding.
- **Specificity** — push every vague phrase to a concrete instance. "Give me the last time this bit you."
- **Minimal version** — "What's the smallest thing that delivers the core value?" Strips the idea to its load-bearing core and exposes gold-plating.
- **Durability** (Standard/Deep) — "Will this still matter in six months, or is it a passing frustration?"

Integrate each answer before moving on. If a probe reveals the idea isn't worth building, say that plainly — a well-reasoned "don't build this" is a successful brainstorm.

## Phase 2 — Approaches & recommendation

When more than one direction exists, lay out **2–3 concrete approaches** (mechanisms — *how the idea works for the user*, not how it's coded). For each: what it is, pros, cons, risks, when it fits. Then **state a recommendation**, grounded in simplicity and carrying cost — the cheapest thing that delivers the core value usually wins. Let the user confirm or redirect before you write anything.

## Phase 3 — Write the requirements doc

Write the doc **only when the dialogue produced durable decisions worth preserving.** A Light brainstorm that ended in verbal alignment may need no file — say so and stop.

When it's warranted, write to:

```
docs/brainstorms/<YYYY-MM-DD>-<topic-slug>-requirements.md
```

Create the dir lazily. If a brainstorm on the same topic exists, **edit it** rather than spawn a near-duplicate. If new domain vocabulary got resolved, add it to `CONCEPTS.md` in the `grill-with-docs` format (skip if none did).

Keep it the **WHAT**, not the **HOW** — repo-relative paths if you reference files, and no implementation detail.

```markdown
# <Idea — one line>

> **Brainstorm:** docs/brainstorms/<YYYY-MM-DD>-<topic-slug>-requirements.md
> **Status:** Requirements  ·  **Depth:** <Light|Standard|Deep>

## Problem
The real problem, with the evidence behind it (who, when, how often). Note the counterfactual — what happens today without this.

## Who & when
Who this is for and the trigger/moment it matters.

## Value & success criteria
What good looks like — observable signals that this worked. Not metrics theater; the one or two things that would tell you it mattered.

## Approach
The chosen mechanism, in user terms. Briefly: the alternatives considered and why this one (link back to the trade-offs).

## Scope boundaries
- **In:** the minimal core.
- **Out:** what this explicitly is not, and what's deferred to later.

## Assumptions & open questions
What we're taking on faith, and what's still unresolved (to settle at plan time or with more evidence).

## Dependencies
What this leans on — other work, data, services, decisions.
```

## Phase 4 — Handoff

Tell the user where the doc is (if written) and offer the natural next step: `grill-me` to stress-test the shaped idea, `plan` to turn it into an implementation plan (it traces back to this doc, and can carry a full user-stories + contract spec if you want one), or just bank it for later. Don't start planning or building unless asked.
