---
name: "github-project-triage"
description: "GitHub issue/PR triage: queues, CI, blockers, risk, proof, next actions."
---

# GitHub Project Triage

Always use this skill when the user types `triage`, unless the request explicitly targets a non-GitHub domain. From inside a repo, use the current GitHub project by default. Triage means maintainer-facing item cards: URL, what each issue/PR is about, why it matters, author trust, fit, risk, proof/test state, blockers, and next action. Never return only queue numbers or opaque refs.

Output is URL-first: every surfaced issue/PR/repo item must include its GitHub URL in the first line or first sentence for that item. If giving a shortlist, print one URL per item.

Use **RepoBar** as the default discovery and queue-map path for triage, not merely a future or broad-scan backup. RepoBar is faster and more profile-aware than hand-rolling `gh repo list`/`gh search` loops: it understands repo activity, issue/PR counts, CI, releases, local checkouts, auth, cache, pinned scope, and filters in one tool, and it works for **private repos** (it shares the GitHub auth/cache of the RepoBar app). Drop to `gh` only for maintainer-grade item detail, cross-checks, and mutations: full issue/PR bodies and comments, diffs, review decisions, unresolved review threads, exact mergeability, workflow logs, reruns, comments, PR edits, closes, and merges. If RepoBar is unavailable or cannot answer the requested scope, report that and use `gh` only as the explicit fallback.

## Setup

Requires `gh` (authenticated), `jq`, and **RepoBar** (preferred). Confirm identity once:

```bash
gh auth status
gh api user --jq .login   # expected: ossianhempel
```

RepoBar ships a CLI inside its app bundle. Prefer a `repobar` on PATH; otherwise call the bundled binary directly:

```bash
repobar_cmd() {
  if command -v repobar >/dev/null 2>&1; then
    repobar "$@"
  elif [ -x "/Applications/RepoBar.app/Contents/MacOS/repobarcli" ]; then
    "/Applications/RepoBar.app/Contents/MacOS/repobarcli" "$@"
  else
    printf 'RepoBar not installed. Run: brew install --cask repobar && repobar import-gh-token\n' >&2
    return 127
  fi
}

repobar_cmd status   # expect: Logged in as github.com#ossianhempel
```

RepoBar auth reuses your `gh` token via `repobar import-gh-token` (re-run after any `gh auth login`/token change). A `repobar` symlink is installed at `~/.local/bin/repobar` → the app's bundled `repobarcli`; it survives Sparkle app updates. If `repobar status` shows `Logged out`, run `repobar import-gh-token`.

Default owner for broad triage: `ossianhempel` (all your repos; no orgs by default). Only broaden to other owners/orgs when the user names them, or when the current repo already lives under that owner.

## Integration Branch Gate

Before starting work inside any local project, determine the repository's
development integration branch. Do **not** assume GitHub's default branch is the
correct PR base: several repos keep `main` as production while normal
development targets `develop`.

Determine the base branch in this order:

1. Repo instructions (`AGENTS.md`, `CLAUDE.md`, release docs, CI docs) that name
   a branch flow, for example "feature branches -> develop -> main".
2. Existing active local checkout when it is already clean and on a documented
   development branch.
3. GitHub default branch only when no repo instructions or local convention say
   otherwise.

Common examples:

- GainsLog: feature branches target `develop`; `main` is production.
- PlateSnap: TestFlight/development work targets `develop`; App Store/production
  releases target `main`.

Then verify the checkout is already on that base branch and clean before any
pull:

```bash
git status --short --branch
git branch --show-current
```

Proceed only when the branch is the selected integration branch and
`git status --short` shows no changes. If the branch is wrong or the worktree is
dirty, stop and ask Ossian what to do unless the task explicitly authorizes an
isolated worktree/clone. In isolated work, create the worktree from the selected
integration branch, not blindly from `main`.

Only after those checks pass, update that selected branch:

```bash
git pull --ff-only
git status --short --branch
```

If the pull fails or leaves changes, stop and report the blocker.

Open PRs against the same selected integration branch. Before reporting a PR as
ready, verify `baseRefName` matches that branch; retarget or report the mismatch
instead of leaving a development PR aimed at production `main`.

## Scope Rule

