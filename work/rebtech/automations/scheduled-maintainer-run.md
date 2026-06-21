# Scheduled maintainer run (Azure DevOps)

A self-contained prompt for an unattended maintainer pass over Rebtech's scoped Azure DevOps repos.
Run it on a cadence (e.g. once each weekday morning). It assumes a **local** machine where `az` is already
logged in (`ossian.hempel@rebtech.se`, org `dev.azure.com/rebtech`, default project `RAID`). If the token
has expired the run stops and asks for a one-time interactive `az login` — it never attempts a
non-interactive workaround.

## Prompt

> Use the `rebtech-devops-maintainer` skill (and `rebtech-devops-triage` for assessment) to run a
> scheduled, low-touch maintenance pass over Rebtech's Azure DevOps. Read the skill first; it carries the
> per-repo overrides, proof rules, and permission boundaries. Stay strictly within the boundaries below.
>
> ### Where the work lives (look here, in this order)
> Org `https://dev.azure.com/rebtech`, two projects: **RAID** and **Assets**.
>
> 1. **Current sprint first (RAID).** RAID's active board is team **"RAID Team"**, current sprint
>    **"Sprint 3"** (`RAID\Sprint 3`). Pull the sprint queue with the current-iteration macro so it stays
>    correct as sprints roll over:
>    ```bash
>    az boards query --project RAID -o json --wiql \
>      "SELECT [System.Id],[System.Title],[System.State],[System.WorkItemType],[System.AssignedTo],[System.Tags] \
>       FROM workitems WHERE [System.TeamProject]='RAID' \
>       AND [System.IterationPath]=@CurrentIteration('[RAID]\RAID Team') \
>       AND [System.State]<>'Closed' ORDER BY [Microsoft.VSTS.Common.Priority] ASC, [System.ChangedDate] DESC"
>    ```
> 2. **Backlog fallback (RAID + Assets).** If the sprint has no in-scope autonomous item, widen to all
>    non-closed items, then filter to the scoped repos:
>    ```bash
>    az boards query --project RAID   -o json --wiql "SELECT [System.Id],[System.Title],[System.State],[System.WorkItemType],[System.Tags] FROM workitems WHERE [System.TeamProject]='RAID'   AND [System.State]<>'Closed' ORDER BY [System.ChangedDate] DESC"
>    az boards query --project Assets -o json --wiql "SELECT [System.Id],[System.Title],[System.State],[System.WorkItemType],[System.Tags] FROM workitems WHERE [System.TeamProject]='Assets' AND [System.State]<>'Closed' ORDER BY [System.ChangedDate] DESC"
>    ```
>    (Tags filter with `CONTAINS` only — `[System.Tags] <> ''` is rejected. Area path is `\RAID\Area`.)
> 3. **Open PRs** on each in-scope repo — these come before new work items (finishing/unblocking a PR beats
>    starting fresh):
>    ```bash
>    for r in raid-plugin raid-telemetry; do az repos pr list --project RAID   --repository $r --status active -o json; done
>    for r in rebtech-website skill-library; do az repos pr list --project Assets --repository $r --status active -o json; done
>    ```
>
> ### Scope (closed list — report-only for anything else)
> Maintenance targets: `RAID/raid-plugin`, `RAID/raid-telemetry`, `Assets/rebtech-website`,
> `Assets/skill-library`. A work item only becomes actionable if its change lands in one of these repos.
> Never touch wikis (`RAID.wiki`, `RIDE.wiki`) or `agent-skills`/`agent-scripts`. A work item whose work
> belongs to a non-scoped repo -> report under "Out of scope", do not action.
>
> ### What to work on (selection order)
> 1. An open PR in scope that you can move forward (resolve your own threads, rebase if push-granted, add
>    proof) up to the open-PR boundary.
> 2. A current-sprint work item in scope that classifies **autonomous** (clear definition of done + a usable
>    verification path): docs/README fixes, narrow bugfixes with a repro, low-risk dependency/CI cleanup,
>    small skill/prompt edits, test-only fixes, well-scoped right-fix refactors.
> 3. A backlog item in scope that classifies autonomous.
> Skip and report as **needs-owner**: product/architecture choices; secrets/Key Vault/pipeline-variable/
> service-connection changes; customer-data or Fabric/production behavior; anything with no proof path or
> missing access. Do not guess on these. The goal is to work as autonomously as possible whenever the task
> is sufficiently defined.
>
> ### Self-review before every PR (autoreview, Claude engine)
> After implementing and committing on the feature branch, validate your own work before opening the PR:
> ```bash
> /Users/ossianhempel/Developer/agent-scripts/skills/autoreview/scripts/autoreview \
>   --engine claude --mode branch --base "origin/<integration>"
> ```
> Follow the `autoreview` skill contract: verify each finding against the real code, fix accepted/actionable
> ones, re-run focused tests + re-run autoreview after any fix, and continue until it exits clean. Only then
> open the PR. If a fix changes the runtime path, refresh the proof.
>
> ### How to orchestrate
> - Default **single-threaded**: handle one item fully (gate -> implement -> prove -> PR -> monitor -> stop)
>   before the next.
> - Escalate to subagents **only** if >=2 in-scope repos have ready autonomous work; then spawn **one
>   worker per repo** (never per item), cap nesting at depth 2, and paste the brief from the skill's
>   `references/repo-worker.md`. Workers never write the ledger or manage another lane.
> - Per-repo overrides are non-negotiable: `rebtech-website` PRs are opened by push + create-PR link (never
>   `az`; `pnpm lint` must be 0/0 first); `skill-library` — confirm the local clone's remote is the Azure
>   DevOps fork before pushing. Integration branches: `master` for rebtech-website, `main` for the rest —
>   but always re-confirm from each repo's own `AGENTS.md`/`CLAUDE.md`.
>
> ### Work-item lifecycle (keep the board honest, like the Codex flow)
> When an autonomous in-scope item is picked up (by root, or by a delegated worker for its lane), **claim
> it** before implementing: `az boards work-item update --id <id> --state Active --assigned-to
> "ossian.hempel@rebtech.se" --discussion "Picked up by maintainer routine (<root|worker:repo>). Working on
> feature/<id>-<slug>."`. When the PR opens, add a non-closing status comment with the PR URL (item stays
> Active — there is no In-Review state). A delegated worker updates its own item and reports each transition
> (claimed -> implementing -> pr-open / blocked) back to root; root reconciles the ledger. Never set an item
> Closed/Resolved (the owner closes after merge), and never touch the state/assignee of an item you are not
> working. Do not claim needs-owner items — leave them New and surface them in the report.
>
> ### Permissions
> Granted: read; **claim a work item (set New->Active, assign to ossian.hempel@rebtech.se, add a
> `--discussion` status comment)**; implement on a `feature/<id>-<slug>` branch; push that feature branch;
> open a PR. NOT granted (stop at the boundary): close/resolve a work item, merge/complete, abandon/close a
> PR, force-push, push to main/master/release, release/tag, public PR comments/votes, pipeline/policy/secret
> changes, `ci-rerun`/`ci-fix`.
>
> ### Keep track of progress (so each run resumes cleanly)
> - **Ledger** `~/.local/state/rebtech-maintainer/run-<YYYY-MM-DD>.json` — one entry per item:
>   `workItem`, `url`, `repo`, `integrationBranch`, `featureBranch`, `worker`, `phase`
>   (`implementing|proof|pr-open|monitoring|needs-owner|blocked`), `pr`, `permissions`, `blocker`.
> - **Human log** `~/rebtech-orchestrator.md` — append dated, high-level entries: items picked up, PRs
>   opened (full URLs), owner questions raised, blockers. Never secrets, never routine polling.
> - **At the start of each run, read both files first.** Skip items already at `pr-open`/`needs-owner`
>   from a prior run (just re-check their PR policy/CI state); do not re-open duplicate PRs or restart work
>   already in flight. The ledger is the dedupe authority.
>
> ### Stop conditions (ask me, do not guess)
> Auth expired (need interactive `az login`); ambiguous integration branch; 403 on a project/repo; a
> needs-owner decision; a dirty working tree you did not create; attachment upload blocked with no
> `docs/proof/` fallback.
>
> ### Stale / not-progressing (required section)
> After working everything you can, scan the in-scope queue for items that are NOT moving and report them —
> the owner needs to know what is stuck:
> - **Stale backlog**: in-scope, still New/Active, no linked PR, `[System.ChangedDate] < @Today - 14`.
> - **Repeatedly deferred**: classified needs-owner/blocked this run AND a prior run (cross-check the log).
> - **Stalled WIP**: Active/assigned, no recent change, no open PR.
> If most in-scope open items are needs-owner/blocked/stale, add a one-line queue-health verdict:
> "Queue not progressing — N of M in-scope items need your input / are stale." For each stale item give
> URL, title, state, days-since-changed, likely reason (underspecified / needs-owner / blocked-on-access /
> no in-scope repo), and a suggested action. Do NOT close or mutate stale items — just surface them.
>
> ### Report
> Compact cross-project ledger: **Active** (repo, item URL, phase, work-item state) / **PR-open** (PR URL,
> policy+CI state, what the owner must do) / **Needs-owner** (full Owner Decision Brief) / **Blocked**
> (exact blocker + branch/status + proof gathered) / **Stale-not-progressing** (per above) / **Out of
> scope** (named, untouched). Full clickable PR + work-item URLs, never bare `#123`. Report meaningful
> changes only.

## Cadence notes

- Once-daily pass; do not tight-poll between runs.
- A PR left open and awaiting the owner stays open — re-check policy/CI is fine; do not nudge reviewers or
  re-push without a `ci-fix` grant.
- The run produces decision-ready PRs and an owner-question list; it never crosses the open-PR boundary.

## Running it as a routine in Claude Code

This prompt assumes **local** `az` auth + local repo clones under `~/rebtech/`, so it must run on this
machine, not in a cloud sandbox. Wire it up as a local recurring `claude` run, e.g. a launchd/cron entry:

```bash
# weekday 08:00 local maintainer pass (headless)
claude -p "$(cat ~/Developer/agent-scripts/work/rebtech/automations/scheduled-maintainer-run.md)"
```

(If instead you register a Claude Code cloud routine, it will not have local `az`/clones — it would need a
scoped `AZURE_DEVOPS_EXT_PAT` and a clone step added first. Prefer the local run.)
