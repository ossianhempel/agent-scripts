---
name: one-password
description: "Fetch secrets and env vars from 1Password via the `op` CLI. Primary path is a non-interactive service-account token (no prompts); Touch ID is the fallback. Use whenever a command needs an API key, token, password, or `.env` value — read it from 1Password instead of hardcoding, printing, or asking the user to paste it. Triggers: op, op read, op run, op inject, op://, 1Password, fetch a secret, get an API key, inject env vars."
metadata: {"requires":{"bins":["op"]},"install":[{"id":"brew","kind":"brew","formula":"1password-cli","bins":["op"],"label":"Install 1Password CLI (brew)"}]}
---

# 1Password CLI (`op`)

Fetch secrets and environment variables from 1Password so commands run with real
credentials without hardcoding them, printing them, or asking the user to paste.

## Auth model (Ossian's Mac)

**Primary — service account (no human in the loop).** A service-account token is
exported as `OP_SERVICE_ACCOUNT_TOKEN` in `~/.zshenv`, so every shell (including
non-interactive agent shells) can run `op` with **no Touch ID prompt**. The token
is scoped to the **`Development` vault only** — that is the blast radius if it leaks.

- Default account: `my.1password.com`.
- The service account can **only read the `Development` vault**. Secrets an agent
  needs non-interactively must live there. It cannot see `Personal`, `H&M`, or
  `Rebtech`.
- Service-account reads need an explicit vault: the vault is in the `op://` ref for
  `op read`; for `op item get`/`op item list` pass `--vault Development`.

**Fallback — Touch ID (interactive).** To reach a vault outside the service
account's scope (`Personal`, `H&M`, `Rebtech`), unset the token for that one
command so `op` uses desktop app integration and prompts Touch ID:

```bash
env -u OP_SERVICE_ACCOUNT_TOKEN op read "op://Personal/SomeItem/field"
```

This requires the user present to approve — use it only when the secret genuinely
isn't (and can't be) in `Development`.

## Core operations

Reference syntax is `op://<vault>/<item>/<field>`. For non-interactive use the
vault is almost always `Development`.

### Read one secret

```bash
op read "op://Development/OpenAI/api_key"
```

Inline for a single command so the value never lands in a variable or log:

```bash
OPENAI_API_KEY="$(op read 'op://Development/OpenAI/api_key')" some-tool --run
```

### Run a command with secrets injected (preferred for many vars)

Keep a `.env` of `op://` references (safe to commit — they're pointers, not values):

```bash
# .env
OPENAI_API_KEY=op://Development/OpenAI/api_key
DATABASE_URL=op://Development/AppDB/connection_string
```

```bash
op run --env-file=.env -- npm run dev
```

`op` resolves every `op://` ref into the child process's environment and nowhere else.

### Inject secrets into a config template

```bash
echo "db_password: {{ op://Development/AppDB/password }}" | op inject
op inject -i config.tpl.yml -o config.yml      # render a whole file
```

### Special field attributes

```bash
op read "op://Development/SomeItem/one-time password?attribute=otp"   # TOTP code
op read "op://Development/server/private key?ssh-format=openssh"      # SSH key
op read --out-file ./key.pem "op://Development/server/ssh/key.pem"    # write to file
```

## Adding a new secret for agents to use

Put it in the `Development` vault. The service account is **read-only**, so create
the item with Touch ID (or the desktop app):

```bash
env -u OP_SERVICE_ACCOUNT_TOKEN op item create --vault Development \
  --category "API Credential" --title "Some Service" "api_key[password]=…"
```

Then agents read it non-interactively via `op read "op://Development/Some Service/api_key"`.

## Finding the right reference

Prefer asking the user for the exact `op://` path, or copy it from the app
(right-click a field → "Copy Secret Reference"). If you must discover it, stay
metadata-only and vault-scoped — list titles, never field values:

```bash
op item list --vault Development --format json        # titles/ids/categories only
op item get "OpenAI" --vault Development --format json # inspect field LABELS, not values
```

Do not enumerate other vaults by default. Search only when the user asks.

## Guardrails

- **Never print or log secret values or the token.** No `echo $TOKEN`, no `set -x`
  around `op`, no `cat` of rendered output. To sanity-check a read, print shape
  only (length, prefix), never the value.
- **Prefer `op run` / `op inject`** over writing secrets to disk. If a file is
  unavoidable (`--out-file`), delete it as soon as the command that needs it is done.
- **No broad enumeration.** Don't run `env`, `export -p`, or list every vault to
  "find" a secret — query the exact item/field in `Development`.
- Don't widen the service account's scope or reach into `Personal` casually. Use the
  Touch ID fallback deliberately and only when needed.
- If `op read` returns the wrong field (items with duplicate/legacy fields), read
  the item as JSON and pick the exact label rather than guessing.

## Operations

- Token lives in `~/.zshenv` (`OP_SERVICE_ACCOUNT_TOKEN`). It is scoped to
  `Development` with `read_items` only.
- Rate limits: `op service-account ratelimit` shows usage if reads start failing.
- Rotate/replace: create a new one with
  `op service-account create <name> --vault Development:read_items --raw`, update
  `~/.zshenv`. The old token keeps working until deleted in the 1Password web UI.

## Service-specific credentials

Keep service-specific auth (which item, which fields) in the owning skill or the
project's `.env` of `op://` refs. This skill owns only the generic rules:
service-account-first, targeted reads, no enumeration, never print values.
