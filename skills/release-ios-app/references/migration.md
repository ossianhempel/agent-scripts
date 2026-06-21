# Consolidating older iOS release-flow skills

Use this when a repo still has a local `.codex/skills/release-flow/`,
`.agents/skills/release-flow/`, `.claude/skills/release-flow/`, or a bespoke release
doc that duplicates the shared iOS release process.

## Target shape

- Shared release decisions live in this global `release-ios-app` skill.
- App Store Connect build/readiness/submission commands live in `asc-release`.
- App Store release notes and metadata updates live in `asc-metadata`.
- Xcode Cloud version/build guard installation stays in `asc-version-guard`.
- Repo-specific facts live in the app repo's `.ios-release.env` and, when needed,
  the file named by `IOS_RELEASE_NOTES_FILE`.

Do not edit generated runtime caches or managed project-local copies directly.
Change `skills/release-ios-app/` here, then sync/prune through the normal
agent-scripts tooling when an install surface needs cleanup.

## What to merge into `release-ios-app`

Move content here when it is shared behavior across iOS or Expo releases:

- version-bump policy for `MARKETING_VERSION` or `expo.version`
- beta-branch to release-branch promotion rules
- TestFlight vs App Store channel sequencing
- the "promote the validated build" rule
- Xcode Cloud vs EAS routing
- backend deploy safeguards before shipping binaries
- compatibility traps that affect multiple repos

Prefer a focused reference file over growing `SKILL.md` when the topic is long or
only relevant during migration.

## What stays repo-local

Keep content in `.ios-release.env` or `IOS_RELEASE_NOTES_FILE` when it is an app
fact, not a shared release rule:

- app ID, bundle ID, version source path, branch names, build system
- repo commands for version checks, tests, changelog generation, or submit guards
- required local config filenames, environment prefixes, and Xcode Cloud overrides
- one-off build-number offsets, historical ASC state, or provider caveats
- app-specific Android/Play Console notes

If the note would be wrong in another app repo, keep it repo-local.

## What stays in sibling skills

Do not copy these bodies into `release-ios-app`; route to them instead:

- `asc-release`: `asc` CLI usage, IPA/PKG build/upload mechanics, readiness checks,
  attach-build, preflight, staging, and final review submission.
- `asc-metadata`: ASO, localization, promotional text, and "What's New" writing.
- `asc-version-guard`: installable scripts and CI hooks that prevent marketing
  version and build-number collisions in Xcode Cloud repos.

`release-ios-app` is the orchestration layer. It should tell the agent which
release path to take and when to invoke those sibling skills, not duplicate their
operational command manuals.

## Migration steps

1. Read the old local release-flow skill or doc and classify each section as
   shared rule, repo-local fact, or sibling-skill responsibility.
2. Move shared rules into `release-ios-app` or one of its `references/` files.
3. Move repo-local facts into `.ios-release.env` or `IOS_RELEASE_NOTES_FILE`.
4. Replace local-skill references with `release-ios-app`.
5. Delete only source-controlled local duplicates. For managed runtime/project
   installs, run the sync/audit prune path instead of hand-deleting copies.
6. YAML-parse every edited `SKILL.md` frontmatter block and run the skill audit.

## Compatibility risks

- Agents may still have stale project-local `release-flow` copies until profile
  pruning runs. Check `scripts/skills-audit.py scan` before assuming the surface
  is clean.
- Some app repos intentionally keep release branches equal. If
  `IOS_RELEASE_BETA_BRANCH == IOS_RELEASE_RELEASE_BRANCH`, skip the promotion PR.
- Expo apps with `IOS_RELEASE_ANDROID=true` have a production Android obligation;
  native-only instructions must not hide that path.
- ASC submission wording can sound like upload guidance. Preserve the golden rule:
  submit the already-uploaded, validated TestFlight build unless explicitly
  bypassing CI for that same candidate.
