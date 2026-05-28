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
  rn-app-developer/skills/<skill>/
```

- Each profile directory holds its skills under `skills/`, same `SKILL.md`
  format as a global skill.
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

Profile installs are relative symlinks back into agent-scripts (zero copies,
zero drift):

```
<project>/.agents/skills/<skill>  -> ../../../agent-scripts/profiles/<profile>/skills/<skill>
<project>/.claude/skills/<skill>  -> ../../.agents/skills/<skill>
```

Shared skills resolve through one more hop (profile entry is itself a symlink
into `_shared/`).

See `../docs/syncing.md` and the "Skill Sync & Audit" section of `../AGENTS.md`
for full details.
