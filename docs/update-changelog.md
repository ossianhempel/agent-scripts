---
summary: 'Checklist for curating CHANGELOG.md from recent commits'
read_when:
  - Updating CHANGELOG.md or drafting release notes.
  - After shipping a noteworthy skill, script, or AGENTS edit in agent-scripts.
---

# Update CHANGELOG.md

Curate user-facing changes in a repo's `CHANGELOG.md` from recent commits. Each repo's changelog has its own flavor — read the existing file first and match its style. The pattern in `agent-scripts` is date-stamped sections (`## YYYY-MM-DD — Title`) with past-tense bullets. App repos may use semver sections (`## 1.4.0`) with an `Unreleased` block.

## Inputs

- The repo to work in (default: current `pwd`).
- Optional baseline: a git ref, tag, or date. If none given, fall back in this order:
  1. Latest tag — `git describe --tags --abbrev=0` (errors if no tags).
  2. Most recent date header already in `CHANGELOG.md` — treat as the baseline date.
  3. Last 50 commits — `git log -n 50` if the file is new.
- The existing `CHANGELOG.md` (read it; preserve its format and tone).

## Steps

### 1. Read the existing changelog and AGENTS
```bash
head -60 CHANGELOG.md       # detect format: date sections vs semver
cat AGENTS.md               # repo-specific tone / what counts as user-facing
```
Match the existing convention. Don't introduce a new format unless asked.

### 2. Collect candidate commits
```bash
git log <baseline>..HEAD --oneline --reverse
# or, when in doubt, browse with diffs:
git log <baseline>..HEAD --stat
```
For each non-trivial commit, peek at the diff (`git show <hash> --stat`) to understand the actual surface change.

### 3. Curate — keep only user-facing changes

Include:
- New skills, removed skills, renamed skills (always — they change what tools an agent has).
- AGENTS.md guidance changes that affect behavior.
- Script behavior changes (sync, prune, audit) that users invoke.
- Bug fixes with observable impact.
- Breaking changes — flag explicitly.

Exclude:
- Internal refactors with no behavior change.
- Typo-only edits, formatting, dependency bumps without user impact.
- Features added then removed in the same window (just drop both).
- Commit-message corrections, README polish.

### 4. Group + order

- Group related commits from the same day into **one section** with a single title.
- Order bullets within a section by impact: **breaking → new skills → updates → fixes → misc.**
- Section ordering in the file is reverse-chronological (newest at top, after the intro).

### 5. Write the new section

Match the file's existing pattern. For `agent-scripts`-style date headers:

```markdown
## 2026-MM-DD — Short Title (5–8 words, names the change)
- Added `<skill-name>` for <one-line purpose>.
- Updated `<skill-name>` to <observable change>.
- Removed `<skill-name>` (replaced by `<new-skill>` / archived / merged into …).
```

For repos using semver / `Unreleased`:
- Ensure an `## Unreleased` section exists at the top; create it if missing.
- Append bullets under it; move them under a versioned heading at release time.

Style rules:
- Past tense, declarative. "Added X." not "This change adds X."
- Backticks around skill names, script names, file paths, env vars.
- No raw commit hashes. PR/issue references as `#NNN` only.
- Concise — one line per bullet ideally, two max.

### 6. Sanity check

- Markdown renders cleanly.
- No duplicate entries.
- Section title summarizes the bundle; bullets give the specifics.
- If a release just shipped, start a fresh `Unreleased` (semver repos only).

## Quick template (agent-scripts flavor)

```markdown
## 2026-MM-DD — Title Here
- Added `<skill>` for <purpose>.
- Updated `<skill>` to <observable change>.
- Removed `<skill>` — replaced by `<new>`.
```

## When NOT to write an entry

- The repo doesn't have a `CHANGELOG.md` and the user didn't ask for one. Don't create unprompted.
- The change is invisible to anyone who isn't reading the code (pure refactor, lint fix).
- You're in the middle of a multi-step change — wait until it lands, write one entry covering the bundle.
