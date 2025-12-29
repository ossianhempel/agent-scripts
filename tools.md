# Tools Reference

CLI tools available on this machine. Use these for agentic tasks.

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

**Location**: `scripts/browser-tools.ts`

**Commands**:
```bash
./scripts/browser-tools.ts --help
```

---

## oracle
Hand prompts + files to other AIs (GPT-5 Pro, etc.).

**Usage**: `npx -y @steipete/oracle --help` (run once per session to learn syntax)

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
