---
name: things
description: Things 3 CLI for reading the local Things database and creating/updating tasks/projects via the Things URL scheme. Use when you need to list, search, or modify Things tasks, projects, areas, or tags from the terminal.
---

# things

Use `things` to read from the local Things 3 database and to create/update items via the Things URL scheme.

Quick start (read)
- `things inbox`
- `things today`
- `things projects` / `things areas` / `things tags`
- `things tasks --search "query" --json`
- `things show --project "Project Name"`

Write (URL scheme)
- `things add "Task title" --notes "..." --list "Project or Area"`
- `things add-project "Project title" --area "Area Name"`
- `things update --id <uuid> --notes "Updated notes"`
- `things update-project --id <uuid> "New project title"`

Filters + DB
- Use `--db` or `THINGSDB` to point to a specific Things.sqlite.
- Common filters: `--filter-project`, `--filter-area`, `--filter-tag`, `--status`, `--search`, `--limit`.
- Use `--json` for machine output; `--recursive` includes checklist items in JSON.

Auth + permissions
- Updates require an auth token: set `THINGS_AUTH_TOKEN` or pass `--auth-token`.
- DB reads may require Full Disk Access for your terminal.
- URL scheme writes can open/foreground Things; use `--dry-run` to print URLs or `--foreground` to force focus.

Notes
- macOS only.
- Use `things --help` and `things <command> --help` for the full flag list.
