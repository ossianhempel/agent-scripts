---
name: post-queue-cli
description: "Operate the Post Queue repo command surface effectively. Use when an agent needs to run local dev servers, local Supabase/Drizzle workflows, scheduler ticks or loops, cron-runner checks, tests, lint, typecheck, or database migrations in this repo."
---

# Post Queue CLI

## Purpose

Use this skill to choose and run the right repo command without rediscovering the scripts in `package.json`.

Post Queue does not expose a standalone binary. Its command surface is the npm scripts plus a few Node/Bash helpers under `scripts/` and `cron-runner/`.

## First Steps

1. Work from the repo root: `/Users/ossianhempel/Developer/post-queue`.
2. Read `AGENTS.md` before changing code, and read narrower `AGENTS.md` files when entering scoped folders such as `src/db/`.
3. Run `npm run docs:list` when starting substantive work, then read the docs whose topic matches the task.
4. Check current scripts before relying on this skill if `package.json` changed recently:
   ```bash
   node -e "const p=require('./package.json'); console.log(JSON.stringify(p.scripts,null,2))"
   ```

## Secrets

Use the 1Password item `op://Development/Post Queue/...` for PostQueue secrets. The item should be tagged `repo:post-queue`, `project:post-queue`, and `environment:production` so agents do not confuse it with other repo secrets.

Recommended sections/fields:

