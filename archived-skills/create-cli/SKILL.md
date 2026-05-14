---
name: create-cli
description: >
  Design and build composable CLIs — human-first, script-friendly, and durable
  enough for agents to run from any repo. Covers the full path: clarify intent,
  design the command surface (args, flags, subcommands, help, output, errors,
  exit codes, config/env precedence, safe/dry-run), then scaffold, install on
  PATH, smoke test from outside the source folder, and ship a companion skill.
  Use when designing a CLI spec before implementation OR when building a real
  tool from API docs, an OpenAPI spec, curl examples, an SDK, a web app, an
  admin tool, or a local script.
---

# Create CLI

Design CLI surface area (syntax + behavior) AND build durable tools that future agent threads can run by command name from any working directory.

Two modes, one skill:

- **Design only** — produce a compact spec the user can implement themselves.
- **Design + build** — scaffold, install, test, and ship a companion skill.

Pick the mode from the user's ask. If in doubt, clarify in one sentence.

## Do This First

- Read `skills/create-cli/references/cli-guidelines.md` as the default rubric for CLI UX.
- When the CLI will be run by agents (Codex, Claude Code, etc.), also read `skills/create-cli/references/agent-cli-patterns.md` for the composable command shape.
- Ask only the minimum clarifying questions needed to lock the interface.

## Start

Name the target tool, its source, and the first real jobs it should do:

- **Source**: API docs, OpenAPI JSON, SDK, curl examples, browser app, existing internal script, article, or working shell history.
- **Jobs**: literal reads/writes such as `list drafts`, `download failed job logs`, `search messages`, `upload media`, `read queue schedule`.
- **Install name**: a short binary name such as `ci-logs`, `slack-cli`, `sentry-cli`, or `buildkite-logs`.

Prefer a new folder under `~/code/clis/<tool-name>` when the user wants a personal tool and has not named a repo.

Before scaffolding, check whether the proposed command already exists:

```bash
command -v <tool-name> || true
```

If it exists, choose a clearer install name or ask the user.

## Clarify (fast)

Ask, then proceed with best-guess defaults if the user is unsure:

- Command name + one-sentence purpose.
- Primary user: humans, scripts, agents, or a mix.
- Input sources: args vs stdin; files vs URLs; secrets (never via flags).
- Output contract: human text, `--json`, `--plain`, exit codes.
- Interactivity: prompts allowed? need `--no-input`? confirmations for destructive ops?
- Config model: flags/env/config-file; precedence; XDG vs repo-local.
- Platform/runtime constraints: macOS/Linux/Windows; single binary vs runtime.

## Design Deliverables

When designing a CLI, produce a compact spec the user can implement:

- Command tree + USAGE synopsis.
- Args/flags table (types, defaults, required/optional, examples).
- Subcommand semantics (what each does; idempotence; state changes).
- Output rules: stdout vs stderr; TTY detection; `--json`/`--plain`; `--quiet`/`--verbose`.
- Error + exit code map (top failure modes).
- Safety rules: `--dry-run`, confirmations, `--force`, `--no-input`.
- Config/env rules + precedence (flags > env > project config > user config > system).
- 5–10 example invocations (common flows; include piped/stdin examples).

## Default Conventions (unless user says otherwise)

- `-h/--help` always shows help and ignores other args.
- `--version` prints version to stdout.
- Primary data to stdout; diagnostics/errors to stderr.
- Add `--json` for machine output; consider `--plain` for stable line-based text.
- Prompts only when stdin is a TTY; `--no-input` disables prompts.
- Destructive operations: interactive confirmation + non-interactive requires `--force` or explicit `--confirm=...`.
- Respect `NO_COLOR`, `TERM=dumb`; provide `--no-color`.
- Handle Ctrl-C: exit fast; bounded cleanup; be crash-only when possible.

## CLI Spec Skeleton (copy into your answer)

Fill these sections, drop anything irrelevant:

1. **Name**: `mycmd`
2. **One-liner**: `...`
3. **USAGE**:
   - `mycmd [global flags] <subcommand> [args]`
4. **Subcommands**:
   - `mycmd init ...`
   - `mycmd run ...`
5. **Global flags**:
   - `-h, --help`
   - `--version`
   - `-q, --quiet` / `-v, --verbose` (define exactly)
   - `--json` / `--plain` (if applicable)
