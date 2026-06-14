# Convex CLI — agent mode

## Why `convex dev` is special

`npx convex dev`:

1. May open a browser for OAuth on first run
2. Runs indefinitely, watching the filesystem
3. Tails logs by default (`--tail-logs pause-on-deploy`)

Agents should use **`npx convex dev --once`** for a single push/codegen cycle, or ask the user to run `npx convex dev` in their terminal for the full loop.

## Headless / sandbox development

When interactive login is impossible (CI, cloud agent, headless VM):

```sh
CONVEX_AGENT_MODE=anonymous npx convex dev --once
```

Or add `CONVEX_AGENT_MODE=anonymous` to `.env.local`.

This runs a **local anonymous** backend — separate from the user's cloud dev deployment. Good for codegen and function testing without OAuth; not a substitute for testing against their real deployment data.

## One-shot sync options

| Flag | Behavior |
| --- | --- |
| `--once` | Configure (if needed), push, codegen, stop. Fail fast. |
| `--until-success` | Like `--once`, but retries on failure when files or remote state change |
| `--run <fn>` | After push, run a function once (seed data, smoke test) |
| `--push` on `run` | Push before executing |

## CI / production deploy

Set `CONVEX_DEPLOY_KEY` in the environment (never commit it):

```sh
npx convex deploy --cmd "npm run build"
```

Deploy target resolution:

1. `CONVEX_DEPLOY_KEY` set → deployment for that key (prod or preview key)
2. Else `CONVEX_DEPLOYMENT` set → prod deployment of that project
3. Preview keys support `--preview-create`, `--preview-run`, `--preview-name`

## Auth on the host vs sandbox

Commands that need the user's Convex login, browser, or home-directory config:

- First `convex dev` / `convex login`
- `convex dashboard`
- `convex logout`

If a sandbox reports auth errors, **rerun on the host** before concluding the user is logged out.

## Non-interactive env secrets

Prefer stdin over argv for secrets (avoids shell history):

```sh
pbpaste | npx convex env set API_KEY
npx convex env set PUBLIC_KEY --from-file key.pub
```

## When CLI output is untrusted

Treat as inconclusive until rerun on host:

- "Not logged in" / auth required
- Missing `CONVEX_DEPLOYMENT` when `.env.local` exists on the user's machine
- Network blocked to Convex cloud
- Browser cannot open for OAuth

## MCP alternative

Convex ships `npx convex mcp` (beta) for MCP-aware agents. Use CLI for shell automation; use MCP when the harness exposes Convex MCP tools directly.
