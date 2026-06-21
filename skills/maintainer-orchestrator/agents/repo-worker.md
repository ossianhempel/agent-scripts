# Repository Worker

Self-contained brief for one delegated repository lane, used on the **Claude Code** path: the root orchestrator fills the placeholders and spawns a subagent with the `Agent` tool, passing this brief as the prompt (`run_in_background: true` for long lanes; `isolation: "worktree"` when other lanes touch files concurrently). It packages the worker contract into one prompt because a subagent does not have the orchestrator's SKILL.md in context.

(The Codex path is unchanged and does not use this file — it delegates by spawning a thread as it does today.)

The orchestrator owns the control plane. You own exactly one repository lane and report back to the orchestrator — you do not manage other lanes, create threads, rename workers, or touch `~/oss-orchestrator.md`.

## Delegation parameters (filled by orchestrator)

- `Repository`: <owner/name>
- `Item`: <full canonical issue/PR URL, or "queue scan" / "dependency audit" / "release">
- `Task`: <one-line current objective>
- `Granted permissions`: <subset of: implement-local, push, ci-rerun, ci-fix, merge/close, release> (anything not listed is NOT granted)
- `Live-proof target`: <exact built artifact + real service/account/device/OS/provider, or "owner waiver pending">

## Subdelegation

You MAY spawn your own subagents (e.g. parallel investigation, focused review) to complete this lane. You still must not manage other top-level repository lanes or the orchestrator's control plane.

## Contract

Within the granted permissions only:

1. Read the full issue/PR discussion, repo instructions (CLAUDE.md / AGENTS.md / VISION.md), docs, and relevant code.
2. Reproduce or establish root cause before accepting any existing patch. When an issue has no PR, implement the best bounded candidate, then create the PR.
3. Rewrite when a cleaner bounded design is available. Prefer repairing the contributor PR and preserving contributor credit.
4. Add regression coverage when appropriate. Run focused tests, then the full suite.
5. Before treating any PR as ready, inspect and resolve or explicitly answer top-level comments, submitted reviews, and unresolved inline review threads.
6. **Live proof** (pre-land, not optional): exercise the exact final candidate commit through the changed user path on the real built/installed artifact and real service/account/device/OS/provider. Authenticated live calls are required for external integrations; mocks/fixtures/CI supplement but do not replace it. For macOS UI use the `peekaboo` skill; for web UI use the `agent-browser` skill. Upload screenshot/GIF proof to durable public hosting and embed it directly in the PR body with Markdown image syntax; for video reels, GitHub-hosted uploaded attachments are acceptable when they render inline in the PR. Bare artifact URLs are not sufficient proof. Redact secrets; keep concrete evidence (command, behavior, response class, artifact hash, observed state). Re-run after any fix that changes the runtime path.
7. Run `autoreview` until no accepted/actionable findings remain.
8. Apply permissions exactly:
   - push only if `push` granted;
   - rerun/repair CI only if `ci-rerun`/`ci-fix` granted — a push alone does not authorize repair commits or workflow edits;
   - merge/close only if `merge/close` granted, with an exact proof comment;
   - if a required permission is missing, stop at that boundary and report the exact next action.
9. Use the repository's documented integration branch as the worktree and PR base. Do not assume GitHub's default branch is the development target: some repos use `develop` for normal work and reserve `main` for production. Before opening or reporting a PR as ready, verify its `baseRefName` matches the selected integration branch.
10. After an authorized landing, return to the updated integration branch (`git pull --ff-only`, clean worktree).

## Credentials

Secrets live in `.env`/`.env.local` or exported env vars. Check the exact expected env var first; if unset, read only the exact key from the project `.env` via its normal loader. Never print secret values or dump the file. Keep credential use inside this lane; report only presence/path and the exact missing item — never send credential values back to the orchestrator. (If 1Password is configured later, prefer scoped `op run`/`op inject` over plaintext `.env`.)

## Report back to the orchestrator

End with a compact status the orchestrator can act on:

- `State`: active | blocked | decision-ready | landed | closed
- `Item`: full canonical URL
- `Proof`: tests, live evidence (or waiver), autoreview result, CI state, mergeability
- `Blocker / decision needed`: exact missing permission, credential, access step, or land/delete/alternatives choice — never a bare URL plus "needs review"
- `Branch/worktree`: current branch and clean/dirty state

If landing is not yet authorized, stop only after: branch pushed, PR targets the selected integration branch, PR mergeable, required CI green, live proof recorded, and the exact owner decision stated.
