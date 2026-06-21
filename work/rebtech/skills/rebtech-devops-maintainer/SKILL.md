---
name: rebtech-devops-maintainer
description: "Delegated maintainer/orchestrator for Rebtech's Azure DevOps repos using Claude Code. Discovers scoped work (Azure Boards work items + active PRs), classifies it autonomous-vs-needs-owner, implements safe items on isolated branches, creates decision-ready pull requests with proof, and monitors branch policies, pipelines, and PR review threads — stopping cleanly at the open-PR boundary. Use when the user asks to triage and work the Azure DevOps queue, run repo maintenance, clear the backlog, prepare decision-ready PRs, babysit pipelines/PRs, or run the maintainer loop across rebtech-website, skill-library, raid-plugin, or raid-telemetry. Pairs with rebtech-devops-triage (queue assessment) and the az-cli skill (command reference). Adapts the GitHub/Codex maintainer-orchestrator pattern to Azure DevOps + Claude Code: az devops CLI instead of gh, subagents instead of Codex threads."
---

# Rebtech Azure DevOps Maintainer Orchestrator

Run a safe, auditable maintenance loop over Rebtech's Azure DevOps repos from Claude Code.
The spine is: **discover -> classify -> (delegate) -> implement -> prove -> open PR -> monitor -> stop at the open-PR boundary -> report.**

This skill is the Azure DevOps + Claude Code adaptation of the private `maintainer-orchestrator`
and `github-project-triage` skills. The classification rules, decision-ready-queue discipline, and
permission separation are unchanged; only the tooling changes (`az devops` not `gh`, Claude Code
subagents not Codex threads). For per-command detail read `references/azure-devops-cli.md`. For the
worker/subagent contract read `references/repo-worker.md`.

## Operating mode: single-thread first, subagents only when earned

Default to **single-threaded**: the root agent does discovery, classification, one item end to end,
the PR, and monitoring inline. It is simpler, fully auditable, and matches the current queue depth.

Escalate to **subagents only when** there are >=2 independent repo lanes with ready autonomous work
**and** the owner granted parallel execution for this run. Then spawn **one worker per repo, never per
item**. Hard nesting cap of 2 (root=0 -> repo-worker=1 -> one read-only helper=2). A worker never
spawns another worker, never manages another lane, and never writes the shared ledger. See
`references/repo-worker.md`.

Do not tight-poll workers. Spawn with `run_in_background: true` (and `isolation: "worktree"` when lanes
touch files concurrently); rely on completion notifications, with a `ScheduleWakeup` backstop (>=1200s)
only as a heartbeat. Regain control via the completion notification + `SendMessage` to continue a
specific worker (continue, never respawn — respawning loses context).

## Scope (this is a closed list — do not broaden silently)

Maintenance targets, by Azure DevOps project:

| Project | Repo | Integration branch (verified) | Notes |
|---|---|---|---|
| Assets | `rebtech-website` | `master` | Next.js; UI proof required; **do NOT open PRs with `az`** (see overrides) |
| Assets | `skill-library` | `main` | pnpm monorepo; **dual remote** GitHub vs Azure DevOps (see overrides) |
| RAID | `raid-plugin` | `main` | branch policies blocking on main |
| RAID | `raid-telemetry` | `main` | never enable HNS / OneLake shortcut on the source |

Out of scope unless the user explicitly names it this run:
- `agent-skills` (the company SKILL.md library) and this repo (`agent-scripts`) are homes, not maintenance targets.
- Every other RAID/Assets repo.
- **Wikis** (`RAID.wiki`, `RIDE.wiki`) are explicit-permission only — never edit autonomously.

### Per-repo overrides (verified — these beat the generic flow)

- **`rebtech-website`** — the account is blocked by Conditional Access for programmatic PR creation, so
  **never run `az repos pr create` here.** Instead: make a single commit whose message is the PR
  title+description (`git commit -m "<title>" -m "<description>"`), push the feature branch, then surface
  the Azure DevOps create-PR link — `bash scripts/open-pr.sh`, or
  `https://dev.azure.com/rebtech/Assets/_git/rebtech-website/pullrequestcreate?sourceRef=<branch>&targetRef=master`
  (the create page pre-fills title+description from that single commit) for the owner to click. `pnpm lint`
  must be **`0 errors, 0 warnings`** before any push (it is exactly what CI runs); run `pnpm typecheck` for
  larger changes. Merge to `master` deploys to production (Vercel) — we never merge anyway, but flag it.
  Generic rule: if `az repos pr create` ever returns a Conditional Access / 403 on any repo, fall back to
  this push + create-PR-link method rather than treating it as a hard failure.
