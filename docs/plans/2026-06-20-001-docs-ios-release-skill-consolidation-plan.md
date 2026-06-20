---
summary: Migration plan for consolidating iOS release-flow guidance into release-ios-app.
read_when:
  - Consolidating iOS, Expo, TestFlight, Xcode Cloud, or App Store release skills.
  - Editing release-ios-app, asc-release, asc-version-guard, or archived ASC/Expo release skills.
  - Deciding whether a release-flow skill should stay standalone or become a release-ios-app reference.
---

# iOS Release Skill Consolidation Plan

Issue: https://github.com/ossianhempel/agent-scripts/issues/6

## Goal

Make `release-ios-app` the single entry point for iOS and Expo release orchestration, matching the `release-mac-app` shape:

- one global skill selected for "release this iOS/Expo app" work;
- repo-owned `.ios-release.env` manifest and repo-owned notes file for app-specific behavior;
- shared references for build-system branches and cross-app release policy;
- separate focused skills only for reusable subdomains that are not release orchestration.

This plan is research-only. It does not consolidate the skill bodies yet.

## Current Inventory

### Keep as the release entry point

- `skills/release-ios-app/SKILL.md`
  - Already defines the user-facing release policy, `develop` -> `main` release PR gate, version bump policy, version-must-exceed-live gate, backend deploy safeguard, TestFlight build promotion rule, and App Store submission handoff.
- `skills/release-ios-app/references/manifest.md`
  - Owns `.ios-release.env` schema and app-specific notes-file convention.
- `skills/release-ios-app/references/native-xcodecloud.md`
  - Owns native Swift/XcodeGen/Xcode Cloud mechanics.
- `skills/release-ios-app/references/expo-eas.md`
  - Owns Expo/EAS iOS and Android release mechanics.
- `skills/release-ios-app/scripts/ios-release`
  - Small manifest-driven status/version helper. It should stay small; do not turn it into a lane runner.

### Keep separate, but route from release-ios-app

- `skills/asc-release/SKILL.md`
  - App Store Connect build/upload/submission command layer. It should stay reusable for macOS App Store, direct ASC troubleshooting, and non-iOS release questions.
- `skills/asc-release/reference/cli-usage.md`
  - Generic `asc` CLI conventions; not iOS-specific.
- `skills/asc-release/reference/xcode-build.md`
  - Low-level archive/export/upload guidance. `release-ios-app` should route here only for intentional local IPA bypasses.
- `skills/asc-release/reference/release-flow.md`
  - ASC readiness/submission flow. `release-ios-app` should route here after a validated TestFlight build exists.
- `skills/asc-release/reference/workflow.md`
  - `.asc/workflow.json` automation guidance. Keep separate unless iOS repos standardize on an `.ios-release.env` generated workflow.
- `skills/asc-metadata/SKILL.md`
  - Metadata, localization, ASO, and What's New writing. Release flow depends on it, but metadata work is not the release orchestrator.
- `skills/asc-pricing/SKILL.md`
  - Pricing and RevenueCat catalog sync. Keep separate because pricing/catalog changes can happen without an app release.
- `skills/asc-version-guard/SKILL.md` and `skills/asc-version-guard/assets/**`
  - Installable guard infrastructure for Xcode Cloud repos. Keep separate because it copies scripts/hooks into app repos and has its own repair/install workflow.
- `skills/ios-marketing-capture/SKILL.md`
  - Screenshot capture automation. Keep separate; release-ios-app can mention screenshot readiness as a validation dependency, but capture implementation is a different task.
- `skills/app-store-screenshots/SKILL.md`
  - Screenshot composition/editor tooling. Keep separate from release orchestration.
- `skills/privacy-policy/SKILL.md`
  - Privacy policy and App Privacy mapping. Keep separate because legal/privacy content changes are not routine release execution.

### Archived material to mine or explicitly retire

- `archived-skills/asc-build-lifecycle/SKILL.md`
  - Merge useful "find latest build", processing-state, and retention notes into an iOS release reference only if still valid against current `asc --help`.
- `archived-skills/asc-testflight-orchestration/SKILL.md`
  - Merge TestFlight group/tester/What to Test distribution notes into a new `release-ios-app/references/testflight.md` if current projects need external tester distribution.
- `archived-skills/asc-submission-health/SKILL.md`
  - Most content overlaps `asc-release/reference/release-flow.md`; compare and backfill any missing readiness blockers into `asc-release`, not directly into `release-ios-app`.
