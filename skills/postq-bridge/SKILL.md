---
name: postq-bridge
description: "Bridge Content Machine output into Post Queue. Use whenever an agent needs to inspect PostQ context, generate or select Content Machine posts, create PostQ drafts, or schedule Walkmon TikTok posts through PostQ while preserving TikTok inbox-draft/manual-finish delivery."
---

# PostQ Bridge

Use this skill to move approved Content Machine artifacts into Post Queue without browser automation. Content Machine owns creative generation and `status.json`; Post Queue owns media uploads, drafts, schedules, Post Targets, notifications, and publishing history.

The MVP proving path is Walkmon TikTok video:

1. Inspect PostQ context.
2. Inspect Content Machine context.
3. Generate or select approved Walkmon video output.
4. Upload the MP4 to PostQ.
5. Create a PostQ draft.
6. Stop for approval.
7. Schedule TikTok as an inbox draft.

Direct TikTok API publishing is outside this skill's default path. Prefer TikTok inbox draft delivery so the user can finish in the TikTok app, add native text/audio, and avoid the engagement downside of server-side direct publishing.

## Repos

Work from explicit repo roots:

- Content Machine: `/Users/ossianhempel/Developer/content-machine`
- Post Queue: `/Users/ossianhempel/Developer/post-queue`
- Skill source: `/Users/ossianhempel/Developer/agent-scripts/skills/postq-bridge`

When changing this skill, edit only the canonical source under `agent-scripts/skills/postq-bridge`. Do not edit generated runtime copies under app repos.

## PostQ Auth

Use the existing `postq` config resolution first. If credentials are missing, use the Post Queue 1Password item without printing secrets:

```bash
export POSTQUEUE_API_URL=http://localhost:3000
export POSTQUEUE_API_TOKEN="$(op read op://Development/PostQ/postq-token)"
```

Prefer environment/config over `--token` so bearer tokens do not land in shell history. Never print `.env`, token values, OAuth payloads, or provider responses containing secrets.

Smoke auth from the Post Queue repo:

```bash
pnpm --silent postq -- auth status --json
```

## Context Intake

Read PostQ state before creating anything:

```bash
pnpm --silent postq -- auth status --json
pnpm --silent postq -- accounts list --json
pnpm --silent postq -- drafts list --json
pnpm --silent postq -- posts list --status queued --json
pnpm --silent postq -- posts list --status published --json
```

Read Content Machine state:

```bash
npx tsx src/cli.ts status --app walkmon
```

Use the context to avoid duplicate drafts or conflicting schedules. If there is more than one connected TikTok account, ask the user which account to use before draft creation. If exactly one connected TikTok account exists, use it but include the account id and username in the draft summary before scheduling.

## Generate Or Select Content

Only hand off approved Content Machine output. For Walkmon, approved output normally means:

- `output/<set>/<set>.mp4`
- `output/<set>/post.md`
- `output/<set>/status.json`
- `output/<set>/review.md` when the `content-review` loop generated it

If no approved output is available, run the repo-local Content Machine review loop instead of drafting directly:

```text
/content-review
```

Walkmon mode drafts hook/reveal/caption copy, validates, reviews, renders, and writes `review.md`. Do not use `assemble-video` unless the user explicitly asks for the unvetted fast path.

## Parse Content Machine Copy

Use the bundled parser so captions and on-video text are not hand-copied from Markdown:

```bash
node /Users/ossianhempel/Developer/agent-scripts/skills/postq-bridge/scripts/parse-content-machine-post.mjs \
  /Users/ossianhempel/Developer/content-machine/output/<set>/post.md
```

It emits:

```json
{
  "title": "<set>",
  "caption": "Caption text\n\n#hashtags",
  "onVideoText": [
    { "label": "Text 01 (video clip)", "text": "..." },
    { "label": "Text 02 (still image)", "text": "..." }
  ]
}
```

Keep the on-video text in the final summary. It is not uploaded as burned-in text; the user adds it natively in TikTok/Instagram.

## Create The PostQ Draft

Upload the generated MP4 from the Post Queue repo:

```bash
pnpm --silent postq -- media upload /Users/ossianhempel/Developer/content-machine/output/<set>/<set>.mp4 --json
```

Create the draft using JSON stdin, not command-line caption flags:

```bash
printf '%s\n' '{
  "title": "<set>",
  "caption": "Caption text\n\n#hashtags",
  "mediaAssetIds": ["<mediaAssetId>"]
}' | pnpm --silent postq -- posts create --from - --json
```

Draft writes are allowed once the Content Machine output is approved. Do not schedule yet. Report:

- Content Machine output folder
- media asset id
- PostQ post id
- parsed caption
- on-video text blocks
- selected TikTok account candidate

## Schedule After Approval

Scheduling is publishing-affecting. Stop and get explicit user approval for the account and time before running the real schedule command.

Validate payload shape with `--dry-run` when useful:

```bash
printf '%s\n' '{
  "targets": [
    {
      "accountId": "<tiktokAccountId>",
      "provider": "tiktok",
      "format": "post",
      "scheduledFor": "2026-06-26T08:00:00Z",
      "payload": { "tiktokDeliveryMode": "draft" }
    }
  ]
}' | pnpm --silent postq -- posts schedule <postId> --from - --dry-run --yes --json
```

Run the real schedule only after approval:

```bash
printf '%s\n' '{
  "targets": [
    {
      "accountId": "<tiktokAccountId>",
      "provider": "tiktok",
      "format": "post",
      "scheduledFor": "2026-06-26T08:00:00Z",
      "payload": { "tiktokDeliveryMode": "draft" }
    }
  ]
}' | pnpm --silent postq -- posts schedule <postId> --from - --yes --json
```

Important: do **not** set `manual: true` for TikTok inbox drafts. In PostQ, manual targets do not get `nextAttemptAt`, so the scheduler will not upload the draft to TikTok. TikTok inbox draft delivery is a normal scheduled target with `payload.tiktokDeliveryMode: "draft"`.

## Status Honesty

Do not run `content-machine mark-posted` after draft creation or after scheduling. The Content Machine set is only posted when the user completes the post inside TikTok or explicitly confirms completion.

After confirmed native publishing:

```bash
npx tsx src/cli.ts mark-posted -s <set> -p tiktok --app walkmon
```

## Final Summary

Always include:

- Content Machine set path.
- PostQ media asset id.
- PostQ post id.
- TikTok account id/username.
- Scheduled time and timezone.
- Delivery mode: `tiktokDeliveryMode: "draft"`.
- On-video text blocks the user still needs to add natively.
- Whether Content Machine `status.json` remains pending or was marked posted after confirmation.

## Verification

When editing this skill or helper, run from `agent-scripts`:

```bash
node --test skills/postq-bridge/scripts/parse-content-machine-post.test.mjs
python3 - <<'PY'
from pathlib import Path
import yaml
body = Path("skills/postq-bridge/SKILL.md").read_text()
front = body.split("---", 2)[1]
yaml.safe_load(front)
PY
scripts/skills-audit.py scan
```

When using the bridge, PostQ read-context smoke checks are safe. Media upload, draft creation, and real scheduling mutate user data; schedule only after explicit approval.