- **`skill-library`** — the local clone may track **GitHub `origin`** rather than the Azure DevOps fork.
  Before pushing, run `git remote -v` and confirm you are pushing to the Azure DevOps `Assets/skill-library`
  remote (push to `main` triggers `azure-pipelines.yml`). If it tracks GitHub, stop and ask which remote the
  maintenance PR should target.

Always confirm a repo's real integration branch from its own `AGENTS.md`/`CLAUDE.md` before branching.
Never trust the API default branch — at least one Rebtech repo defaults to a feature branch.

## Stage 1 — Discover the queue

Per in-scope project, read non-closed work items and active PRs (read-only):

```bash
# Work items (run for RAID and Assets)
az boards query --project RAID -o json --wiql \
  "SELECT [System.Id],[System.Title],[System.State],[System.WorkItemType],[System.AssignedTo],[System.Tags] \
   FROM workitems WHERE [System.TeamProject]='RAID' AND [System.State]<>'Closed' \
   ORDER BY [System.ChangedDate] DESC"

# Active PRs, per in-scope repo (or per project)
az repos pr list --project RAID --repository raid-plugin --status active -o json
```

Tags filter with `CONTAINS` only — `[System.Tags] <> ''` is rejected. Filter the result down to the
scoped repo list above; report (do not action) anything outside scope.

## Stage 2 — Classify (autonomous vs needs-owner)

Tuned for an internal org (known colleagues, effectively no forks — drop drive-by/trust heuristics).

**Autonomous** (implement -> open PR, then stop): docs/README fixes, narrow bugfixes with a repro and
a verification path, low-risk dependency/CI cleanup that goes green, small skill/prompt edits, test-only
fixes, well-scoped refactors that are the *right* fix. The guiding test: relatively clear work with a
clear definition of done and a usable verification path -> do it as autonomously as possible.

**Needs owner**: product/architecture choices; anything touching secrets, Key Vault, pipeline variables,
or service connections; customer-data or Fabric/production-platform behavior; work needing access you do
not have; work with no end-to-end proof path; destructive/irreversible changes.

Planning/brainstorm/research-only output is **not** a repo PR — it goes in the run report, never as a
docs PR.

## Stage 3 — Local repo gate (the dirty-tree guard)

`~/rebtech` is a workspace parent, not a git repo — each subdir is its own repo. Per item:

1. Map the work item / PR to its local clone `~/rebtech/<repo>` (clone via `az repos clone` if absent).
2. Read that repo's `AGENTS.md`/`CLAUDE.md` and pick the integration branch: (a) what the repo
   instructions say, else (b) a clean local checkout already on a documented dev branch, else (c)
   `main`/`master`. If the API default is a feature branch and instructions are silent -> **stop, ask**.
3. `git status --short --branch`. If dirty -> **stop, report**; never stash or discard someone's work.
4. Create `feature/<workitem-id>-<slug>` off freshly fetched `origin/<integration>`. For parallel lanes
   use a git worktree so workers cannot collide.
5. Return clean: after the PR is open, `git switch <integration> && git pull --ff-only && git status`
   must be clean before the next item. Never leave a dirty tree or a stray branch.

## Stage 4 — Implement + prove

Implement the smallest correct change. Then gather proof and store it where Azure DevOps reviewers see it:

- **Non-UI**: exact commands + output, test runs, lint/typecheck, final commit SHA — pasted **inline in
  the PR description**. Run focused + full tests per repo (`pytest -m unit`, `npm run typecheck && npm test`,
  `pnpm` scripts, `dataform compile`, etc.).
- **UI** (`rebtech-website`): screenshots of the changed path via the playwright MCP / agent-browser skill.
- **Image storage = PR attachments** (decided): upload after the PR exists and embed the returned URL in
  the description. Exact `curl`/token recipe in `references/azure-devops-cli.md` (Attachments). Fallback
  if attachments are blocked: commit under `docs/proof/<workitem>/` in the same PR, or paste the path +
  textual description. Never silently omit proof.

## Stage 4b — Self-review with autoreview (Claude engine) before any PR

The routine validates its own work before opening a PR — this is non-negotiable for autonomous runs.
Commit the change on the feature branch, then run the `autoreview` skill against the branch diff using the
**Claude engine** (not the default Codex):

```bash
/Users/ossianhempel/Developer/agent-scripts/skills/autoreview/scripts/autoreview \
  --engine claude --mode branch --base "origin/<integration>"
```

Follow the `autoreview` skill's contract: review output is advisory — verify each finding against the real
code path, fix the accepted/actionable ones at the right boundary, and **re-run focused tests + re-run
autoreview** after any fix. Keep going until the helper exits clean with no accepted/actionable findings.
Only then proceed to Stage 5. If a fix changes the runtime path, refresh the proof from Stage 4. Do not
push or open the PR just to review — review locally first. (For `rebtech-website`, autoreview the single
title+description commit before the push that surfaces the create-PR link.)

