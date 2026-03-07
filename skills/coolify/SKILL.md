---
name: coolify
description: >-
  Manage Coolify self-hosted PaaS instances via the coolify CLI. Deploy
  applications, manage databases, sync environment variables, handle servers,
  and orchestrate services from the terminal. Use when working with Coolify
  deployments, infrastructure, or the Coolify API. Triggers: 'deploy to
  coolify', 'coolify app', 'manage my coolify server', 'sync env vars to
  coolify', 'create a database on coolify'.
---

# Coolify CLI

Coolify is an open-source, self-hostable PaaS (Heroku/Vercel alternative). The `coolify` CLI wraps the Coolify REST API for terminal-based management.

## Prerequisites

Verify the CLI is installed: `coolify version`. If not installed:

```bash
curl -fsSL https://raw.githubusercontent.com/coollabsio/coolify-cli/v4.x/scripts/install.sh | bash
```

## Configuration

Config lives at `~/.config/coolify/config.json`. Each "context" is a named Coolify instance with a URL and API token.

### First-time setup

```bash
# Coolify Cloud
coolify context set-token cloud <api-token>

# Self-hosted instance
coolify context add <name> <https://coolify.example.com> <api-token>

# Verify connectivity
coolify context verify
```

API tokens are created in the Coolify dashboard at `/security/api-tokens`.

### Multiple environments

```bash
coolify context add production https://prod.coolify.io <token>
coolify context add staging https://staging.coolify.io <token>
coolify context use production
# Or per-command: coolify app list --context staging
```

## Common Workflows

### Discover existing resources

Before creating or deploying, gather UUIDs needed for flags:

```bash
coolify server list                  # Get server UUIDs
coolify project list                 # Get project UUIDs
coolify resource list                # List all apps, services, databases
coolify app list --format json       # Machine-readable output
```

### Deploy an application

1. **From public repo:**
```bash
coolify app create public \
  --server-uuid <server> --project-uuid <project> \
  --environment-name production \
  --git-repository "https://github.com/user/repo" \
  --git-branch main --build-pack nixpacks --ports-exposes 3000
```

2. **From Docker image:**
```bash
coolify app create dockerimage \
  --server-uuid <server> --project-uuid <project> \
  --environment-name production \
  --docker-registry-image-name "nginx:latest" --ports-exposes 80
```

3. **Trigger a deploy of existing resource:**
```bash
coolify deploy uuid <app-uuid>
coolify deploy name <app-name>
coolify deploy batch app1,app2,app3 --force
```

### Manage environment variables

```bash
coolify app env list <app-uuid>
coolify app env create <app-uuid> --key DATABASE_URL --value "postgres://..."
coolify app env sync <app-uuid> --file .env.production   # Diff-based sync from .env file
```

`env sync` is the recommended approach — it reads the local file, diffs against remote, updates changed values, and creates new ones.

### Create a database

```bash
coolify db create postgresql \
  --server-uuid <server> --project-uuid <project> \
  --environment-name production \
  --postgres-user myuser --postgres-db mydb --instant-deploy
```

Types: `postgresql`, `mysql`, `mariadb`, `mongodb`, `redis`, `keydb`, `clickhouse`, `dragonfly`.

### Application lifecycle

```bash
coolify app start <uuid>
coolify app stop <uuid>
coolify app restart <uuid>
coolify app logs <uuid>
coolify app deployments <uuid>
```

### CI/CD integration

Use `--format json` for machine-readable output in scripts:

```bash
APP_UUID=$(coolify app list --format json | jq -r '.[] | select(.name=="myapp") | .uuid')
coolify deploy uuid "$APP_UUID" --format json
```

## Command Reference

For the full command tree with all flags, see [references/commands.md](references/commands.md).

## Key Patterns

- **UUIDs are everywhere** — most commands require resource UUIDs. Use `list` commands with `--format json` to extract them.
- **`--format json`** — always prefer JSON output when piping to other tools or extracting values.
- **`--show-sensitive`** — required to see tokens, passwords, and connection strings in output.
- **`--context <name>`** — target a specific Coolify instance without switching the default.
- **Aliases** — `app`/`apps`, `db`/`database`, `svc`/`service` are interchangeable.