- `archived-skills/asc-id-resolver/SKILL.md`
  - Generic ID lookup belongs in `asc-release/reference/cli-usage.md` or a small `asc-release` reference section, not `release-ios-app`.
- `archived-skills/asc-signing-setup/SKILL.md`
  - Keep archived unless app repos need signing-asset setup. This is onboarding/repair, not routine release.
- `archived-skills/asc-screenshot-resize/SKILL.md`
  - Prefer `app-store-screenshots`/`ios-marketing-capture`; only keep a short release checklist item for "screenshots validate in ASC".
- `archived-skills/expo-deployment/**`
  - Mine EAS build, submit, Android Play Store, and App Store metadata caveats into `release-ios-app/references/expo-eas.md` only after checking against current Expo/EAS docs. Much of it is generic upstream deployment guidance and should not be copied wholesale.

## Target Shape

Keep `release-ios-app` as a thin orchestrator with references:

```text
skills/release-ios-app/
  SKILL.md
  scripts/ios-release
  references/
    manifest.md
    native-xcodecloud.md
    expo-eas.md
    app-store-submit.md        # optional: iOS-specific wrapper around asc-release handoff
    testflight.md              # optional: groups/testers/What to Test, if used in real repos
    migration.md               # optional: setup checklist for existing repos
```

The skill should answer release questions in this order:

1. Read `.ios-release.env`.
2. Read `IOS_RELEASE_NOTES_FILE`.
3. Select the branch path from `IOS_RELEASE_BETA_BRANCH` and `IOS_RELEASE_RELEASE_BRANCH`.
4. Select the build-system reference from `IOS_RELEASE_BUILD_SYSTEM`.
5. Run the manifest helper for status/version checks.
6. Run repo tests from `IOS_RELEASE_TEST_CMDS`.
7. Confirm backend deploy requirements.
8. Wait for a `VALID` TestFlight build.
9. Route App Store readiness/submission to `asc-release`.
10. Route What's New to `asc-metadata`.

## Merge Order

1. **Normalize release-ios-app references.**
   - Add a "Related skills and boundaries" table to `release-ios-app/SKILL.md`.
   - Make every ASC handoff name current skills: `asc-release` and `asc-metadata`; remove stale names such as `asc-whats-new-writer`.
   - Keep this as a small docs-only PR because it changes selection behavior without moving content.

2. **Backfill missing current ASC readiness notes.**
   - Diff `archived-skills/asc-submission-health/SKILL.md` against `skills/asc-release/reference/release-flow.md`.
   - Move only still-current readiness blockers into `asc-release/reference/release-flow.md`.
   - Do not duplicate the same readiness checklist inside `release-ios-app`.

3. **Extract optional TestFlight distribution reference.**
   - If real repos use groups/testers/What to Test, create `release-ios-app/references/testflight.md`.
   - Source from `archived-skills/asc-testflight-orchestration/SKILL.md`, but rewrite around the golden rule: distribute the same build that will later be promoted.
   - Keep generic `asc` command conventions in `asc-release`.

4. **Tighten Expo/EAS reference.**
   - Compare `archived-skills/expo-deployment/references/{testflight,ios-app-store,play-store,workflows}.md` with current `release-ios-app/references/expo-eas.md`.
   - Pull only durable repo-release decisions into `expo-eas.md`: iOS submit fallback, Android production obligation when `IOS_RELEASE_ANDROID=true`, EAS build-number ownership, and metadata boundary.
   - Leave generic Expo deployment docs archived or plugin-provided.

5. **Align version guard with the manifest.**
   - Decide whether `.ios-release.env` should reference `asc-version-guard`'s `.asc-release.json` path or whether the guard should read `.ios-release.env` directly in a later implementation.
   - Until then, keep both manifests but document the duplication: app ID, source-of-truth version file, lookup country, protected branches.

6. **Repository rollout.**
   - For each iOS/Expo app repo, add or update `.ios-release.env` and `IOS_RELEASE_NOTES_FILE`.
   - Prefer repo-owned wrappers for project-specific build commands.
   - Do not remove repo-specific release notes until one dry-run release uses the global skill successfully.

## Repo-Specific Escape Hatches

Use escape hatches through `.ios-release.env` and `IOS_RELEASE_NOTES_FILE`, not by forking the global skill:

- `IOS_RELEASE_BUILD_SYSTEM`
  - Allows `xcodegen-xcodecloud` and `eas` today. Add new values only when at least one real repo needs them.
