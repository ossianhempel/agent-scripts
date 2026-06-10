# Profiles

Profiles are **project-scoped skill packages**. Unlike `../skills/` (which fans
out to every agent runtime globally), profile skills are installed only into the
specific projects assigned to them. This keeps the global skill set small while
letting focused projects pull in a curated bundle.

## Layout

```
profiles/
  _shared/skills/<skill>/          # canonical home for skills used by 2+ profiles
  swift-app-developer/skills/<skill>/
  macos-swift-app-developer/skills/<skill>/
  rn-app-developer/skills/<skill>/
  swift-app-developer/mcp.json     # optional project-level MCP servers
```

### Web profiles are composable

The native-app profiles (`swift-app-developer`, `rn-app-developer`, …) are
single coarse bundles because those stacks are uniform. Web apps vary per repo
(Clerk vs Better Auth, Next.js vs TanStack Start, monorepo or not), so the web
side is split into small composable profiles and a project lists the ones it
uses:

| Profile | Skills |
|---|---|
| `web-base` | shadcn, frontend-app-builder, frontend-testing-debugging, privacy-policy, grill-with-docs (every web repo) |
| `fw-nextjs` | vercel-react-best-practices, vercel-composition-patterns |
| `fw-tanstack` | tanstack-start-best-practices |
| `auth-clerk` | clerk, clerk-cli, clerk-setup, clerk-custom-ui |
| `auth-better-auth` | better-auth-best-practices, better-auth-create-auth, better-auth-organization |
| `web-monorepo` | hono, turborepo |
| `payments-stripe` | stripe-best-practices |
| `web-tooling` | mcp-builder, create-cli |
| `convex` | the convex-* cluster |

```jsonc
// profile-assignments.json
"~/Developer/gainslog-web": ["web-base", "auth-clerk", "fw-nextjs", "payments-stripe"],
"~/Developer/mejla":        ["web-base", "auth-better-auth", "fw-tanstack"]
```

When a project lists several profiles, the sync **unions** their skills (first
profile wins a name clash) and prunes against that union — so a repo only ever
gets the skills its combination declares. To change what a repo gets, edit its
profile list, not its installed copies.

- Each profile directory holds its skills under `skills/`, same `SKILL.md`
  format as a global skill.
- Each profile may also hold `mcp.json`, whose `mcpServers` are merged into
  each assigned project's `.mcp.json`.
- Each profile may also hold `plugins.json` (a `claude` section only — Codex
  plugin enablement is inherently global), whose marketplaces/enabled plugins
  are merged into each assigned project's `.claude/settings.json`. Applied by the
  same `--provider profiles` run. See AGENTS.md → "Plugins".
- A skill that belongs to **one** profile lives as a real directory inside that
  profile's `skills/`.
- A skill shared by **multiple** profiles (but not global) lives once in
  `_shared/skills/<skill>/`; each profile that uses it holds a **symlink**:

  ```sh
  ln -s ../../_shared/skills/<skill> profiles/<profile>/skills/<skill>
  ```

  Sync resolves the symlink and copies the real contents into the project, so
  there is still a single source of truth for the shared skill.

## Targeting

`../profile-assignments.json` maps project paths to profile(s). Keys are project
roots (`~` is expanded); values are a profile name or a list of profile names.

## Syncing

The default sync (`scripts/sync-agent-scripts.sh` with no args) never touches
profiles. Sync profiles explicitly:

```sh
# Sync every assignment from profile-assignments.json
scripts/sync-agent-scripts.sh --provider profiles

# One-off: sync a profile to a specific project
scripts/sync-agent-scripts.sh --provider profiles \
  --profile swift-app-developer --project ~/Developer/platesnap
```

Profile skills install as **self-contained real-directory copies** into each
project — not symlinks. App repos must stay portable: a symlink into
agent-scripts breaks the moment the repo is cloned, run in CI, or opened on
another machine, and some editors/indexers won't traverse it.

```
<project>/.agents/skills/<skill>/   (real dir, copied from the profile)
<project>/.claude/skills/<skill>/   (real dir, copied from the profile)
```

The in-repo `_shared/` model is still the single source of truth — a profile's
`<skill>` may be a symlink into `_shared/`, but the sync **dereferences** it
(`cp -RL`) so the project always gets real files, never a link. Edit a shared
skill once in `_shared/`; re-run the sync to fan the copy out. (Global skills,
which install into the home directory and are never committed, stay symlinks —
see `../AGENTS.md`.)

Each dest dir carries an `.agent-scripts-managed` manifest listing the skills
the sync owns. Removing a skill from a profile prunes its stale copy on the next
sync; project-authored skills (never in the manifest) are never touched.

Profile MCP installs are conservative merges:

```
profiles/<profile>/mcp.json  ->  <project>/.mcp.json
profiles/<profile>/mcp.json  ->  <project>/.codex/config.toml
```

Existing project MCP servers are preserved; missing profile servers are added;
conflicting server names warn and keep the project-local value. Codex reads the
`.codex/config.toml` output; `.mcp.json` is kept as the cross-tool project
manifest.

See `../docs/syncing.md` and the "Skill Sync & Audit" section of `../AGENTS.md`
for full details.
