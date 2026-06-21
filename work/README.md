# work/ — employer (non-personal) skills & automations

This subtree holds **work** agent content, kept separate from the personal skills in
`agent-scripts/skills/`. One folder per employer:

```
work/
├── sync-claude-skills.sh        # installs work/*/skills/* into Claude Code ONLY
├── rebtech/
│   ├── skills/                  # SKILL.md skill dirs (Rebtech / Azure DevOps)
│   └── automations/             # scheduled-job prompt files
└── hm/                          # (later) same shape for H&M
    ├── skills/
    └── automations/
```

## Loading model — who sees what

The main `scripts/sync-agent-scripts.sh` installs the *personal* `skills/` into many tools at once.
This `work/` subtree is **not** touched by that default sync — it is wired up deliberately and narrowly:

| Destination | Tools that read it | What lands here |
|---|---|---|
| `~/.claude/skills/` | **Claude Code only** | `work/*/skills/*` via `work/sync-claude-skills.sh` |
| `~/.agents/skills/` | Codex, Cursor, Gemini, Copilot, Windsurf (shared) | nothing from `work/` (deliberately) |
| `./.github/prompts/` or Copilot user prompts dir | **GitHub Copilot** (prompts, not skills) | only if you author Copilot prompts |

### Claude Code only (Rebtech maintainer skills)

```bash
./work/sync-claude-skills.sh            # symlink into ~/.claude/skills only
./work/sync-claude-skills.sh --dry-run  # preview
```

It symlinks each `work/<employer>/skills/<name>` into `~/.claude/skills/` and **never** into
`~/.agents/skills/`, so Codex/Cursor/Gemini/Copilot do not load them. Re-run after adding a new
employer or skill. Safe across runs of the main sync (which only manages names under
`agent-scripts/skills/*` via its own `.agent-scripts-managed` manifest).

### "Copilot only" — read this before trying

There is **no Copilot-only *skills* folder.** In this toolchain:

- **Skills** (`SKILL.md`) are loaded by Claude Code (`~/.claude/skills`) and by the shared
  `~/.agents/skills` (Codex/Cursor/Gemini/Copilot/Windsurf together). The only way to make a skill
  exclusive is the Claude-only path above — there is no per-tool skills folder for Copilot alone.
- **Copilot does not consume `SKILL.md` skills.** It consumes **prompt files** (`*.prompt.md`).
  Those live in Copilot-specific locations that no other tool reads:
  - workspace scope: `<repo>/.github/prompts/*.prompt.md`
  - user scope: the Copilot user prompts dir (`--copilot-user-prompts-dir`).

So to make H&M content show up **in Copilot but not Codex/Cursor**, author it as a **Copilot prompt**
(not a skill) under `work/hm/automations/` (or a dedicated `work/hm/prompts/`) and sync only that
provider:

```bash
scripts/sync-agent-scripts.sh --provider copilot --copilot-scope user \
  --copilot-user-prompts-dir <copilot-user-prompts-path>
# or workspace scope:
scripts/sync-agent-scripts.sh --provider copilot --copilot-scope workspace \
  --copilot-prompts-dir <repo>/.github/prompts
```

(The main sync renders prompt source into `*.prompt.md` via `render_copilot_prompt`. Point the
`--copilot-*-prompts-dir` at a `work/`-scoped source if you want to keep these out of the personal set.)

Summary of the asymmetry: **Claude-only is a folder choice; Copilot-only is a *format* choice**
(prompt, not skill).

## automations/

Plain-markdown prompt files for scheduled / recurring agent runs (e.g.
`rebtech/automations/scheduled-maintainer-run.md`). They are not skills and are not symlinked anywhere —
a scheduler (a Claude Code routine, a local cron invoking `claude -p`, etc.) points at them. Each is
self-contained so it works without the rest of the repo in context.

## Adding H&M later

1. `mkdir -p work/hm/skills work/hm/automations`
2. Add `work/hm/skills/<name>/SKILL.md` for Claude Code skills, or `*.prompt.md` for Copilot prompts.
3. `./work/sync-claude-skills.sh` (Claude skills) and/or the `--provider copilot` sync (Copilot prompts).
