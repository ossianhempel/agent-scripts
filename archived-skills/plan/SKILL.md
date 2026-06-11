---
name: plan
description: "Write a durable implementation plan or PRD/spec in docs/plans/. Triggers: plan this, write a plan, PRD, spec, user stories, scope, implementation breakdown, feature/refactor/migration before coding."
---

Turn a request into a durable, repo-relative implementation plan and write it to `docs/plans/`. You define **HOW** to build the work — research the codebase, make the decisions knowable at plan time, and break the work into ordered implementation units. When the work is behavior-heavy or the user wants a spec/PRD, you also pin down **WHAT** it must do — user stories and the behavioral contract — in an optional Specification section above the units. You do **not** write production code, run tests, or implement here. The deliverable is the plan file.

This skill is free-standing — it requires no other skill, agent, or project config and works the same in any repository. It is also **loosely coupled** to upstream companions when they're available: `brainstorm` shapes a raw idea into a requirements doc under `docs/brainstorms/` (the WHAT); `grill-me` / `grill-with-docs` interrogate the design tree to sharpen it; and `grill-with-docs` leaves behind `CONCEPTS.md` and ADRs. The coupling is one-directional and optional: those produce sharpened intent; plan consumes it and traces back to it. Plan never requires any of them to have run.

## Operating principles

- **Repo-relative paths only.** Always `src/api/user.ts`, never `/Users/.../project/src/api/user.ts`. Plans must be portable across machines and checkouts.
- **No code in the plan.** Research, decide, and describe in prose. Do not pre-write imports, signatures, or framework syntax. Exception: a tiny snippet that encodes a *decision* more precisely than prose can (a schema shape, a state-machine transition, a type contract) may be inlined inside the relevant decision — trimmed to the decision, not a working sample.
- **Stable unit IDs.** Implementation units are `U1`, `U2`, … Once assigned, a U-ID is never renumbered — not when reordering, splitting, or deleting. Deleting a unit leaves its number retired (a gap), so existing references stay valid.
- **Test scenarios are mandatory** for any unit that bears behavior. Each names concrete inputs, the action, and the expected outcome. A unit with no observable behavior (pure scaffolding, config, a dependency bump) instead writes `Test expectation: none — <reason>`.
- **Trace to origin.** Every requirement the plan satisfies links back to its source (the issue, the conversation, a PRD/spec). If the source is this conversation, say so.
- **Plan, don't implement.** No edits to source files. The only file you write is the plan.

## Phase 0 — Scope & resume

