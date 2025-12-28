# Syncing Agent Instructions

Use `scripts/sync-agent-instructions.sh` to insert a shared pointer line into
repo instruction files while preserving local rules below it.

The pointer line looks like:

```
READ /path/to/agent-scripts/GLOBAL_AGENTS.md BEFORE ANYTHING (skip if missing).
```

## Usage

Scan a directory of repos:

```sh
/path/to/agent-scripts/scripts/sync-agent-instructions.sh --root ~/code --dry-run
```

Target specific repos:

```sh
/path/to/agent-scripts/scripts/sync-agent-instructions.sh --repo ~/code/app --repo ~/code/api
```

Create missing instruction files:

```sh
/path/to/agent-scripts/scripts/sync-agent-instructions.sh --root ~/code --create-missing
```

By default, the script only updates files that already exist. Use
`--create-missing` to create new instruction files.

Override the pointer path:

```sh
/path/to/agent-scripts/scripts/sync-agent-instructions.sh \
  --root ~/code \
  --pointer-path ~/agent-scripts/GLOBAL_AGENTS.md
```

## Supported filenames

By default the script updates these files (if present):

- `AGENTS.md`
- `CLAUDE.md`
- `GEMINI.md`
- `.github/copilot-instructions.md`

You can override the list with `--files`.
