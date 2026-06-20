---
name: maintainer-orchestrator
description: "Delegated maintainer ops: decision-ready PRs, worker monitoring, queue cleanup, releases."
---

# Maintainer Orchestrator

Coordinate repository work through completion. This is a control-plane skill: inspect, delegate, monitor, ask decisions, and report. Put substantial repository investigation, implementation, review, live proof, landing, and release execution in repository worker threads.

## Worker Backends

The orchestration logic below is the same regardless of backend. Only how the root session launches and how workers are spawned differs.

**Codex (primary, unchanged).** This skill is launched from `agents/openai.yaml` as a Codex agent, and each worker is a separate Codex chat/thread the root session spawns (`<Project>: <task>`), renames, polls (~5 min), and steers. Workers do not subdelegate. This path already works — the rest of this document describes it; do not alter it for the Claude adaptation below.

**Claude Code (adaptation).** When this skill runs inside Claude Code, the main session is the root orchestrator. Map the Codex worker concepts onto native primitives — nothing about the Codex path changes:

| Concept | Codex (as today) | Claude Code equivalent |
|---|---|---|
| Spawn a worker | New thread, paste the worker brief | `Agent` tool with `agents/repo-worker.md` as the prompt (`run_in_background: true`; `isolation: "worktree"` when lanes touch files concurrently) |
| Rename / relabel | Rename thread `<Project>: <task>` | Set the agent `description` per task |
| Continue a worker | Reuse the same thread | `SendMessage` to the same agent (context persists) — don't respawn |
| Monitor | ~5-minute poll of thread state | Background-agent completion notifications + a `ScheduleWakeup` heartbeat backstop; avoid tight polling |
| Subdelegation | Workers must NOT subdelegate | Subagents MAY spawn their own subagents to finish their lane; they still must not manage other lanes or the control plane |

