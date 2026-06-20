# Tools Reference

CLI tools available on Ossian's machines. Use these for agentic tasks.

## agent-readiness
Deterministic readiness evaluator with a CLI + JSON report schema.

**Location**: `tools/agent-readiness`

**Docs**: `tools/agent-readiness/README.md`

**Commands**:
```bash
./scripts/readiness.sh .
```

---

## sync-agent-scripts
Sync skills + slash commands into agent runtimes (Codex/Claude/Gemini/Cursor/Copilot).

**Location**: `scripts/sync-agent-scripts.sh`

**Docs**: `docs/syncing.md`

**Commands**:
```bash
./scripts/sync-agent-scripts.sh --dry-run
./scripts/sync-agent-scripts.sh --providers codex,claude
```

---

## sync-agent-instructions
Insert or update the shared pointer line in repo instruction files.

**Location**: `scripts/sync-agent-instructions.sh`

**Docs**: `docs/instructions-syncing.md`

**Commands**:
```bash
./scripts/sync-agent-instructions.sh --root ~/Developer --dry-run
./scripts/sync-agent-instructions.sh --repo ~/Developer/my-repo --create-missing
```

---

## committer
Safe commit helper that stages only the paths you pass in.

**Location**: `scripts/committer`

**Commands**:
```bash
./scripts/committer "feat: add widget" src/widget.ts
```

---

## trash
Recoverable file deletion for macOS.

**Usage**:
```bash
trash path/to/file
trash path/to/folder
```

Use `trash` instead of `rm` for user files or repo files that need removal.

---

## docs-list
List docs with front-matter summaries + read_when hints.

**Location**: `scripts/docs-list.ts`

**Commands**:
```bash
./scripts/docs-list.ts
```

---

## browser-tools
Chrome DevTools helper (navigate, evaluate, screenshot, inspect, etc.).

**Location**: `bin/browser-tools` (resolves to `scripts/browser-tools.ts`)

**Commands**:
```bash
./bin/browser-tools --help
```

---

## openclaw
Personal AI assistant service. On this Mac it runs as the launch agent
`ai.openclaw.gateway`, with state under `~/.openclaw`.

**Docs**: `docs/openclaw-operations.md`

**Health checks**:
```bash
launchctl print gui/$(id -u)/ai.openclaw.gateway
tail -n 160 ~/Library/Logs/openclaw/gateway.log
find ~/.openclaw/telegram/ingress-spool-default -maxdepth 1 -type f -print
```

**Restart**:
```bash
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

Use this when Telegram/Discord/WhatsApp channels stop responding. Do not edit
OpenClaw source code for local service recovery.

---

## oracle
Hand prompts + files to other AIs (GPT-5 Pro, etc.).

**Usage**: `npx -y @steipete/oracle --help` (run once per session to learn syntax)

---

## mcp-as-cli
Run MCP tools on demand through MCPorter without adding persistent MCP server
config to Codex, Claude, Cursor, or project profiles.

**Location**: `bin/mcp-as-cli`

**Docs**: `docs/mcp-as-cli.md`

**Commands**:
```bash
bin/mcp-as-cli list https://mcp.example.com/mcp --schema
bin/mcp-as-cli call 'https://mcp.example.com/mcp.tool_name' key=value
bin/mcp-as-cli auth https://mcp.example.com/mcp
```

---

## summarize
Summarize or extract content from URLs, articles, PDFs, local files, YouTube/videos, podcasts, transcripts, and stdin text.

**Install**:
```bash
brew install steipete/tap/summarize
```

**Usage**:
```bash
summarize "https://example.com"
summarize "/path/to/file.pdf"
summarize "https://youtu.be/..." --youtube auto
summarize "https://example.com" --extract --format md
pbpaste | summarize -
```

Companion skill: `skills/summarize`.

---

## peekaboo
Capture, inspect, and automate macOS UI with screenshots, annotated UI maps, app/window/menu control, and keyboard/mouse input.

**Install**:
```bash
brew install steipete/tap/peekaboo
```

**Usage**:
```bash
peekaboo permissions
peekaboo see --annotate --path /tmp/peekaboo-see.png
peekaboo image --mode screen --path /tmp/screen.png
peekaboo list apps --json
peekaboo click --on B1
```

Archived companion skill: `archived-skills/peekaboo`.

---

## clerk
Clerk CLI for auth, users, orgs, instance config, and Backend/Platform API calls.

**Install**:
```bash
# Prefer project-local via package runner; global install optional
npx -y clerk@latest --version
```

**Usage**:
```bash
clerk doctor --json
clerk auth login
clerk env pull
clerk api ls users
clerk api /users --json
```

Companion skill: `skills/clerk-cli`.

---

## convex
Convex CLI for dev sync, deploy, run functions, inspect data, env vars, logs, and exports.

**Install**:
```bash
npm install convex   # or use npx in any repo
npx convex --version
```

**Usage**:
```bash
npx convex dev --once
npx convex deploy
npx convex run tasks:list
npx convex data
npx convex env list
npx convex insights --details
```

Companion skill: `skills/convex-cli`.

---

## gh
GitHub CLI for PRs, issues, CI, releases.

**Usage**: `gh help`

When someone shares a GitHub URL, use `gh` to read it:
```bash
gh issue view <url> --comments
gh pr view <url> --comments --files
gh run list / gh run view <id>
```

---

## gog (gogcli)
Google Workspace CLI (Gmail, Calendar, Drive, Contacts, etc.).

**Install**:
```bash
brew install steipete/tap/gogcli
```

**Usage**:
```bash
gog auth credentials /path/to/client_secret.json
gog auth add you@gmail.com
gog gmail labels list
```

---

## things
Things 3 CLI for reading the local Things database and creating/updating tasks/projects via the Things URL scheme.

**Install**:
```bash
brew install ossianhempel/tap/things3-cli
```

**Usage**:
```bash
things inbox
things today
things repeating
things add "Task title"
things add "Daily standup" --repeat=day --repeat-mode=schedule
things update --id <uuid> --repeat=week --repeat-every=2
things update --id <uuid> --repeat=day --repeat-until=2026-01-18
```

Repeating updates write directly to the Things database (Full Disk Access may be required).

---

## obsidian
Obsidian vault for notes and knowledge management.

**Location**: `~/ossians-second-brain-sync`

**Usage**:
```bash
obsidian --help
obsidian search query="query"
obsidian read path=daily-notes/2026-05-28.md
obsidian open path=daily-notes/2026-05-28.md
```
