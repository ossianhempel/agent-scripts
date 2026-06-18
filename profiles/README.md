# Profiles

Profiles are **project-scoped MCP bundles**. Skills live in `../skills/` and sync
globally via symlinks; profiles only merge optional `mcp.json` into assigned
projects.

## Layout

```
profiles/
  swift-app-developer/mcp.json     # XcodeBuild MCP, RevenueCat, …
  rn-app-developer/mcp.json
  macos-swift-app-developer/mcp.json
```

## Targeting

`../profile-assignments.json` maps project paths to a profile name. Only assign
profiles when a project needs project-level MCP servers that should not spin up
globally on every Codex launch.

## Syncing

The default sync never touches profiles. Sync MCP bundles explicitly:

```sh
scripts/sync-agent-scripts.sh --provider profiles
scripts/sync-agent-scripts.sh --provider profiles --dry-run
```

Profile sync merges `mcp.json` into each assigned project's `.mcp.json` and
`.codex/config.toml`. It also prunes stale `.agent-scripts-managed` skill copies
from prior profile-sync runs (skills are global now).

See `../docs/syncing.md` for full details.