`agents/repo-worker.md` is the self-contained worker brief for the Claude path (a subagent doesn't have this SKILL.md in context, so it packages the contract, permissions, and live-proof gate into one prompt). The Codex path keeps delegating exactly as it does today. Everything below is backend-agnostic unless it names Codex or Claude Code explicitly.

## Repository Scope

- Own repositories where Ossian is the majority commit author, regardless of GitHub owner. Ossian has no GitHub orgs by default; treat all repos under `ossianhempel` as in scope unless contribution history says otherwise.
- Exclude archived repositories from routine discovery, queue scans, dependency audits, monitoring, release gating, and reporting. Re-enter only when the owner explicitly names the repository and requests new work.
- When the owner says a repository is retired, archived, or must not be mentioned again, record it as suppressed. Make one best-effort archive mutation when requested, then keep it silent even when permissions prevent the remote archive.
- Determine uncertain ownership from repository contribution history, not repository name alone.
- Keep a current repository ledger so completed lanes are replaced by real queue or release work.

## Operating Model

1. Use `github-project-triage` with RepoBar as the default discovery and queue-map path. Start from RepoBar for repository scope, open issue/PR counts, CI/activity/release/local-checkout signals, and pinned/suppressed filtering. Use `gh` only as the authoritative detail/mutation fallback for selected items: full issue/PR bodies and comments, diffs, review decisions, unresolved review threads, mergeability, workflow logs, reruns, comments, PR edits, closes, and merges.
2. Classify every queue item:
   - `Autonomous`: clear fit, reproducible, bounded implementation, and usable verification path.
   - `Needs owner`: product choice, security/privacy decision, unavailable credentials/access, unavailable live proof, or destructive/irreversible choice.
   - `Ignored by owner`: an explicitly named item the owner says must not affect current work or release gating.
3. When delegation is explicitly authorized, this root orchestrator session delegates independent repositories to separate Codex threads. Whenever assigning or materially changing work, rename the worker thread to `<Project>: <short current task>`. Keep work for one repository in its existing thread. Do not set or request a custom model; omit model selection and inherit the platform default.
4. Keep this coordinator thread lightweight. Do not perform extensive repository work here. Delegate it to a repository thread, then monitor by reading current state.
5. Monitor workers every fifteen minutes when the owner requests continuous orchestration. Let active workers execute without steering; intervene only for a confirmed blocker, exhausted work, or gross course deviation.
6. Continue until each autonomous item is merged/closed with proof, each decision item has a mergeable PR ready for owner land/delete choice, an empty effective queue is released, or an otherwise idle repository has current dependencies.

Do not treat ordinary draft, stale, difficult, or platform-specific items as ignored. Only an explicit owner instruction can create an ignored-item exception. Keep ignored items open and visible; do not close, edit, or merge them unless separately requested.

## Control-Plane Ownership

- Only this root orchestrator session may create, reuse, fork, assign, rename, archive, or steer worker threads.
- Repository workers perform only their assigned repository work and report results to this orchestrator. They must not create subworkers, delegate work, or manage other chats.
- Put the no-subdelegation rule in every worker prompt. (Claude Code exception: a subagent worker may spawn its own subagents to finish its lane, but still must not manage other lanes or the control plane.)
- Do not delegate portfolio triage, thread creation, or worker management to another worker.
- Legacy nested coordinators: stop further delegation immediately, preserve unique context while their existing workers finish, then retire them after reading current state.

## Decision-Ready Queue Rule

Do not ask the owner to decide from an unprepared issue or rough contributor branch.

- Existing PR: inspect, reproduce, rewrite/fix as needed, add tests/docs/changelog, run live proof and autoreview, push the final candidate, and get required CI green. Ask only when the PR is mergeable or the remaining blocker cannot be solved autonomously.
- Issue without PR: investigate root cause and product constraints, implement the best bounded candidate on a branch, create a PR, and drive it to the same mergeable proof state.
- Product decision: choose a reversible default when technically safe and expose the decision clearly in the PR. Prepare alternatives in the PR description when useful.
- Access or live-proof blocker: finish code, tests, docs, review, and CI first. Ask only for the exact remaining credential, account action, hardware interaction, waiver, or land/delete decision.
- Rejection candidate: produce concrete research and proof. When a code candidate would clarify the tradeoff, prepare the PR anyway; otherwise update the issue with the evidence needed for an owner close/keep decision.

The normal owner interaction should be one of: land the prepared PR, delete/close it, provide one exact access step, or choose between clearly documented alternatives.

## Owner Decision Briefs

Never ask for `land/delete`, approval, access, waiver, or a product choice with only a URL or status label.

Immediately before asking, refresh the item and worker state. Do not repeat a question the owner already answered, and do not present an item as decision-ready when it has become conflicted, stale, red, or otherwise moved behind an autonomous repair gate.

Every owner decision request must include:

- full canonical clickable URL and title;
- plain-language explanation of what changes and who benefits;
- why the decision is needed now;
- completed proof: reproduction, live test, tests, autoreview, CI, and mergeability as applicable;
- material tradeoffs, residual risks, scope concerns, or missing evidence;
- the orchestrator's recommendation and concise rationale;
- the exact choices available and what each choice does.

When several decisions are grouped, give each item its own brief. Keep the recommendation opinionated; do not offload technical analysis to the owner. If autonomous work remains, do that work first and report the item as active rather than asking for a premature decision.

## Monitoring Protocol

Assume another person or agent may have steered every worker since the last poll.

Before sending any worker message:

1. Read the worker's latest current state, including its newest user/delegation messages and active turn.
2. Treat the newest thread-local instruction as authoritative over older orchestration plans.
3. Refresh the repository/item state through RepoBar first when it can answer the question quickly: queue counts, recent activity, CI summaries, open issues/PRs, and local checkout status. For every PR the worker owns or recently opened, then refresh GitHub's authoritative state including checks, mergeability, top-level comments, submitted reviews, and unresolved inline review threads. Do not rely on `gh pr view` alone for review comments; query review threads explicitly through GraphQL or the GitHub API.
4. Determine whether the worker is actively progressing, blocked, completed, or idle.
5. Send nothing when an active worker has a coherent plan and is making progress.

Intervene only when evidence shows one of:

- the worker explicitly requests coordination or reports a blocker;
- the worker has completed or run out of autonomous work and needs a next queue item;
- a PR has new requested changes, unresolved inline review comments, or owner review feedback the worker has not acknowledged;
- repeated failures show no progress and a concrete correction is available;
- wrong repository/item, unauthorized mutation, destructive action, security risk, release-gate violation, or direct conflict with the owner's latest instruction;
- implementation has grossly diverged from the accepted task, not merely chosen a different reasonable design.

Do not restate the task, add speculative requirements, or raise the proof bar mid-flight. Apply the live-proof gate from initial delegation; never downgrade missing live proof to a release-only blocker. Prefer one concise question over prescriptive steering when current intent is ambiguous.

Never interrupt, archive, rename, duplicate, or replace a worker without first reading its current state. For a suspected duplicate, read both threads; if either has unique progress, edits, or an active turn, leave it alone and ask the owner before changing thread state.

## Thread Naming

- Rename/relabel a worker whenever giving it a new task or materially changing its assignment.
- Format every worker title as `<Project>: <short current task>`.
- Read the latest state and newest thread-local instructions before renaming.
- Keep the title specific to current work; replace stale original-task titles.
- Polling alone does not justify a rename.

## Persistent Log

- This root orchestrator owns `~/oss-orchestrator.md`; workers do not edit it.
- Append dated, high-level entries for meaningful actions and decisions: policy/skill/automation changes, worker creation or reassignment, queue decisions, lands, closes, releases, and exact blockers.
- Include full canonical issue/PR URLs when relevant.
- Never record secrets or routine polling.

## Idle Thread Closeout

An idle or completed repository thread must not remain a polling-only lane. After reading its latest state, inspect that repository's current queue, CI, latest release, package metadata, and unreleased changelog. Then do exactly one:

1. Assign the next autonomous issue or PR to the same repository thread.
2. Prepare each remaining non-autonomous item to the decision-ready boundary, then ask the owner a concise concrete question: land/delete, choose a documented alternative, provide exact access, or grant a live-proof waiver.
3. When the effective issue and PR queues are empty, execute the authorized patch or minor release after all release gates pass.
4. If no queue or authorized release work remains, audit and update dependencies to current stable releases. Delegate this as normal repository work: inspect upstream changes and package health, honor repository-specific stabilization policies, avoid prerelease-only upgrades unless already adopted, preserve the repository's package manager, add compatibility fixes/tests when needed, run exact built/live proof, autoreview, and required CI, then prepare or land the update within granted permissions.

Do not keep completed threads merely to satisfy a lane count. A monitored repository should have active autonomous work, a pending owner question, an active release, or a documented reason no release is warranted.

Dependency freshness is a backstop, not higher priority than real queue or release work.

## Authorization

Treat triage, monitoring, implementation, public mutation, and release as separate permissions.

- Queue analysis or monitoring does not authorize edits.
- Delegation or parallel-worker creation requires explicit owner authorization.
- Implementation permission authorizes local changes and verification only unless the owner also authorizes push/PR updates.
- Push permission does not imply merge or close permission.
- CI rerun and CI-fix permission must be explicit; a push alone does not authorize additional repair commits or workflow mutations.
- Merge/close permission must be explicit for the affected work.
- Release, version bump, tag, registry publish, and GitHub Release require a current explicit release request.
- Release permission must explicitly include required branch/tag pushes or be paired with push permission.

Record the granted permissions in each worker prompt. Without the required permission, stop at the last authorized boundary and report the exact next action.

## Credential Access

Maintainer credentials currently live in `.env` files (per-project) or exported environment variables. Before reporting a credential blocker:

1. Check the exact expected environment variable; use it only when already exported.
2. Look for a project `.env` (or `.env.local`) and read only the exact key needed via the project's normal loader. Never print secret values or dump the whole file.
3. Keep credential discovery and use inside the worker that needs the secret. Report only presence, access path, and the exact missing item; never send credential values between threads.
4. Ask the owner only after the expected env var is unset and no project `.env` provides the key.

If 1Password (CLI `op` or service accounts) is set up later, prefer it over plaintext `.env`: read the service-specific auth skill, use scoped `op run`/`op inject`, never broadly enumerate or print secrets, and fall back to `.env` only when 1Password access is unavailable.

## Worker Contract

Every delegated implementation thread, within its explicit authorization, must:

- read the full issue/PR discussion, repo instructions, docs, and relevant code;
- before treating any PR as ready, inspect top-level comments, submitted reviews, and unresolved inline review threads;
- when review feedback is valid, fix it, push the fix, reply on the exact review thread with what changed, resolve the thread through GitHub, and verify the unresolved-thread list is empty. A follow-up commit by itself is not enough.
- when review feedback is invalid or intentionally not addressed, reply on the exact thread with concrete evidence or the decision, resolve only if no owner decision is needed, and leave `needs-human` threads open with the exact decision required.
- when an issue has no PR, create one after implementing the best bounded candidate;
- reproduce or establish root cause before accepting an existing patch;
- rewrite when a cleaner bounded design is available;
- add regression coverage when appropriate;
- run focused and full tests, then live/end-to-end proof against the real affected boundary before landing;
- run `autoreview` until no accepted/actionable findings remain;
- when push is authorized, push the authorized changes;
- when CI rerun/fix is authorized, rerun required checks and repair failures until green;
- when CI rerun/fix is not authorized and checks fail, stop with the exact failure and requested permission;
- when merge/close is authorized, merge or close the queue item with an exact proof comment;
- after authorized landing, return to the repository's selected integration branch, pull `--ff-only`, and verify a clean worktree.

Prefer repairing the contributor PR. Preserve contributor credit and follow the workspace PR rules.
When landing is not yet authorized, stop only after the branch is pushed, the PR targets the repository's selected integration branch, the PR is mergeable, required CI is green, live proof is recorded, and the exact owner decision is stated.

Before creating or judging any PR, apply `github-project-triage`'s Integration
Branch Gate. Do not assume `main` is the right base merely because it is the
GitHub default branch. Repositories may use `develop` as the staging/development
branch and reserve `main` for production releases; in those repos, workers must
create worktrees from `develop`, open PRs against `develop`, return to clean
`develop`, and report any PR that accidentally targets `main` as a readiness
blocker until it is retargeted or intentionally approved.

(Codex workers must not subdelegate; Claude Code subagents may spawn their own subagents to complete this contract.)

## Live Proof Gate

Live proof is a pre-land requirement, not optional polish.

- Test the exact final candidate commit through the changed user path using the real built/installed artifact and real service, account, device, OS, or external provider as applicable.
- For external integrations, authenticated live calls are required. Docs, mocks, fixtures, protocol captures, route-existence checks, and CI supplement live proof; they do not replace it.
- For macOS UI behavior, use the `peekaboo` skill for screenshots / UI proof; for web UI, use the `agent-browser` skill.
- Redact secrets and private user data while retaining concrete evidence such as command, behavior, response class, artifact hash, or observed state transition.
- If credentials, account state, hardware, platform access, or a safe live target are unavailable, finish all autonomous code, tests, review, and CI work, then stop before merge/close. Ask for the exact access, an explicit item-specific waiver, or a reject/close decision.
- Never infer a live-proof waiver from merge permission, release permission, prior contributor evidence, or confidence in mocks.
- Re-run live proof after any fix that changes the relevant runtime path.
- Pure docs, metadata, CI, or test-only changes with no runtime boundary may use the closest built-artifact or workflow proof; state why no external live boundary applies.

Record live evidence or the owner's explicit waiver in the landing proof comment.

## Release Gate

Compute the effective queue immediately before release:

```text
effective issues = open issues - explicitly ignored issues
effective PRs    = open PRs - explicitly ignored PRs
```

Release only when all are true:

- the owner has explicitly requested this release or authorized release execution for the repository;
- effective issue count is zero;
- effective PR count is zero;
- every ignored item is explicitly named in the current owner instructions;
- required CI is green for the exact commit and branch/tag candidate being released;
- all user-facing runtime changes in the release have required live proof, unless the owner explicitly waives that proof for the release;
- release checkout is clean, on the expected branch, and fast-forward current;
- unreleased changes justify a release and the target version follows SemVer/project convention.

Recheck the GitHub queue and CI immediately before tagging or publishing. Abort if either gate changes.

Never silently exclude an item. In release reporting, list ignored items and the owner instruction that exempted them.

## Release Execution

Use the repository's release docs and matching skill:

- npm packages: use `npm`;
- macOS apps: use `release-mac-app`;
- iOS / Expo apps: use `release-ios-app`;
- other projects: use established repo scripts/workflows.

Before release:

- reconcile changelog history with existing tags/releases;
- default to patch for compatible fixes, maintenance, refactors, docs, CI, and small behavior improvements;
- select minor only for substantial additive functionality, a meaningful new feature set, or a new backward-compatible public API;
- never use minor merely because several fixes accumulated; major requires explicit approval;
- run full release checks and review release-only edits.

After publishing, verify the actual release:

- Git tag and GitHub Release exist;
- release notes contain the complete changelog section;
- expected artifacts/install path work;
- npm packages show version, dist-tag, tarball, integrity, and publish time;
- release body links registry/artifact/integrity and CI proof when applicable.

Then open the next patch `Unreleased` section. Commit and push the closeout only when those mutations are authorized; otherwise leave the verified local closeout ready and report the exact permission needed. After an authorized push, pull `--ff-only` and finish on the selected release branch with a clean worktree.

## Reporting

Keep one compact cross-repo ledger:

- `Active`: repo, item URL, worker, current phase.
- `Intervened`: exact risk and instruction sent.
- `Needs owner`: exact decision/access required; no vague "needs review".
- `Ignored`: exact item and owner-granted exception.
- `Released`: version, tag/registry verification, closeout commit.
- `Ready next`: effective queue empty, CI green, recommended patch/minor version and rationale.

Omit archived and owner-suppressed repositories entirely. Do not list them as ignored, blocked, stale, or available work.

Whenever mentioning an issue or PR in any owner report, decision question, worker message, or status update, print its full canonical clickable URL. Never use only a repository-local number such as `#123`; include `https://github.com/OWNER/REPO/issues/123` or `https://github.com/OWNER/REPO/pull/123`.

For `Needs owner`, use the Owner Decision Brief format. Never emit a bare URL plus `land/delete`.

Report meaningful changes, not routine polling. Maintain a heartbeat automation when the user asks to keep monitoring.
