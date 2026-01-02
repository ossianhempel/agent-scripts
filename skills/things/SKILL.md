---
name: things
description: Things 3 CLI for reading the local Things database and creating/updating tasks/projects via the Things URL scheme. Use when you need to list, search, or modify Things tasks, projects, areas, or tags from the terminal (deletes use AppleScript).
---

# things

Use `things` to read from the local Things 3 database and to create/update items via the Things URL scheme (areas use AppleScript).

Quick start (read)
- `things inbox`
- `things today`
- `things projects` / `things areas` / `things tags`
- `things tasks --search "query" --json`
- `things tasks --query 'tag:work AND title:/review/i' --format jsonl`
- `things show --project "Project Name"`

Write (URL scheme)
- `things add "Task title" --notes "..." --list "Project or Area"`
- `things add-project "Project title" --area "Area Name"`
- `things update --id <uuid> --notes "Updated notes"`
- Bulk update (preview then apply): `things update --query 'tag:work' --dry-run` then `things update --query 'tag:work' --yes --tags "Work"`
- `things update-project --id <uuid> "New project title"`
- `things delete --id <uuid>` or `things delete "Todo title"`
- Bulk delete (preview then apply): `things delete --query 'notes:/deprecated/i' --dry-run` then `things delete --query 'notes:/deprecated/i' --yes`
- Undo last bulk action: `things undo --dry-run` then `things undo --yes`
- `things delete-project --id <uuid>` or `things delete-project "Project title"`
- `things delete-area --id <uuid>` or `things delete-area "Area Name"`
- Move to Someday: `things update --id <uuid> --when=someday`
- Move to This Evening (Later): `things update --id <uuid> --later` (alias for `--when=evening`)

Filters + DB
- Use `--db` or `THINGSDB` to point to a specific Things.sqlite.
- Common filters: `--filter-project`, `--filter-area`, `--filter-tag`, `--status`, `--search`, `--limit`, `--offset`.
- Rich query: `--query` supports boolean ops, field predicates, and regex (e.g. `title:/regex/ AND tag:work`).
- Date filters: `--created-before/after`, `--modified-before/after`, `--due-before`, `--start-before`.
- URL filter: `--has-url`.
- Sorting: `--sort created,-deadline,title`.
- Output: `--format table|json|jsonl|csv`, `--select uuid,title,status`, `--no-header`. `--json` still works.
- `--recursive` includes checklist items in JSON output.

Auth + permissions
- Updates require an auth token: run `things auth` for setup/status, set `THINGS_AUTH_TOKEN`, or pass `--auth-token`.
- DB reads may require Full Disk Access for your terminal.
- URL scheme writes can open/foreground Things; use `--dry-run` to print URLs or `--foreground` to force focus.
- Delete commands prompt for confirmation when interactive; pass `--confirm` for single deletes in non-interactive scripts. Bulk delete requires `--yes`.
- Bulk update/delete write an action log; use `things undo` to revert the last bulk update or trash.

Notes
- macOS only.
- Use `things --help` and `things <command> --help` for the full flag list.
- Install via Homebrew: `brew install ossianhempel/tap/things3-cli`.
