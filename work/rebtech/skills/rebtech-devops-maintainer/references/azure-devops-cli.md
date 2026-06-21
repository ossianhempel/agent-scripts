# Azure DevOps CLI cookbook (verified against dev.azure.com/rebtech)

Org `https://dev.azure.com/rebtech`. Defaults already set (`az devops configure -l`):
`organization=https://dev.azure.com/rebtech`, `project=RAID`. Auth is local interactive `az login`
(as `ossian.hempel@rebtech.se`); if a token has expired, the only fix is re-running `az login` once.
No PAT is configured and none is needed for local runs.

Two projects: **RAID** and **Assets**. Work-item states: **New -> Active -> Closed** (a few legacy
"Resolved"). The `azure-devops` extension is `az` 2.81 / ext 1.0.2.

## What is first-class in the CLI

| Operation | Command |
|---|---|
| Query work items (WIQL) | `az boards query --project <P> --wiql "..."` |
| Show a work item | `az boards work-item show --id <id> -o json` |
| Claim a work item (granted) | `az boards work-item update --id <id> --state Active --assigned-to "ossian.hempel@rebtech.se" --discussion "<status>"` |
| Status comment on the board (granted, non-closing) | `az boards work-item update --id <id> --discussion "<status / PR url>"` |
| Close/resolve a work item | NEVER (owner action after merge) — no command, by policy |
| List active PRs | `az repos pr list --project <P> --repository <repo> --status active -o json` |
| Show a PR | `az repos pr show --id <pr> -o json` |
| Create a PR | `az repos pr create --project <P> --repository <repo> --source-branch <b> --target-branch <int> --title "..." --work-items <id> --description "..."` |
| Link/list work items on a PR | `az repos pr work-item add/list --id <pr> --work-items <id>` (non-closing) |
| Add/list reviewers | `az repos pr reviewer add/list --id <pr>` |
| List PR policy evaluations (gate status) | `az repos pr policy list --id <pr> -o json` |
| List branch policies | `az repos policy list --project <P> --repository-id <id> --branch main -o json` |
| List pipelines / runs | `az pipelines list --project <P> -o table` / `az pipelines runs list --project <P> -o table` |

Notes:
- Dotted field names must be quoted inside JMESPath: `--query 'fields."System.Title"'`.
- Tags: `[System.Tags] CONTAINS 'x'`. Never `[System.Tags] <> ''` (rejected on long-text fields).
- `az repos policy list -o table` shows `type.displayName` as null — use `-o json` to read policy type names.
- CI / PR-validation status is fully readable: filter `az pipelines runs list` to `sourceBranch == refs/pull/<pr>/merge`.

## Branch creation is NOT first-class — use git

```bash
cd ~/rebtech/<repo>
git fetch origin --quiet
git switch -c feature/<id>-<slug> origin/<integration>
# ... make changes, commit ...
git push -u origin feature/<id>-<slug>      # push the FEATURE branch only
```

## PR review threads / comments are REST-only (the CLI gap)

There is no `az repos pr` verb for review threads. Use `az devops invoke`.

```bash
# READ all threads + comments on a PR (read-only, always allowed)
az devops invoke --org https://dev.azure.com/rebtech \
  --area git --resource pullRequestThreads \
  --route-parameters project=<P> repositoryId=<repoId> pullRequestId=<pr> \
  --http-method GET --api-version 7.1 -o json
# Each thread carries comments[] + status (active|fixed|closed|wontFix|pending) + id.

# POST a comment / reply  -> WRITE, requires explicit grant (public comment boundary)
# new thread:   POST .../pullRequestThreads        body: {"comments":[{"content":"...","commentType":1}],"status":1}
# reply:        POST .../pullRequestThreads/{tid}/comments   body: {"content":"...","parentCommentId":<n>}

# RESOLVE a thread -> WRITE, requires explicit grant
# PATCH .../pullRequestThreads/{tid}   body: {"status":"closed"}  (or "fixed")
```

Resolve `<repoId>` once with `az repos show --project <P> --repository <repo> --query id -o tsv`.

## Proof image storage = PR attachments (decided)

Upload after the PR exists, then embed the returned URL in the PR description markdown. `az devops invoke`
is awkward for binary bodies, so use a bearer token + `curl`. The Azure DevOps resource ID is constant:
`499b84ac-1321-427f-aa17-267ca6975798`.

```bash
TOKEN=$(az account get-access-token \
  --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv)

curl -sS -X POST \
  "https://dev.azure.com/rebtech/<P>/_apis/git/repositories/<repoId>/pullRequests/<pr>/attachments/<fileName>.png?api-version=7.1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @/path/to/proof.png
# Response JSON contains "url": embed it in the PR description as ![proof](<url>) and verify it renders.
```

If attachment upload is blocked (403/policy): fall back to committing the image under
`docs/proof/<workitem>/` in the same PR, or reference the local path + a textual description. Never omit.

## Quick scope probes

```bash
az repos list --project RAID   --query '[].name' -o tsv
az repos list --project Assets --query '[].name' -o tsv
az devops configure -l            # confirm org/project defaults
az account show                   # confirm the signed-in user
```