6. **I/O contract**:
   - stdout:
   - stderr:
7. **Exit codes**:
   - `0` success
   - `1` generic failure
   - `2` invalid usage (parse/validation)
   - (add command-specific codes only when actually useful)
8. **Env/config**:
   - env vars:
   - config file path + precedence:
9. **Examples**:
   - …

---

# Building the CLI

Use this section when the user asks you to actually build the tool, not just design the surface. If the ask is "design parameters", stop at the spec above.

This mode is for durable tools, not one-off scripts. If a short script in the current repo solves the task, write the script there instead.

## Agent-Friendly Command Contract

Sketch the command surface in chat before coding. Include the binary name, discovery commands, resolve or ID-lookup commands, read commands, write commands, raw escape hatch, auth/config choice, and PATH/install command.

Build toward this surface:

- `tool-name --help` shows every major capability.
- `tool-name --json doctor` verifies config, auth, version, endpoint reachability, and missing setup.
- `tool-name init ...` stores local config when env-only auth is painful.
- **Discovery** commands find accounts, projects, workspaces, teams, queues, channels, repos, dashboards, or other top-level containers.
- **Resolve** commands turn names, URLs, slugs, permalinks, customer input, or build links into stable IDs so future commands do not repeat broad searches.
- **Read** commands fetch exact objects and list/search collections. Paginated lists support a bounded `--limit`, cursor, offset, or clearly documented default.
- **Write** commands do one named action each: create, update, delete, upload, schedule, retry, comment, draft. They accept the narrowest stable resource ID, support `--dry-run`, `draft`, or `preview` first when the service allows it, and do not hide writes inside broad commands such as `fix`, `debug`, or `auto`.
- `--json` returns stable machine-readable output.
- A **raw escape hatch** exists: `request`, `tool-call`, `api`, or the nearest honest name.

Do not expose only a generic `request` command. Give agents high-level verbs for the repeated jobs.

Document the JSON policy in the CLI README: API pass-through versus CLI envelope, success shape, error shape, and one example for each command family. Under `--json`, errors must be machine-readable and must not contain credentials.

## Choose the Runtime

Before choosing, inspect the user's machine and source material:

```bash
command -v cargo rustc node pnpm npm python3 uv || true
```

Then choose the least surprising toolchain:

- Default to **Rust** for a durable CLI agents should run from any repo: one fast binary, strong argument parsing, good JSON handling, easy copy/install into `~/.local/bin`.
- Use **TypeScript/Node** when the official SDK, auth helper, browser automation library, or existing repo tooling is the reason the CLI can be better.
- Use **Python** when the source is data science, local file transforms, notebooks, SQLite/CSV/JSON analysis, or Python-heavy admin tooling that can still be installed as a durable command.

Do not pick a language that adds setup friction unless it materially improves the CLI. If the best language is not installed, either install the missing toolchain with the user's approval or choose the next-best installed option.

State the choice in one sentence before scaffolding, including the reason and the installed toolchain you found.

## Auth and Config

Support the boring paths first, in this precedence order:

1. Environment variable using the service's standard name, such as `GITHUB_TOKEN`.
2. User config under `~/.<tool-name>/config.toml` or another simple documented path.
3. `--api-key` or a tool-specific token flag only for explicit one-off tests. Prefer env/config for normal use because flags can leak into shell history or process listings.

Never print full tokens. `doctor --json` should say whether a token is available, the auth source category (`flag`, `env`, `config`, provider default, or missing), and what setup step is missing.

If the CLI can run without network or auth, make that explicit in `doctor --json`: report fixture/offline mode, whether fixture data was found, and whether auth is not required for that mode.

For internal web apps sourced from DevTools curls, create sanitized endpoint notes before implementing: resource name, method/path, required headers, auth mechanism, CSRF behavior, request body, response ID fields, pagination, errors, and one redacted sample response. Never commit copied cookies, bearer tokens, customer secrets, or full production payloads.

Use screenshots to infer workflow, UI vocabulary, fields, and confirmation points. Do not treat screenshots as API evidence unless they are paired with a network request, export, docs page, or fixture.

## Build Workflow

