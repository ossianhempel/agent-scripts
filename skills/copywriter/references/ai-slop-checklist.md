# AI-Slop Checklist

The single source of truth for what counts as AI-generated writing in copy
output. SKILL.md's "Anti-AI-Writing Rules" section is the philosophy; this file
is the operational rubric. The lint script (`scripts/ai_slop_lint.py`) parses
its machine-readable word lists directly from this file, so edit the lists
**here** and the linter stays in sync automatically.

Two kinds of rules live here:

- **Mechanical** — exact strings the linter catches deterministically. Listed
  in the marked blocks below. Fix every one; there are no false positives worth
  keeping.
- **Judgment** — patterns a human (or a reviewing agent) has to read for. The
  linter can't see these. Read this file before declaring copy done.

Run the linter as the cheap first gate, then read the judgment section yourself:

```bash
python3 skills/copywriter/scripts/ai_slop_lint.py path/to/draft.md
# or pipe a draft straight in:
pbpaste | python3 skills/copywriter/scripts/ai_slop_lint.py -
```

Exit code is non-zero when anything is flagged.

---

## Mechanical rules (the linter enforces these)

### Banned vocabulary

Never use these words. They are the most common AI writing tells. If you reach
for one, find the concrete word that actually says what you mean.

<!-- lint:banned-vocab -->
delve, intricate, tapestry, pivotal, underscore, landscape, foster, testament,
enhance, crucial, vital, significant, profound, steadfast, breathtaking,
captivate, watershed, solidify, multifaceted, nuanced, robust, leverage,
utilize, facilitate, paradigm, synergy, holistic, comprehensive, streamline,
innovative, cutting-edge, game-changing, revolutionary, seamless, intuitive,
best-in-class
<!-- /lint:banned-vocab -->

### Conjunctive filler

Cut these or replace with a real transition.

<!-- lint:filler -->
moreover, furthermore, additionally
<!-- /lint:filler -->

### Banned openers

Don't start a piece, section, or paragraph with these.

<!-- lint:openers -->
welcome to, introducing
<!-- /lint:openers -->

### Em dashes and double hyphens

Never use em dashes (—) in any output. Don't substitute the literal double
hyphen (`--`) either. Restructure with commas, periods, or parentheses, or
split into two sentences. (A normal hyphen inside a compound word like
`best-in-class` or `two-tap` is fine — the linter ignores those.)

### Emoji piling

One emoji per section, max, and only if it earns its place. Two or more emoji on
the same line reads as AI exuberance. The linter flags lines with 2+ emoji.

---

## Judgment rules (read these yourself — the linter can't)

These are the tells that need a reader, not a regex. Check them by hand before
declaring copy done.

### Structural tells

- **Rule of three.** "X, Y, and Z" lists everywhere. Use 2 or 4 — whatever the
  content actually has. One rule-of-three list in a piece is fine; a cadence of
  them is the tell.
- **Negative parallelism.** "It's not about X, it's about Y." Once per piece,
  max.
- **False ranges.** "From X to Y" or "Whether X or Y" used to sound inclusive
  while saying nothing. Be specific instead.
- **Reflexive summaries.** Restating every point at the end. Trust the reader.

### Tone tells

- **Inflated symbolism.** Framing mundane things as epic narratives.
- **Editorializing.** Telling the reader how to feel — "This is exciting,"
  "Interestingly." Present the thing; let them react.
- **Superficial -ing commentary.** Vague gerund phrases that add nothing:
  "Creating a more engaging experience."
- **Promotional tone about the copy itself.** Just write it; don't sell it.

### The read-aloud test

Read the draft out loud. AI slop is smooth, even, and frictionless — every
sentence the same length, every clause balanced. Real copy has uneven rhythm:
a three-word line next to a long one, a fragment, a hard stop. If it sounds
like it was written to be inoffensive, it was. Rewrite for friction.