## Stage 5 — Open the PR (decision-ready, non-closing link)

Default path (raid-plugin, raid-telemetry, skill-library):

```bash
az repos pr create --project RAID --repository raid-plugin \
  --source-branch feature/<id>-<slug> --target-branch main \
  --title "<type>(<scope>): <summary>" \
  --work-items <id> \
  --description "$(cat /tmp/pr-body.md)"
```

**`rebtech-website` exception** (see Per-repo overrides): do NOT use `az` — make one commit whose message
is title+description, push the branch, and surface `bash scripts/open-pr.sh` / the `pullrequestcreate` link
for the owner. Same fallback applies anywhere `az repos pr create` returns a Conditional Access / 403.

PR body shape:
- One-line plain summary (what changes, who benefits).
- `Work item: AB#<id>` — linked but **non-closing** (linking does not transition the item on merge here).
- **Proof** section (commands/output, screenshots or attachment links).
- Tests run + result; lint/typecheck.
- Risk / tradeoffs / residual gaps.
- Reviewer note if a specific owner should look.

Verify `targetRefName` matches the selected integration branch before reporting the PR ready; never leave
a dev PR aimed at production `main`/`master` by accident.

## Work-item lifecycle (claim on pickup, report on transitions)

The board must reflect reality, the same way the Codex maintainer flow does. Tie state changes to the
work, whether the root works the item single-threaded or delegates it to a repo-worker:

- **On pickup / delegation (claim it):** before implementing, set the item active and owned. The worker
  that will do the work (root or subagent) runs:
  ```bash
  az boards work-item update --id <id> --state Active --assigned-to "ossian.hempel@rebtech.se" \
    --discussion "Picked up by maintainer routine (<root|worker:repo>). Working on feature/<id>-<slug>."
  ```
  Only claim items already in scope and classified autonomous. Do not claim needs-owner items — leave those
  New and surface them in the report. Do not touch the state/assignee of items you are not working.
- **On PR open (report status to the board):** add a non-closing status comment with the PR link; the item
  stays **Active** (RAID has no In-Review state):
  ```bash
  az boards work-item update --id <id> \
    --discussion "Decision-ready PR opened: <pr-url>. Awaiting review/merge. Item left Active (owner closes after merge)."
  ```
- **On blocked / handed back to owner:** comment the exact blocker; leave the item Active (or New if never
  claimed) and put it under Needs-owner in the report. Never set it Closed/Resolved.
- **Worker -> root reporting:** a delegated worker updates its own item's state/comments (its lane) and
  **reports each transition back to root** (claimed -> implementing -> pr-open / blocked). Root reconciles
  the ledger from those reports; workers never write the ledger themselves.

These work-item writes (`--state Active`, `--assigned-to`, `--discussion`) are the *only* board mutations
allowed. Closing/resolving is always the owner's action after merge.

## Stage 6 — Monitor (stop at the open-PR boundary)

Per open PR you own this run:
- **Policy / mergeability**: `az repos pr policy list --id <pr>` (build + reviewer gates).
- **CI**: `az pipelines runs list --project <P> -o table`, filter to `refs/pull/<pr>/merge`; read failing logs.
- **Review threads**: REST only — `az devops invoke --area git --resource pullRequestThreads ...` (recipe in
  references). Address or explicitly answer threads you own; **never resolve a reviewer's thread** without grant.
- **Conflicts**: if `mergeStatus` = conflicts, rebase on freshly fetched integration branch (only if push
  granted), re-run proof, update the PR.
- **Rerun/fix**: only if `ci-rerun`/`ci-fix` is explicitly granted. Push alone does not authorize fix commits.

Then **stop**. Do not complete/merge — branch policy blocks it anyway, and it is out of scope.

## Permission boundaries (hard stops)

Default granted for autonomous runs: **read everything; claim a work item (set `New -> Active` + assign +
status comment, per the lifecycle below); implement on a feature branch; push that feature branch; open a
PR.** Everything past the open-PR boundary is a separate explicit grant.

Never, unless explicitly granted for this run:
- **close/resolve a work item** (Active is the ceiling — the owner closes after merge);
- complete/merge a PR; abandon/close a PR; delete a branch;
- force-push; push to `main`/`master`/release branches directly;
- create a release / tag / publish;
- post a public **PR** comment, reply, or vote (a work-item *discussion* comment for status is allowed);
- modify branch policies, pipeline definitions, variables, secrets, or service connections;
- touch any repo or wiki outside the scoped list;
- reassign or change the state of a work item you are **not** actively working this run.

## Shared state (root is the only writer)