- `PostQueue production`: `APP_URL`, `DATABASE_URL`, `INSTAGRAM_CLIENT_ID`, `INSTAGRAM_CLIENT_SECRET`, `INSTAGRAM_REDIRECT_URI`, `UPLOADTHING_TOKEN`, `UPLOADTHING_SECRET`, `X_CLIENT_ID`, `X_CLIENT_SECRET`, `X_REDIRECT_URI`, `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`, `CRON_SECRET`.
- `PostQueue cron runner`: `APP_URL`, `CRON_SECRET`, `GATE_DATABASE_URL`, `GATE_MODE`, `INTERVAL_SEC`, `LIMIT`.
- `PostQueue legacy Supabase env`: `SUPABASE_DB_URL`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY`, `SUPABASE_SERVICE_ROLE_KEY`. These are legacy/local compatibility fields unless current code starts importing the Supabase helpers again.
- `PostQueue local dev`: local-only values such as `DEV_SEED_CLERK_ID`.

Production app data currently uses Coolify/self-hosted Postgres via `DATABASE_URL`; do not treat `SUPABASE_DB_URL` as the primary production database unless the code or deployment changes. If `TOKEN_ENCRYPTION_KEY` is configured in production, store it under `PostQueue production` and never put it in the cron-runner environment.

## Command Map

### Local App

- Start the normal HTTPS dev server and ensure local Supabase is ready:
  ```bash
  npm run dev
  ```
- Start an HTTP dev server without the Supabase bootstrap:
  ```bash
  npm run dev:http
  ```
- Start the app and scheduler loop together:
  ```bash
  npm run dev:with-scheduler
  ```

`npm run dev` calls `scripts/ensure-local-supabase.sh`, which requires Docker and the Supabase CLI. It starts local Supabase when needed, applies Drizzle migrations, and runs idempotent seeds.

Use `npm run dev:http` when another process already prepared the DB or when a scheduler helper needs `--http`.

### Verification

- Typecheck after significant TypeScript changes:
  ```bash
  npm run typecheck
  ```
- Lint:
  ```bash
  npm run lint
  ```
- Unit/integration test suite:
  ```bash
  npm run test
  ```
- Scheduler integration test with local Supabase bootstrap:
  ```bash
  npm run test:integration
  ```
- CI-shaped scheduler integration test, assuming DB state is already prepared:
  ```bash
  npm run test:integration:ci
  ```
- Production build:
  ```bash
  npm run build
  ```

Prefer the narrowest meaningful check while iterating. Before commits or broad changes, run the relevant full gate, usually `npm run typecheck`, `npm run lint`, and affected tests.

### Local Database

- Start local Supabase:
  ```bash
  npm run db:local:start
  ```
- Stop local Supabase:
  ```bash
  npm run db:local:stop
  ```
- Reset local Supabase, apply Drizzle migrations, and seed:
  ```bash
  npm run db:local:reset
  ```
- Repo reset helper:
  ```bash
  npm run reset
  ```
- Generate Drizzle migrations after editing `src/db/schema/**`:
  ```bash
  npm run db:generate
  ```
- Apply migrations to the local DB:
  ```bash
  DATABASE_URL=${SUPABASE_LOCAL_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres} npm run db:migrate:local
  ```
- Open Drizzle Studio:
  ```bash
  npm run db:studio
  ```

For DB work, also read `src/db/AGENTS.md`. Source of truth is `src/db/schema/**`; treat `src/db/migrations/**` and especially `src/db/migrations/meta/**` as generated output.

`db:local:reset`, `supabase:reset`, and `npm run reset` wipe local data. Do not run production migrations unless the user explicitly asks or the release workflow requires it.

### Production Database

- Apply migrations to the production database:
  ```bash
  npm run db:migrate:prod
  ```

Only run this after confirming `DATABASE_URL` points at the intended production database. Do not print connection strings. If secrets are needed, use the `one-password` skill or an existing non-printing env wrapper.

If production migration fails because base schema objects already exist but Drizzle history is missing, read `docs/scheduler/how-the-scheduler-runs.md` and the README database section before making any baseline changes.

### Scheduler

Read these before scheduler changes or ops:

- `docs/scheduler/overview.md`
- `docs/scheduler/how-the-scheduler-runs.md`
- `src/app/api/cron/publish/route.ts`
- `src/lib/scheduler/runTick.ts`

The scheduler is a polling worker. It claims due `post_targets` rows, processes each target, records `publish_attempts`, and recomputes parent post status. Overlapping ticks are intended to be safe because claiming is database-backed.

Required local env:

- `CRON_SECRET` in `.env.local`

Run one local tick against the default HTTPS dev server:
```bash
npm run scheduler:tick
```

Run one tick against local HTTP:
```bash
npm run scheduler:tick -- --http
```

Run one tick against an explicit app URL:
```bash
npm run scheduler:tick -- --url http://localhost:3000 --limit 25
```

Run the polling loop:
```bash
npm run scheduler:loop -- --interval 60 --limit 25
```

Scheduler helper details:

- `scheduler:tick` loads `.env.local`, requires `CRON_SECRET`, and POSTs `/api/cron/publish` with `Authorization: Bearer`.
- `scheduler:loop` repeats the same POST forever and logs claimed/succeeded/failed/retried counts.
- `--limit` is clamped to `1..100`.
- `--http` targets `http://localhost:3000`; HTTPS localhost disables TLS verification inside the helper.

Prefer header auth and POST. If docs disagree about query-string or GET fallback behavior, trust the current route code and `docs/scheduler/how-the-scheduler-runs.md` over older README snippets.

### Cron Runner

The production polling service lives in `cron-runner/`.

Relevant files:

- `cron-runner/run.js`
- `cron-runner/Dockerfile`
- `cron-runner/docker-compose.yml`
- `docs/scheduler/how-the-scheduler-runs.md`

Runner env should be narrow:

- `APP_URL`
- `CRON_SECRET`
- optional gate settings such as `GATE_MODE`, `GATE_DATABASE_URL`, `INTERVAL_SEC`, `LIMIT`, `MAINTENANCE_TICK_MS`

The runner must not carry `TOKEN_ENCRYPTION_KEY`, platform client secrets, or identity hash peppers. Use a least-privilege gate DB role for `GATE_DATABASE_URL` when enabling Postgres gating.

## Common Workflows

### Make a Schema Change

1. Read `src/db/AGENTS.md`.
2. Edit `src/db/schema/**`.
3. Generate migrations:
   ```bash
   npm run db:generate
   ```
4. Apply to local:
   ```bash
   DATABASE_URL=${SUPABASE_LOCAL_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres} npm run db:migrate:local
   ```
5. Run focused tests plus `npm run typecheck`.

### Verify Scheduler Behavior Locally

1. Ensure `.env.local` has `CRON_SECRET`.
2. Start the app:
   ```bash
   npm run dev
   ```
3. In another terminal, run:
   ```bash
   npm run scheduler:tick -- --limit 25
   ```
4. Inspect the JSON response and relevant DB rows or UI state.

Use `SCHEDULER_DRY_RUN=true` for tests that should avoid real provider publishing, matching the integration test setup.

### Run App Plus Scheduler While Testing Queued Posts

```bash
npm run dev:with-scheduler
```

Optional tuning:
```bash
SCHEDULER_INTERVAL_SEC=30 SCHEDULER_LIMIT=10 npm run dev:with-scheduler
```

For HTTP local dev:
```bash
SCHEDULER_HTTP=true npm run dev:with-scheduler
```

## Safety Rules

- Never print `.env.local`, `DATABASE_URL`, `CRON_SECRET`, OAuth secrets, tokens, or token encryption keys.
- Do not run `npm run db:migrate:prod` unless the task explicitly calls for a production migration and the target DB is confirmed.
- Treat scheduler ticks as potentially publishing real queued content unless the environment is local/test or `SCHEDULER_DRY_RUN=true` is explicitly part of the path.
- Do not hand-edit generated Drizzle migration metadata.
- If command output references account tokens, OAuth payloads, or provider responses, summarize safely and redact sensitive fields.

## Troubleshooting Pointers

- Docker or Supabase CLI missing: local DB bootstrap scripts will fail before the app starts.
- Local Postgres TLS errors: local Supabase should use non-SSL localhost URLs; see the README local troubleshooting section.
- `scheduler:tick` says `CRON_SECRET is not set`: add it to `.env.local` or run through an env wrapper without printing the value.
- `tick failed: 401`: `CRON_SECRET` mismatch or the app deployment/runtime lacks the env var.
- Cron runner logs `Database schema is missing scheduler columns`: apply the latest migrations to the same DB used by the app and gate query.
- `claimed=0` forever: no `post_targets` are due, `next_attempt_at` is in the future, or scheduling did not create target rows.