If the user says `triage` and the current working directory is a Git repo with a GitHub remote, triage only that project. Do not broaden to all of Ossian's queues unless the user says `broad`, `all`, `everything`, names multiple owners/orgs, or asks for cross-repo triage.

If the repo has `VISION.md`, read it before judging what can be handled autonomously. Use it as the product-fit source of truth, then apply this skill's risk/testability rules. If no `VISION.md` exists, use the autonomous-fit rules below.

Find the current project:

```bash
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)
if [ -z "$repo" ]; then
  url=$(git remote get-url origin 2>/dev/null || true)
  repo=$(printf '%s\n' "$url" |
    sed -E 's#^git@github.com:##; s#^https://github.com/##; s#\.git$##')
fi
printf '%s\n' "$repo"
```

Current-project triage starts with:

```bash
repobar_cmd issues "$repo" --limit 50 --json
repobar_cmd pulls "$repo" --limit 50 --json
repobar_cmd ci "$repo" --limit 20 --json
repobar_cmd activity "$repo" --limit 20 --json
```

Before acting on any issue or PR, read all comments and treat Ossian/owner comments as authoritative routing instructions. If Ossian says it looks good, needs changes, is superseded, is product-approved, or is not wanted, that overrides bot labels and ordinary triage judgment. If there is no owner comment, use maintainer judgment and say that the call is yours.

Then inspect enough detail to explain every surfaced item. For small queues (about 10 open items or fewer), inspect all items. For larger queues, inspect the top priority slice and say what was not expanded. Use `gh` here for the cross-check/details RepoBar does not expose deeply enough:

```bash
gh issue view <n> --repo "$repo" \
  --json number,title,author,body,comments,labels,createdAt,updatedAt,url
gh pr view <n> --repo "$repo" \
  --json number,title,author,body,comments,files,commits,isDraft,reviewDecision,mergeStateStatus,statusCheckRollup,createdAt,updatedAt,url
gh pr diff <n> --repo "$repo" --patch
```

Only comment, close, merge, rerun, or patch with strong evidence.

## Triage Output

When the user says `triage`, always scan open issues and open PRs for the current repo. Return:

- `Autonomous candidates`: items that appear fixable/landable without more product input, with URL, why it qualifies, required verification, and confidence. This is a selection for review, not permission to start work unless the user also asks for autonomous execution.
- `Needs Ossian`: items blocked on owner decision, product direction, missing credentials/access, live-provider proof that cannot be obtained, security/privacy judgment, or an authoritative owner comment requesting changes.
- `Defer/close/supersede`: stale, duplicate, lower-quality, or overlapping items where the likely action is not new code.

For every plausible autonomous candidate, check feasibility before presenting it: use the `oracle` skill or an independent high-reasoning subagent when available. Give the reviewer only task-local evidence and ask whether the item can be completed autonomously, what verification is required, and what could make it unsafe. If no second-model review is available, do the same depth yourself and say so.

## Autonomous Work Mode

When the user says `do work autonomously`, `work you can do autonomously`, `keep going`, or similar, do not stop after a queue summary or one local patch. Treat it as permission to process the eligible issue/PR queue sequentially until no safe autonomous item remains, each item is landed/closed/deferred with proof, or a blocker requires Ossian.

Never work multiple tickets at once. For each item:

1. Read the issue/PR, related code, docs, CI, and `VISION.md` if present; use official docs / web search when facts may be stale or unclear.
2. Decide if it is autonomous:
   - Go: performance improvements unless complexity rises too much; bugfixes with repro/root cause and verification path; small UI/UX tweaks; docs fixes; narrow test/internal fixes; low-risk dependency/CI cleanup with green proof.
   - Ask first: new features, product/vision choices, broad behavior changes, risky dependencies, security-sensitive changes without strong proof, live-provider work without usable credentials, anything that cannot be end-to-end tested.
   - Refactor preference: choose a clean bounded refactor when it is the better fix for an autonomous item; do not use "small patch" as the default if it leaves worse design.