- `IOS_RELEASE_RELEASE_BRANCH` and `IOS_RELEASE_BETA_BRANCH`
  - Allows repos without `develop` by setting both to the same branch.
- `IOS_RELEASE_VERSION_CHECK_CMD`
  - Lets a repo keep a stronger local guard such as `pnpm run version:check`.
- `IOS_RELEASE_TEST_CMDS`
  - Keeps app-specific validation in the app repo.
- `IOS_RELEASE_BACKEND_DEPLOY`
  - Captures backend deploy gates without baking Convex or another provider into the release skill.
- `IOS_RELEASE_NOTES_FILE`
  - Stores Xcode Cloud workflow names, env-prefix quirks, build-number offsets, EAS submit fallbacks, Google Play hand steps, signing caveats, or review-account details.
- Repo-owned wrapper scripts
  - If a repo has a release wrapper, the skill should prefer it the same way `release-mac-app` prefers app-local `Scripts/mac-release`.

Do not use escape hatches for secrets. Manifest and notes files must remain safe to commit.

## Compatibility Risks

- **Skill trigger drift.** If `asc-release`, `asc-metadata`, `asc-version-guard`, or Expo deployment guidance still have broad release descriptions, agents may select the wrong entry point. Mitigation: make `release-ios-app` the orchestration trigger and make adjacent skills' descriptions emphasize subdomain work.
- **Duplicate version policy.** `release-ios-app` and `asc-release/reference/release-flow.md` both contain minor-vs-patch policy. Mitigation: keep the policy in `release-ios-app` for app releases; let `asc-release` retain a shorter fallback for direct ASC work, and avoid divergent wording.
- **Two manifest systems.** `.ios-release.env` and `.asc-release.json` duplicate app/version/branch data. Mitigation: document the duplication now; later decide whether `asc-version-guard` can consume `.ios-release.env` or whether the helper can validate parity.
- **Archived command staleness.** Archived ASC/Expo skills may contain commands that changed. Mitigation: any migration PR that copies commands must verify with `asc --help` or `eas --help` before unarchiving guidance.
- **Repo-specific release branches.** Some repos use `develop` for beta and `main` for production; some may not. Mitigation: use manifest branch keys, not hard-coded branch names.
- **Direct upload trap.** Old `asc publish appstore --ipa` guidance can conflict with the validated-TestFlight-build rule. Mitigation: route direct upload only through an explicit bypass path and require promoting the same uploaded build.
- **Android coupling for Expo.** Expo apps can be dual-platform. Mitigation: `IOS_RELEASE_ANDROID=true` means Android production work is part of release readiness, but Play Console steps remain repo-specific/manual unless a separate Android release skill is introduced.
- **Legal/privacy and pricing surfaces.** App Privacy, subscriptions, and pricing may block release but are not always safe for autonomous mutation. Mitigation: `release-ios-app` should list the blocker and route to `privacy-policy`, `asc-pricing`, or owner decision rather than silently changing them.

## Validation Plan For The Consolidation PRs

For docs-only consolidation:

- `bin/docs-list`
- `git diff --check`
- `npx -y markdownlint-cli2 <changed markdown files>`
- YAML/frontmatter parse for every edited `SKILL.md`
- `skills/autoreview/scripts/autoreview --mode branch --base origin/main`

For helper or manifest changes:

- `bash -n skills/release-ios-app/scripts/ios-release`
- Fixture-based `.ios-release.env` smoke test in a temporary git repo for:
  - missing manifest;
  - native `project.yml` version parse;
  - Expo `app.json` version parse;
  - live-version lookup unavailable path;
  - branch/status output.

For real app rollout:

- Run `./.agents/skills/release-ios-app/scripts/ios-release status` in each app repo.
- Run the repo's `IOS_RELEASE_VERSION_CHECK_CMD`.
- Run all commands in `IOS_RELEASE_TEST_CMDS`.
- Confirm `baseRefName` of release PR matches `IOS_RELEASE_RELEASE_BRANCH`.
- Confirm the build selected for App Store submission is already `VALID` in TestFlight.

## Recommendation

Do not archive or merge adjacent skills in one large patch. First, make `release-ios-app` the explicit orchestration router and clean stale handoff names. Then migrate archived ASC/Expo release fragments in small PRs only where they fill a current gap. Keep `asc-release`, `asc-metadata`, `asc-pricing`, `asc-version-guard`, and screenshot/privacy skills separate because they remain useful outside a routine iOS app release.
