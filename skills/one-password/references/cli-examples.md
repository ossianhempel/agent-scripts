# `op` CLI examples

Quick reference for the 1Password CLI. Full docs:
https://developer.1password.com/docs/cli/

## Auth / status

Default auth is the service-account token (`OP_SERVICE_ACCOUNT_TOKEN` in `~/.zshenv`),
scoped to the `Development` vault — non-interactive, no Touch ID.

```bash
op account list     # metadata only — list configured accounts
op vault list       # with token set: shows only Development
op service-account ratelimit   # usage if reads start failing

# Touch ID fallback for other vaults (Personal/H&M/Rebtech):
env -u OP_SERVICE_ACCOUNT_TOKEN op read "op://Personal/Item/field"
```

## Read a secret

```bash
op read "op://Private/OpenAI/api_key"
op read "op://Private/db/one-time password?attribute=otp"
op read "op://Private/server/private key?ssh-format=openssh"
op read --out-file ./key.pem "op://Private/server/ssh/key.pem"
```

## Run a command with secrets in its environment

```bash
export DB_PASSWORD="op://Private/AppDB/password"
op run -- printenv DB_PASSWORD            # resolved only inside the child process
op run --env-file=./.env -- npm run dev   # .env holds op:// refs, not values
```

## Inject into templates / config

```bash
echo "db_password: {{ op://Private/AppDB/password }}" | op inject
op inject -i config.tpl.yml -o config.yml
```

## Inspect items (metadata only — never prints field values)

```bash
op item list --vault Private --format json
op item get "OpenAI" --vault Private --format json
```

## Store a secret without printing it

`op item create` category strings are human-readable and case-sensitive; use
`"API Credential"` for API tokens.

```bash
TOKEN="$(pbpaste)"   # value comes from clipboard, never echoed
op item create --account my.1password.com --category "API Credential" \
  --title "Some Service" "api_key[password]=$TOKEN" >/dev/null
op item get "Some Service" --account my.1password.com --fields "label=api_key" >/dev/null
```

## Account notes

- Default account: `my.1password.com`. Pass `--account my.1password.com` when
  multiple accounts are configured or `op whoami` shows the wrong one.
- Don't use `my.1password.eu` unless explicitly asked.
