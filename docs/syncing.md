---
summary: Guide for syncing skills, commands, and hooks to agent runtime locations
read_when:
  - Using sync-agent-scripts.sh to deploy skills/commands/hooks
  - Setting up agent skills across Codex, Claude Code, Gemini, Cursor, or Copilot
---

# Syncing Agent Scripts

> **Note:** Slash commands (in `slash-commands/`) are deprecated in Codex. Use skills instead. Claude Code still supports slash commands, but skills work everywhere and are the recommended approach.

Use `scripts/sync-agent-scripts.sh` to install the skills, slash commands, and
agent hooks in this repo into each agent runtime's standard locations.

## Architecture

Skills install as **relative symlinks** pointing back into this repo's
`skills/` — there is one canonical copy (in agent-scripts) and every runtime
links to it. The link targets are:

- **`~/.agents/skills`** — cross-tool standard read by Codex, Gemini CLI, Cursor,
  Copilot, Windsurf, and others. One link set serves all these tools.
- **`~/.claude/skills`** — Claude Code only (does not yet support `.agents/`).
- **`~/.gemini/antigravity-cli/skills`** — Antigravity CLI.

Each link resolves like
`~/.claude/skills/<skill> -> ../../Developer/agent-scripts/skills/<skill>`.

Consequences (same model the profiles already use):

- **Zero duplication** — one copy on disk, period.
- **No drift, no re-sync after edits** — change a skill in agent-scripts and
  every runtime sees it immediately. You only re-run sync to add or remove a
  skill, not to edit one.
- **agent-scripts is a runtime dependency** — move or delete the repo and every
  runtime's skill links break.

Commands, prompts, and hooks are still **copied** to each tool's native location
since their formats differ per tool.