- Machine ledger: `~/.local/state/rebtech-maintainer/run-<YYYY-MM-DD>.json` — one entry per item
  (`workItem`, `url`, `repo`, `integrationBranch`, `featureBranch`, `worker`, `phase`, `workItemState`,
  `assignedTo`, `pr`, `permissions`, `blocker`). Phase in
  `claimed|implementing|proof|pr-open|monitoring|needs-owner|blocked`; `workItemState` mirrors the board
  (`New|Active`). Root writes this from worker reports.
- Human log: `~/rebtech-orchestrator.md` — dated, high-level entries (lane assignments, PRs opened with
  full URLs, owner questions, blockers). Never secrets; never routine polling.

## Stage 7 — Report

Compact, cross-project ledger. Always use full clickable PR/work-item URLs (never bare `#123`):
- **Active**: repo, item URL, worker, current phase, work-item state.
- **PR-open**: PR URL, policy/CI state, what is left (review/merge by owner).
- **Needs owner**: use the Owner Decision Brief (below). Never a bare URL + "merge/close".
- **Blocked**: exact blocker, current branch/status, proof gathered, next decision needed.
- **Stale / not progressing**: see below — this is a required section, not optional.
- **Out of scope**: named, untouched, reported.

### Stale / not-progressing detection (required every run)

The point of the routine is to *clear* well-defined work. Anything that is not getting worked is a signal
for the owner — either it is underspecified, blocked, or genuinely stale. After working everything it can,
the routine scans the in-scope queue for items that are not moving and reports them:

- **Stale backlog**: in-scope item still `New`/`Active`, no linked PR, not touched in a while. Find with
  `[System.ChangedDate] < @Today - 14` (default threshold 14 days; tune as needed):
  ```bash
  az boards query --project RAID -o json --wiql \
    "SELECT [System.Id],[System.Title],[System.State],[System.ChangedDate],[System.AssignedTo] FROM workitems \
     WHERE [System.TeamProject]='RAID' AND [System.State]<>'Closed' AND [System.ChangedDate] < @Today - 14 \
     ORDER BY [System.ChangedDate] ASC"
  ```
- **Repeatedly deferred**: items the routine classified needs-owner or blocked on this run **and** a prior
  run (cross-check the ledger / `~/rebtech-orchestrator.md` history). These are not getting unblocked.
- **Stalled WIP**: item `Active`/assigned with no recent change and no open PR — claimed but not finished.
- **Queue-health line**: if most in-scope open items are needs-owner/blocked/stale (few autonomous), say so
  explicitly: "Queue not progressing — N of M in-scope items need your input / are stale."

For each stale item report: full URL, title, state, days since changed, the last known reason it is not
moving (underspecified / needs-owner decision / blocked-on-access / no in-scope repo), and a suggested
owner action (clarify the definition of done, reprioritize, or close). The routine does **not** close or
mutate stale items — it surfaces them for you to decide.

### Owner Decision Brief (use whenever asking the owner)

Refresh the item + worker state immediately before asking. Include: full clickable URL + title; plain
explanation (what changes, who benefits); why a decision is needed now; completed proof (repro, tests,
live proof, CI, mergeability); material tradeoffs/risks/missing evidence; an opinionated recommendation +
rationale; the exact choices and what each does. One brief per decision.

## Failure modes

| Failure | Response |
|---|---|
| Missing/expired auth | `az account get-access-token` fails -> stop, report "re-run `az login`" (local, interactive that one time). Never half-act. |
| Unreadable project scope (403) | Stop that lane, report exact project/repo + permission needed; continue other lanes. |
| Ambiguous integration branch | API default is a feature branch and instructions silent -> stop, ask which branch. Never guess. |
| No proof-upload path | Attachments blocked -> fall back to `docs/proof/` commit or inline path+text; report the degradation. |
| CI failure | Read logs; fix only if `ci-fix` granted; else leave PR with failing check + diagnosis in the report. |
| Unresolved review threads | Read via REST; address/answer your own; never resolve others'; product call -> Owner Decision Brief. |
| Subagent drift | Root verifies each lane is on its assigned repo/branch and in scope on every check-in; on drift -> `SendMessage` correction or stop the worker. Workers cannot write the ledger, so drift cannot corrupt shared state. |

## Keep the skill in source control

This skill lives in the private `agent-scripts` repo under `work/rebtech/skills/rebtech-devops-maintainer/`
(`work/<employer>/` is the per-employer bucket — Rebtech now, H&M later — kept separate from the personal
skills in `skills/`). Scheduled-job prompts sit beside it in `work/rebtech/automations/`. It loads into
**Claude Code only** (not Codex) via `work/sync-claude-skills.sh`, which symlinks `work/*/skills/*` into
`~/.claude/skills` and never into `~/.agents/skills`. Improve it there and commit to `agent-scripts` —
never local-only edits under `~/.claude`. Azure DevOps CLI gaps belong in the `az-cli` skill source
(`raid-plugin` -> `raid-core/skills/az-cli`), via a PR to that repo.
