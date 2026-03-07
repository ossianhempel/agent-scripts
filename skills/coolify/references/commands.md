# Coolify CLI Command Reference

## Global Flags

| Flag | Description |
|------|-------------|
| `--token` | Override context token for this command |
| `--context` | Use a specific context by name |
| `--format` | Output format: `table` (default), `json`, `pretty` |
| `--show-sensitive`, `-s` | Show sensitive values (tokens, passwords) |
| `--debug` | Enable debug output |

## context — Manage Coolify instances

```
coolify context add <name> <url> <token>
coolify context list
coolify context get <name>
coolify context use <name>
coolify context update <name> [flags]
coolify context delete <name>
coolify context set-token <name> <token>
coolify context set-default <name>
coolify context verify
coolify context version
```

## app (aliases: apps, application, applications)

```
coolify app list
coolify app get <uuid>
coolify app update <uuid> [flags]
coolify app delete <uuid>
coolify app start <uuid>
coolify app stop <uuid>
coolify app restart <uuid>
coolify app logs <uuid>
coolify app deployments <uuid>
```

### app create

```
coolify app create public --server-uuid <uuid> --project-uuid <uuid> \
  --environment-name <env> --git-repository <url> --git-branch <branch> \
  --build-pack <nixpacks|dockerfile|...> --ports-exposes <port>

coolify app create github --server-uuid <uuid> --project-uuid <uuid> \
  --environment-name <env> --github-app-uuid <uuid> \
  --git-repository <url> --git-branch <branch> --build-pack <pack> \
  --ports-exposes <port>

coolify app create deploy-key --server-uuid <uuid> --project-uuid <uuid> \
  --environment-name <env> --private-key-uuid <uuid> \
  --git-repository <url> --git-branch <branch> --build-pack <pack> \
  --ports-exposes <port>

coolify app create dockerfile --server-uuid <uuid> --project-uuid <uuid> \
  --environment-name <env> --dockerfile <content-or-path> --ports-exposes <port>

coolify app create dockerimage --server-uuid <uuid> --project-uuid <uuid> \
  --environment-name <env> --docker-registry-image-name <image:tag> \
  --ports-exposes <port>
```

### app env (aliases: envs, environment)

```
coolify app env list <app-uuid>
coolify app env get <app-uuid> --uuid <env-uuid>
coolify app env create <app-uuid> --key <KEY> --value <VALUE> [--is-build-time] [--is-preview]
coolify app env update <app-uuid> --uuid <env-uuid> --key <KEY> --value <VALUE>
coolify app env delete <app-uuid> --uuid <env-uuid>
coolify app env sync <app-uuid> --file <.env-file>
```

`env sync` reads a local `.env` file, diffs against remote, updates changed values, creates new ones.

## database (aliases: databases, db, dbs)

```
coolify db list
coolify db get <uuid>
coolify db update <uuid> [flags]
coolify db delete <uuid>
coolify db start <uuid>
coolify db stop <uuid>
coolify db restart <uuid>
```

### db create

Types: `postgresql`, `mysql`, `mariadb`, `mongodb`, `redis`, `keydb`, `clickhouse`, `dragonfly`

```
coolify db create postgresql --server-uuid <uuid> --project-uuid <uuid> \
  --environment-name <env> --postgres-user <user> --postgres-db <db> \
  [--instant-deploy]
```

### db backup

```
coolify db backup list <db-uuid>
coolify db backup create <db-uuid> [flags]
coolify db backup update <db-uuid> --uuid <backup-uuid> [flags]
coolify db backup delete <db-uuid> --uuid <backup-uuid>
coolify db backup trigger <db-uuid>
coolify db backup execution <db-uuid> --uuid <execution-uuid>
coolify db backup delete-execution <db-uuid> --uuid <execution-uuid>
```

## server (aliases: servers)

```
coolify server list
coolify server get <uuid>
coolify server add --name <name> --ip <ip> --private-key-uuid <uuid>
coolify server remove <uuid>
coolify server validate <uuid>
coolify server domain <uuid>
```

## deploy

```
coolify deploy uuid <resource-uuid>
coolify deploy name <resource-name>
coolify deploy batch <name1,name2,...> [--force]
coolify deploy list
coolify deploy get <deployment-uuid>
coolify deploy cancel <deployment-uuid>
```

## service (aliases: services, svc)

```
coolify service list
coolify service get <uuid>
coolify service create [flags]
coolify service delete <uuid>
coolify service start <uuid>
coolify service stop <uuid>
coolify service restart <uuid>
coolify service env list <svc-uuid>
coolify service env sync <svc-uuid> --file <.env-file>
```

## project (aliases: projects)

```
coolify project list
coolify project get <uuid>
coolify project create [flags]
```

## resource (aliases: resources)

```
coolify resource list    # List all resources (apps, services, databases)
```

## github (aliases: gh, github-app, github-apps)

```
coolify github list
coolify github get <uuid>
coolify github create [flags]
coolify github update <uuid> [flags]
coolify github delete <uuid>
coolify github repo <github-app-uuid>
coolify github branches <github-app-uuid> --repo <owner/repo>
```

## private-key (aliases: private-keys, key, keys)

```
coolify private-key list
coolify private-key create --name <name> --private-key <key-content>
coolify private-key delete <uuid>
```

## teams (aliases: team)

```
coolify teams list
coolify teams get <uuid>
coolify teams current
coolify teams members list <team-uuid>
```

## Utility

```
coolify config
coolify version
coolify update
coolify completion <shell>   # bash, zsh, fish, powershell
coolify docs
```