These are the **global** skills — every assigned runtime gets all of them.
Project-scoped skills are handled separately as **profiles** (see
[Profiles](#profiles-project-scoped-skill-packages)).

Hooks live under `hooks/`. The current shared hook installs a Claude Code and
Codex `SessionStart` command that pulls the current Git branch from its upstream
only when it is safe: the directory is a Git worktree, the branch has an
upstream, the worktree is clean, there are no unpushed local commits, and the
pull can fast-forward.

## Quickstart

From the repo you want to receive project-local commands (Cursor/Copilot):

```sh
/path/to/agent-scripts/scripts/sync-agent-scripts.sh
```

Preview changes only:

```sh
/path/to/agent-scripts/scripts/sync-agent-scripts.sh --dry-run
```

Limit providers:

```sh
/path/to/agent-scripts/scripts/sync-agent-scripts.sh --providers agents,claude
```

## Profiles (project-scoped skill packages)

Global skills (`skills/`) go everywhere. **Profiles** are curated bundles that
install only into the specific projects that need them, keeping the global set
small.

```
profiles/
  _shared/skills/<skill>/          # canonical home for skills used by 2+ profiles
  swift-app-developer/skills/<skill>/
  rn-app-developer/skills/<skill>/
profile-assignments.json           # project path -> profile(s)
```

- A skill in **one** profile is a real directory inside that profile's `skills/`.
- A skill shared by **multiple** profiles (but not global) lives once in
  `_shared/skills/<skill>/`; each profile that uses it holds a symlink:

  ```sh
  ln -s ../../_shared/skills/<skill> profiles/<profile>/skills/<skill>
  ```

  Sync follows the symlink and copies the real contents into the project, so the
  shared skill keeps a single source of truth.

### Syncing profiles

The default run **never** touches profiles. Use the non-default `profiles`
provider:

```sh
# Sync every assignment in profile-assignments.json
scripts/sync-agent-scripts.sh --provider profiles

# One-off: sync a profile into a specific project
scripts/sync-agent-scripts.sh --provider profiles \
  --profile swift-app-developer --project ~/Developer/platesnap

# Preview
scripts/sync-agent-scripts.sh --provider profiles --dry-run
```

`profile-assignments.json` maps project roots (`~` expanded) to a profile name
or a list of names:

```json
{
  "assignments": {
    "~/Developer/platesnap": "swift-app-developer",
    "~/Developer/gainslog": "rn-app-developer"
  }
}
```

### Where profile skills land in a project

Profile installs are a chain of **relative symlinks** back into agent-scripts —
not copies. There is one canonical copy of each skill (in agent-scripts), and
every assigned project links to it.

```
<project>/.agents/skills/<skill>  -> ../../../agent-scripts/profiles/<profile>/skills/<skill>
<project>/.claude/skills/<skill>  -> ../../.agents/skills/<skill>
```

Shared skills resolve through one more hop — the profile's `<skill>` entry is
itself a symlink to `_shared/skills/<skill>`. The chain works because the
symlinks are relative; agent-scripts only needs to be a sibling of the project
under whatever parent dir each machine uses (`~/Developer/`, `~/repos/`, etc.).

Consequences:

- **Zero duplication** — one copy on disk, period.
- **No drift possible** — edit in agent-scripts, every project sees it
  immediately. No need to re-run sync after a content change.
- **Sync = `ln -sfn`** — fast and idempotent.
- **agent-scripts is a runtime dependency** of every assigned project. If you
  move or delete agent-scripts, every project's profile skills break.

### Profile overrides

- `--profile <name>` (repeatable) + `--project <path>` — one-off sync, bypassing
  the manifest.
- `--profiles-manifest <path>` — use a different assignments file (default
  `./profile-assignments.json`).

### Auditing & pruning profiles

`scripts/skills-audit.py scan` reports profile inventory, assignments, profile
orphans, a list of project-native skills, and profile/global name collisions.
(A "profile drift" section also exists for backwards-compatibility but with the
symlink install model drift is structurally impossible — it will always be
empty.)

Two distinct categories matter for pruning:

- **Profile orphans** — a skill installed in a project that *is* managed by the
  repo's profile system (it lives in some profile or `_shared`) but is *not* in
  this project's assigned profile(s). These were installed by a different
  profile assignment and are safe to prune.
- **Project-local skills not in any repo profile** — skills authored inside the
  project that the repo has no copy of (e.g. an app's bespoke
  `gainslog-content` or `react-native-skills`). These are **never** pruned;
  scan only lists them so you can decide whether to promote them into a profile.

`scripts/skills-audit.py prune --profiles --execute` removes only profile
orphans from assigned project scopes, and only inside an assigned project's own
`.agents/skills` / `.claude/skills`. Without `--profiles`, prune manages global
scopes only and never touches project-local skills.

## Auto-sync via Git hooks (local only)

If you want local auto-sync on pull/checkout/rebase:

```sh
./scripts/install-hooks.sh
```

This installs repo-local hooks (via `core.hooksPath`) that run
`scripts/sync-agent-scripts.sh` when changes are detected under
`skills/`, `slash-commands/`, or `scripts/`:

- `post-merge` / `post-checkout` / `post-rewrite` — sync on *incoming* changes
  (pull, checkout, rebase).
- `pre-push` — sync on *outgoing* changes when pushing **`main`**, covering the
  gap where you publish your own work. It also runs `skills-audit.py prune` in
  **dry-run** mode and warns about global orphan skills without deleting them.
  Both steps are non-blocking: failures only warn, the push always proceeds.

To remove the hooks:

```sh
git config --unset core.hooksPath
```

## Default destinations

Skills (installed as relative symlinks into this repo's `skills/`):

- Cross-tool: `~/.agents/skills` (Codex, Gemini, Cursor, Copilot, Windsurf)
- Claude Code: `~/.claude/skills`
- Antigravity CLI: `~/.gemini/antigravity-cli/skills`

Commands/prompts (copied):

- Codex: `~/.codex/prompts`
- Claude Code: `~/.claude/commands`
- Gemini CLI: `~/.gemini/commands` (slash commands converted to `.toml`)
- Cursor: `~/.cursor/commands` (global) or `./.cursor/commands` (project)
- Copilot: `./.github/prompts` (workspace) or VS Code profile folder (user)

Hooks:

- Codex: `~/.codex/hooks.json`
- Claude Code: `~/.claude/settings.json`

## Overrides

- `--agents-home`, `--agents-skills-dir`, `--agents-scope`
- `--claude-home`, `--claude-skills-dir`
- `--codex-home`, `--gemini-home`
- `--cursor-commands-dir`, `--cursor-scope`
- `--copilot-prompts-dir`, `--copilot-user-prompts-dir`, `--copilot-scope`
- `--profile`, `--project`, `--profiles-manifest` (profiles provider)
- Or set env vars: `AGENTS_SCOPE`, `CURSOR_COMMANDS_DIR`, `CURSOR_SCOPE`,
  `COPILOT_PROMPTS_DIR`, `COPILOT_USER_PROMPTS_DIR`, `COPILOT_SCOPE`

## Notes

- The `agents` provider handles skills for all tools except Claude Code, syncing
  once to `~/.agents/skills` instead of separate per-tool directories.
- Use `--agents-scope project` or `--agents-scope both` to also sync skills to
  `./.agents/skills` in the current directory (for project-local skills).
- Cursor commands support both project and global scopes; the script defaults to
  global-only. Use `--cursor-scope project` or `--cursor-scope both`.
- Copilot supports workspace and user prompt scopes; the script defaults to none
  and only syncs prompts when you pass `--copilot-scope` and a prompts directory.
- Gemini also supports project-local commands in `./.gemini/commands`. If you
  want that, run with `--gemini-home .gemini`.
- Hook sync preserves unrelated existing hook entries and replaces only the
  managed command that points at this repo's hook script.
- The `profiles` provider is never in the default provider set, so a plain
  `sync-agent-scripts.sh` only ever syncs global `skills/`. Run it explicitly to
  push project-scoped profile bundles.
- `--dry-run` prints every file that would be created or updated.