1. Read the source just enough to inventory resources, auth, pagination, IDs, media/file flows, rate limits, and dangerous write actions. If the docs expose OpenAPI, download or inspect it before naming commands.
2. Sketch the command list in chat. Keep names short and shell-friendly.
3. Scaffold the CLI with a README or equivalent repo-facing instructions.
4. Implement `doctor`, discovery, resolve, read commands, one narrow draft or dry-run write path if requested, and the raw escape hatch.
5. Install the CLI on PATH so `tool-name ...` works outside the source folder.
6. Smoke test from another repo or `/tmp`, not only with `cargo run` or package-manager wrappers. Run `command -v <tool-name>`, `<tool-name> --help`, and `<tool-name> --json doctor`.
7. Run format, typecheck/build, unit tests for request builders, pagination/request-body builders, no-auth `doctor`, help output, and at least one fixture, dry-run, or live read-only API call.

If a live write is needed for confidence, ask first and make it reversible or draft-only.

When the source is an existing script or shell history, split the working invocation into real phases: setup, discovery, download/export, transform/index, draft, upload, poll, live write. Preserve the flags, paths, and environment variables the user already relies on, then wrap the repeatable phases with stable IDs, bounded JSON, and file outputs.

For raw escape hatches, support read-only calls first. Do not run raw non-GET/HEAD requests against a live service unless the user asked for that specific write.

For media, artifact, or presigned upload flows, test each phase separately: create upload, transfer bytes, poll/read processing status, then attach or reference the resulting ID.

For fixture-backed prototypes, keep fixtures in a predictable project path and make the CLI locate them after installation. Smoke-test from `/tmp` to catch binaries that only work inside the source folder.

For log-oriented CLIs, keep deterministic snippet extraction separate from model interpretation. Prefer a command that emits filenames, line numbers or byte ranges, matched rules, and short excerpts.

## Language Defaults

### Rust

- `clap` for commands and help
- `reqwest` for HTTP
- `serde` / `serde_json` for payloads
- `toml` for small config files
- `anyhow` for CLI-shaped error context

Add a `Makefile` target such as `make install-local` that builds release and installs the binary into `~/.local/bin`.

### TypeScript/Node

- `commander` or `cac` for commands and help
- native `fetch`, the official SDK, or the user's existing HTTP helper for API calls
- `zod` only where external payload validation prevents real breakage
- `package.json` `bin` entry for the installed command
- `tsup`, `tsx`, or `tsc` using the repo's existing convention

Add an install path such as `pnpm install`, `pnpm build`, and `pnpm link --global`, or a `Makefile` target that installs a small wrapper into `~/.local/bin`.

### Python

- `argparse` for commands and help, or `typer` when subcommands would otherwise get messy
- `urllib.request` / `urllib.parse`, `requests`, or `httpx` for HTTP, matching what is already installed or already used nearby
- `json`, `csv`, `sqlite3`, `pathlib`, and `subprocess` for local files, exports, databases, and existing scripts
- `pyproject.toml` console script or a small executable wrapper for the installed command
- `uv` or a virtualenv only when dependencies are actually needed

Add a `Makefile` target such as `make install-local` that installs the command on PATH and document whether it depends on `uv`, a virtualenv, or only system Python.

## Companion Skill

After the CLI works, create or update a small skill for it. Use the `skill-creator` skill when it is available. Place a personal companion skill at `~/.claude/skills/<tool-name>/SKILL.md` (or the equivalent Codex path) unless the user names a repo-local path or another skill repo.

Write the companion skill in the order a future agent thread should use the CLI, not as a tour of every feature. Explain:

- How to verify the installed command exists.
- Which command to run first.
- How auth is configured.
- Which discovery command finds the common ID.
- The safe read path.
- The intended draft/write path.
- The raw escape hatch.
- What not to do without explicit user approval.
- Three copy-pasteable command examples.

Keep API reference details in the CLI docs or a skill reference file. Keep the skill focused on ordering, safety, and examples future agent threads should actually run.

## Notes

- Prefer recommending a parsing library (language-specific) only when asked; otherwise keep design-phase guidance language-agnostic.
- If the request is "design parameters", do not drift into implementation.
- If the request is "build a CLI from X", do not skip the design-phase clarification — a bad surface makes the implementation wasted work.