3. Implement or fix the PR in the best maintainable way. Prefer updating the contributor PR when writable; otherwise recreate locally with credit.
4. Verify locally and live end-to-end when possible. For macOS UI behavior, use the `peekaboo` skill for screenshots / UI proof; for web UI, use the `agent-browser` skill. For API/provider behavior, use a real usable key/account through the expected secret workflow when available. If access is missing, stop before pretending the item is done and ask Ossian for help.
5. Run Codex Auto Review (`codex`) before commit/land unless trivial/docs-only or explicitly skipped; address accepted/actionable findings.
6. Ensure CI is green, PR description/changelog are good, land/close/comment with evidence, then return to the selected integration branch, pull `--ff-only`, and verify a clean worktree before selecting the next autonomous item.
7. After every landed PR, post a PR comment with exactly how it was tested: local commands, live/UI/API proof, CI run/check state, landed commit, and any caveats. If verification images apply, attach them to the comment; if you cannot attach images, say so and include the screenshot path instead of silently omitting them.

Do not end autonomous mode with dirty files or an unpushed local fix unless blocked. If blocked, state the exact blocker, current branch/status, proof already gathered, and the next decision needed.

Autonomous work is still bounded by scope: current repo by default; broad/all queues only when the user asked for broad/all/everything or named owners/orgs.

## Trust Signals

Include author/opener trust for every non-maintainer item you recommend acting on. For low-risk Dependabot/internal items, a terse bot/internal trust line is enough.

Use the bundled helper:

```bash
skills/github-project-triage/scripts/github-activity.sh --repo <owner/repo> --global <login>
```

Trust output must stay factual:

```text
Trust: @login; acct 2021-04-03; repo 2 PRs/1 issue/0 commits in 12mo; GitHub 9 PRs/3 issues/12 reviews; signal: known contributor / new drive-by / bot / unknown.
```

Do not treat trust as proof. It changes review depth, not correctness.

## Item Evaluation

Classify each item:

- `bug`: require repro/log/failing test/current-main proof when feasible; identify root cause before recommending fix/merge.
- `feature`: require end-to-end test plan. If live validation needs a provider key, account, device, service, model access, or paid API, say exactly what credential/access is missing before work can be considered complete.
- `dependency`: explain package group, major/minor risk, failing checks, runtime/engine changes, and whether to split.
- `security`: raise priority, require careful code-path proof, tests, and trust/context; do not merge on rationale alone.
- `docs/internal`: lower risk, but still explain user-visible relevance and stale/generated churn risk.

Judge:

- `Fit`: good / mixed / poor, with one reason.
- `Risk`: low / medium / high, with blast radius.
- `Proof`: current CI, local repro, failing test, live E2E, or missing proof.
- `Blocker`: first-time contributor CI approval, failing check, missing key, unclear product direction, stale branch, untrusted/broad diff, no repro, conflicts.
- `Next`: approve CI, run test, request repro, split PR, patch locally, merge after green, close with proof, or defer.

## Fast Queue Map

Use this when mapping more than one repository, including orchestrator runs. Start with RepoBar's repo-level map: it finds repos with open issues and/or PRs and gives counts in one call.

PR queue, primary triage order:

```bash
repobar_cmd repos --scope all --only-with work --owner ossianhempel --sort prs --json
```

Issue pressure, second pass when issues matter:

```bash
repobar_cmd repos --scope all --only-with work --owner ossianhempel --sort issues --json
```

Useful `jq` summary (fields: `fullName`, `openIssues`, `openPulls`, `activityTitle`, `activityActor`):

```bash
repobar_cmd repos --scope all --only-with work --owner ossianhempel --sort prs --json |
  jq -r '.[] | [.fullName, .openIssues, .openPulls, .activityTitle, .activityActor] | @tsv'
```

For a compact terminal view, use `--plain` instead of `--json`.

