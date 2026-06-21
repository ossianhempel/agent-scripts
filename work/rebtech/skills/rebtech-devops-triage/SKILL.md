---
name: rebtech-devops-triage
description: "Read-only triage of Rebtech's Azure DevOps queue from Claude Code: assess Azure Boards work items and active pull requests across the RAID and Assets projects, each with a plain-language what-it-is, type, fit, risk, proof/CI state, blocker, and the exact next maintainer action. Use when the user asks to triage the Azure DevOps backlog, review the work-item/PR queue, see what is worth doing, prioritize, or get a maintainer-grade read on the queue without changing anything. This is the assessment front-end for the rebtech-devops-maintainer skill (which actually implements + opens PRs). It maps the GitHub/Codex github-project-triage pattern onto az devops: WIQL + az repos pr instead of gh/RepoBar. Triage only — it never edits, pushes, comments, votes, or merges."
---

# Rebtech Azure DevOps Triage

Maintainer-grade, **read-only** assessment of the Azure DevOps queue. Produce a clear picture of what is
in the queue, what is worth doing, what is blocked, and the exact next action — without changing anything.
This is the front-end; `rebtech-devops-maintainer` is what actually implements and opens PRs.

Adapted from the private `github-project-triage` skill: same evaluation criteria, Azure DevOps tooling.
For the command reference see `rebtech-devops-maintainer/references/azure-devops-cli.md`.

## Scope

Default to the named maintenance repos: `Assets/rebtech-website`, `Assets/skill-library`,
`RAID/raid-plugin`, `RAID/raid-telemetry`. Broaden only if the user says so or names other repos. Wikis and
`agent-skills` are out of scope.

If the current working directory is itself one of these repos, triage just that one unless asked for `all`.

## Discover (read-only)

```bash
# Non-closed work items, per project
az boards query --project RAID -o table --wiql \
  "SELECT [System.Id],[System.Title],[System.State],[System.WorkItemType],[System.AssignedTo],[System.Tags] \
   FROM workitems WHERE [System.TeamProject]='RAID' AND [System.State]<>'Closed' ORDER BY [System.ChangedDate] DESC"
az boards query --project Assets -o table --wiql "... [System.TeamProject]='Assets' ..."

# Active PRs, per in-scope repo
az repos pr list --project RAID --repository raid-plugin --status active -o json

# For a PR worth a closer look:
az repos pr show --id <pr> -o json                              # diff metadata, mergeStatus, reviewers
az repos pr policy list --id <pr> -o json                       # build + reviewer gate status
az pipelines runs list --project <P> -o table                   # filter refs/pull/<pr>/merge for CI
az devops invoke --area git --resource pullRequestThreads \
  --route-parameters project=<P> repositoryId=<id> pullRequestId=<pr> \
  --http-method GET --api-version 7.1 -o json                    # review threads (REST; read-only)
```

Tags filter with `CONTAINS` only. Quote dotted fields in JMESPath.

## Integration-branch gate (do not assume the default)

Before calling any PR "ready", determine the real integration branch from the repo's `AGENTS.md`/`CLAUDE.md`,
not the API default (at least one Rebtech repo defaults to a feature branch). Flag any PR whose
`targetRefName` does not match the documented integration branch as a blocker, not a ready item.

## Evaluate each item

For every work item / PR, judge:
- **Type**: bug | feature | dependency | security | docs/internal
- **Fit**: good | mixed | poor (+ one reason)
- **Risk**: low | medium | high (+ blast radius)
- **Proof**: current CI | local repro | failing test | live E2E | missing proof
- **Blocker**: failing check | unclear product direction | missing access/credential | stale branch |
  conflicts | wrong target branch | no repro | none
- **Next**: run test | request repro | patch locally | split PR | implement candidate | merge after green
  (owner) | close with proof (owner) | defer

Internal org: drop drive-by/account-age trust scoring; weight by reproducibility, risk, and proof instead.

## Classification (matches the maintainer skill)

- **GO (autonomous-eligible)**: docs fixes, narrow bugfixes with repro + verification path, small UI/UX
  tweaks, low-risk dependency/CI cleanup that goes green, test-only fixes, well-scoped right-fix refactors.
- **ASK FIRST**: new features, product/architecture choices, security/secret/pipeline-variable changes,
  customer-data/Fabric/production behavior, anything not end-to-end testable, missing access.

## Output template

```
Project/Repo: <Assets|RAID>/<repo>   (integration branch: <branch>)

Immediate (autonomous-eligible):
- AB#207 <type>: <title>   <full work-item or PR URL>
  What: one-line plain summary.
  Type/Fit/Risk: bug | good | low because ...
  Proof: CI/repro/test/e2e state.
  Blocker: none | <exact blocker>.
  Next: <exact maintainer action>.

Needs judgment (ASK FIRST):
- AB#124 ...

Defer / close:
- AB#125 ...

Out of scope / skipped:
- <repo or item> — <why>
```

Prioritize: security > release-blocking > auth > CI > data-loss > cosmetic; reproducible and recent over
old vague requests; nearly-green PRs over cold ones. Always use full clickable URLs, never bare `#123`.
Hand off GO items to `rebtech-devops-maintainer` to implement; this skill never mutates anything.