1. **Resume check.** Look in `docs/plans/` for an existing plan that matches this request (by slug/topic). If one exists and the user wants to continue or deepen it, edit that file in place — do not create a new one, and keep its existing U-IDs stable.

   **Check for an upstream requirements doc.** If `docs/brainstorms/` holds a requirements doc for this topic (the `brainstorm` skill's output), read it — it's the settled WHAT. Build the plan's Problem/Scope and Requirements Traceability from it rather than re-deriving intent.

2. **Classify the work** into one `<type>` for the filename. Pick the dominant one:
   `feature` · `fix` · `refactor` · `infra` · `perf` · `chore` · `spike`.

3. **Pick a depth** (infer from the request; confirm only if ambiguous):
   - **Quick** — small, well-understood change. Light research, fewer units, terse design section.
   - **Standard** (default) — normal feature/refactor. Codebase research, flows, edge cases.
   - **Deep** — large, risky, or cross-cutting. Add explicit design, risks, alternatives, and flow/edge-case analysis.

   **Decide whether to include the Specification section** (the optional product-spec altitude — user stories + behavioral contract, the old PRD layer). Include it when the work is behavior-heavy, the surface is large or user-facing, or the user explicitly asks for a PRD / spec / user stories. Skip it for a straightforward refactor/fix where the units alone tell the whole story — most plans don't need it.

4. **Surface scope decisions before researching.** If the boundary is unclear (what's in vs. out, which surfaces are affected), state your assumed scope in one or two lines and let the user correct it. Don't stall on this for a Quick plan.

5. **Sharpen the WHAT first if it's fuzzy.** A plan is only as good as the intent behind it. If the idea itself is unformed — it's a hunch, not a decided thing — suggest `brainstorm` to shape it before planning. If the idea is shaped but the design tree has unresolved branches (competing approaches, undefined terms, unclear boundaries), suggest `grill-me` / `grill-with-docs` to resolve them. Offer it; don't force it — a clear, settled request goes straight to research.

## Phase 1 — Gather context

1. **Research the codebase.** Find the files, modules, patterns, and conventions this work touches. If the harness offers a read-only search/explore subagent, delegate the fan-out to it and keep the conclusions; otherwise explore directly. Note the existing patterns to follow so the plan fits the repo rather than fighting it.

   **Read the project's domain docs if they exist** (the artifacts `grill-with-docs` maintains): a root `CONCEPTS.md` or per-context `CONCEPTS.md` files mapped by `CONCEPTS-MAP.md`, and any `docs/adr/`. Use that glossary's terms verbatim in the plan, and honor existing ADRs as settled decisions — cite them rather than relitigating. If a plan-time decision contradicts an ADR, surface the conflict instead of silently overriding it.

2. **External research only when it pays.** Reach for the web only when a decision genuinely depends on outside knowledge — an unfamiliar library's API, a protocol detail, a known-good migration path. Skip it for routine work. If you do research externally, capture the sources for the plan's Sources section.

3. **For Standard/Deep:** trace the primary flow end to end and enumerate the edge cases and failure modes the work must handle. These become test scenarios later.

## Phase 2 — Decide & break down

1. **Resolve what's knowable now.** Settle the technical questions that can be answered at plan time (data shape, where logic lives, which seam to test at, naming). Record each as a decision with its rationale. Leave genuinely open questions explicit rather than guessing.

2. **Break the work into implementation units.** Each unit is an independently reviewable, ideally independently shippable step. Order them by dependency. Assign stable `U`-IDs. Each unit gets: goal, dependencies, repo-relative files, approach (prose), test scenarios (or explicit none), and verification.

3. **For Deep plans,** add a High-Level Design section when the architecture is non-obvious — the shape of the solution, the key interfaces/seams, and how the units compose into it.

## Phase 3 — Write the plan

1. **Compute the filename.** Plans live in `docs/plans/` (create it if absent). Name:

   ```
   docs/plans/<YYYY-MM-DD>-<NNN>-<type>-<slug>-plan.md
   ```

   - `<YYYY-MM-DD>` — today's date.
   - `<NNN>` — zero-padded daily sequence, starting `001`. Compute it: list `docs/plans/<today>-*`, take the highest existing `NNN` for today, add one. First plan of the day is `001`.
   - `<slug>` — short kebab-case topic (e.g. `oauth-token-refresh`).

   ```bash
   today=$(date +%F)
   dir=docs/plans
   n=$(ls "$dir"/${today}-*-plan.md 2>/dev/null | sed -E "s#.*/${today}-([0-9]+)-.*#\1#" | sort -n | tail -1)
   printf '%03d\n' $(( 10#${n:-0} + 1 ))   # next NNN
   ```

2. **Write the file** using the template below. Include the optional sections only when they carry weight — an empty "Risks" heading is noise.

## Phase 4 — Handoff

After writing, tell the user the path and offer the natural next steps: start executing `U1`, deepen a section, **stress-test the plan with `grill-me`** before committing to it, open an issue/PR from the plan, or hand it to another agent. Don't start implementing unless asked.

---

## Plan template

```markdown
# <Title — what this builds, in one line>

> **Plan:** docs/plans/<YYYY-MM-DD>-<NNN>-<type>-<slug>-plan.md
> **Status:** Draft
> **Type:** <feature|fix|refactor|infra|perf|chore|spike>  ·  **Depth:** <Quick|Standard|Deep>

## Problem & Scope

What problem this solves and for whom. State the scope boundary explicitly: what is in, and what is deliberately out.

## Requirements Traceability

Where the requirements come from (a `docs/brainstorms/` requirements doc, issue link, PRD path, a grill session, a `CONCEPTS.md`/ADR, or "this conversation"), as a numbered list:

- **R1** — <requirement> — _source_
- **R2** — <requirement> — _source_

If the plan builds on a grilling session or relies on existing ADRs, name them here so the lineage is traceable.

<!-- Specification — include only for behavior-heavy / spec'd work (the optional PRD altitude). Stays implementation-agnostic: contracts and behavior, NO file paths or code. File-level detail lives in Implementation Units below. -->
## Specification

### User Stories

An extensive numbered list. Format: _As a `<actor>`, I want `<capability>`, so that `<benefit>`._ Cover the whole feature, including the unhappy paths.

1. As a …, I want …, so that …
2. …

### Behavioral Contract

The agreed surface, at module/interface altitude — not files. What each module exposes, the shape of the data, API/event contracts, key interactions, schema changes. A snippet is allowed only when it pins a decision more precisely than prose (a type shape, a state transition). Testing principle: tests assert **external behavior**, never implementation detail; name the **seams** to test at (prefer existing, highest seam) — the concrete scenarios get written per unit below.

## Key Technical Decisions

- **D1** — <decision>. _Rationale:_ <why this over the alternative>.
- **D2** — <decision>. _Rationale:_ <…>.

Open questions (if any): things that can't be settled until implementation, named explicitly.

<!-- Deep only, when architecture is non-obvious -->
## High-Level Design

The shape of the solution: key components/seams, how data flows, how the units compose. Prose and diagrams-in-text, no code.

## Implementation Units

### U1 — <goal>

- **Goal:** <the one outcome this unit delivers>
- **Depends on:** <none | U?>
- **Files:** `src/...`, `src/...` (repo-relative)
- **Approach:** <prose: what changes and how, no code>
- **Test scenarios:**
  - Given <input/state>, when <action>, then <expected outcome>.
  - _or_ `Test expectation: none — <reason>`
- **Verification:** <how we confirm this unit is done — a command, a behavior, a check>

### U2 — <goal>

- ... (same shape)

<!-- Include only when material -->
## Risks & Mitigations

- <risk> → <mitigation / fallback>

## Alternatives Considered

- <alternative> — rejected because <reason>.

## Deferred / Out of Scope

- <thing intentionally not done now, and why / when it'd come back>

## Sources

- <link or path> — <what it informed>
```