Notes:
- RepoBar covers private repos (shares the app's GitHub auth). Default `--age` is 365 days; pass `--forks`/`--archived` only when the user asks for "all", "everything", or archaeology.
- Preserve RepoBar's PR-count order when summarizing. Do not include a lower-PR repo while omitting a higher-PR repo from the same scope. Repos with zero issues but open PRs are still triage-relevant.

Fallback if RepoBar is unavailable or unreadable — report that fact, then sweep with `gh search` only if the user's scope permits a fallback:

```bash
gh search prs --owner ossianhempel --state open --limit 200 \
  --json repository,number,title,author,createdAt,updatedAt,url |
  jq -r 'group_by(.repository.nameWithOwner) | sort_by(-length)
    | .[] | "\(.[0].repository.nameWithOwner): \(length) open PRs"'
gh search issues --owner ossianhempel --state open --include-prs=false --limit 200 \
  --json repository,number,title,author,createdAt,updatedAt,url |
  jq -r 'group_by(.repository.nameWithOwner) | sort_by(-length)
    | .[] | "\(.[0].repository.nameWithOwner): \(length) open issues"'
```

## Detail Pass

After the RepoBar queue map, inspect only the top repos unless the user explicitly wants exhaustive detail. RepoBar gives fast per-repo issue/PR/CI/activity views:

```bash
repobar_cmd issues <owner/name> --limit 50 --json
repobar_cmd pulls <owner/name> --limit 50 --json
repobar_cmd ci <owner/name> --limit 20 --json
repobar_cmd activity <owner/name> --limit 20 --json
```

For PRs that look mergeable, suspicious, or worker-owned, switch to `gh` for maintainer-grade cross-check state (diff, checks, review decision, exact merge state, review threads):

```bash
gh pr view <n> --repo <owner/name> --json number,title,state,author,isDraft,mergeStateStatus,reviewDecision,statusCheckRollup,updatedAt,url
gh pr diff <n> --repo <owner/name> --patch
gh run list --repo <owner/name> --branch <branch> --limit 10
```

For issues that may already be fixed, switch to `gh issue view`, then inspect current source before commenting or closing.

To find duplicate or related threads before commenting or closing, search across your repos:

```bash
gh search issues --owner ossianhempel "<keywords>" --limit 30 --json repository,number,title,state,url
gh search prs    --owner ossianhempel "<keywords>" --limit 30 --json repository,number,title,state,url
```

## Local Cross-Check

Use this when the task mentions local project state, dirty repos, or "what do I own here". RepoBar maps local checkouts and their sync state:

```bash
repobar_cmd local --root "$HOME/Developer" --depth 1 --limit 200 --plain
repobar_cmd local --root "$HOME/Developer" --depth 1 --sync --limit 200 --json
```

Do not run destructive local actions (`local reset`, branch deletes, checkout moves) unless the user explicitly asks.

## Triage Heuristics

Prioritize:

- PRs with green or nearly-green CI, recent maintainer activity, or low-risk dependency/docs/test changes.
- Repos with high open PR counts but recent activity, because they often hide obvious cleanup.
- Issues that are reproducible, recently reported, or block releases.
- Security, release, auth, install, CI, and data-loss reports before cosmetic items.
- Bugs with clear current-main reproduction and narrow owner path.
- Features only when live validation is possible or the missing access is explicit.

Deprioritize:

- Archived repos unless the user asked for them.
- Fork-only queues unless the fork is actively maintained by Ossian.
- Old broad feature requests with no reproduction or owner signal.
- Repos with missing/removable remotes until local state is clarified.
- Feature/provider PRs that need unavailable API keys or accounts for end-to-end proof.
- Broad generated changes without a clear user problem, test plan, or trusted author signal.

## Output Shape

For current-project triage, answer with:

```text
Repo: owner/name
Source: RepoBar issue/PR/CI/activity map, plus gh detail/diff/check cross-checks and local source/tests where inspected

Immediate:
- #123 PR: title
  What: one-line summary in plain words.
  Type/Fit/Risk: bug|feature|dependency; good|mixed|poor; low|medium|high because ...
  Trust: @login; acct date; repo/global activity; known/unknown/bot.
  Proof: CI/repro/test/e2e state.
  Blocker: none / missing key / first-time CI approval / failing lint / unclear direction.
  Next: exact maintainer action.

Needs judgment:
- #124 issue: ...

Defer/close:
- #125 issue: ...

Skipped:
- <why>
```

For a broad scan, answer with:

```text
Owner scanned: ossianhempel
Source: RepoBar <command summary>, plus gh for selected PRs/issues

Top queues:
- owner/repo: X issues, Y PRs; why it matters; next action

Immediate actions:
- <small obvious merge/fix/comment/rerun, with item summary>

Needs judgment:
- <larger/ambiguous queues, with item summary>

Skipped:
- archived/forks/missing access/etc.
```

When the user asks to act, keep going: inspect the selected PRs/issues with `gh`, rerun/fix CI, comment/close/merge only with evidence, and report exact commands/proof.
