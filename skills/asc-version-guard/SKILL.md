---
name: asc-version-guard
description: Install, repair, or diagnose the App Store Connect version/build-number guard for Xcode Cloud iOS apps so a wrong MARKETING_VERSION or colliding build number never reaches App Store Connect. Use when setting up release guards in a new iOS repo, fixing a missing or drifted pre-push/CI version check, or diagnosing why Xcode Cloud rejected a build for version/build-number reasons. Triggers include "add the version guard", "set up release hooks", "why did Xcode Cloud reject this build", "version check", "build number collision", MARKETING_VERSION.
---

# ASC version guard

One job: make "wire up or fix the release version/build-number guard" a consistent, one-shot operation across iOS repos, instead of copy-pasting and drifting scripts per repo (the failure mode that produced three divergent copies in platesnap/petalpal/walkmon).

Scope: **Xcode Cloud + xcodegen** repos (source of truth is `project.yml` → `.pbxproj`). EAS/Expo repos (e.g. gainslog) use a different mechanism — not covered here yet.

## The converged standard

| Decision | Standard | Why |
|---|---|---|
| `MARKETING_VERSION` == live App Store version | **Hard fail** | You always choose the shipped version; CI never silently auto-bumps. |
| Build number (`CURRENT_PROJECT_VERSION`) | **`CI_BUILD_NUMBER` + `buildNumberOffset`** | Dependency-free in CI: Xcode Cloud's monotonic counter is always unique, no asc CLI / creds / network to flake. `buildNumberOffset` (default 0) is a one-time static constant covering pre-Xcode-Cloud uploads. |
| Version comparison | shared `asc-version-lib.sh` | Single source for normalize/compare/validate — kills the per-repo drift. |
| Source of truth | `project.yml` `MARKETING_VERSION` | Xcode Cloud builds the committed `.pbxproj`; CI scripts patch it directly. |

Guard runs in two places, same logic:
- **Local** `pre-push` hook (`.githooks/pre-push` → `scripts/check-marketing-version.sh`) blocks pushes to protected branches before CI burns a slot.
- **CI** `ci_post_clone.sh` → `set_build_number.sh` (`CI_BUILD_NUMBER` + offset) then `validate_release_version.sh` (strict on protected branches, log-only elsewhere).

The version gate (local + CI) reads the live App Store version from the public iTunes lookup API via `curl`/`plutil` — no credentials. The build-number step needs nothing but the CI-injected `CI_BUILD_NUMBER`.

## Assets

- `assets/asc-version-lib.sh` — shared POSIX-sh helpers (`asc_normalize`, `asc_compare`, `asc_validate_shape`, `asc_live_app_store_version`, `asc_cfg`).
- `assets/check-marketing-version.sh` — local strict check.
- `assets/pre-push` — protected-branch git hook.
- `assets/ci/{ci_post_clone,set_build_number,validate_release_version}.sh` — Xcode Cloud scripts.
- `assets/.asc-release.json` — per-repo config template.
- `assets/install.sh` — copies everything in, wires `core.hooksPath`, prints follow-ups.

## Installing in a repo

1. Copy `assets/.asc-release.json` to the repo root and fill it:
   - `appAppleId` — numeric ASC app ID.
   - `projectName` — Xcode project name (used for `<PROJECT>.xcodeproj` and the per-project skip env var, e.g. `PLATESNAP_SKIP_VERSION_VALIDATE`).
   - `sourceOfTruth` — path to `project.yml` (e.g. `ios/project.yml` or `project.yml`).
   - `xcodeprojPath` — path to the `.xcodeproj` (e.g. `ios/PlateSnap.xcodeproj`).
   - `protectedBranches` — branches that get the strict gate (usually `["develop","main"]`).
   - `lookupCountry` — iTunes lookup storefront (`us`).
   - `buildNumberOffset` — `0` for new apps; for an app that had builds uploaded before Xcode Cloud, set it to the highest such build number so `CI_BUILD_NUMBER + offset` clears them.
2. Run `bash assets/install.sh <repo_root> [ci_scripts_dir]` (ci dir defaults to `ci_scripts`; pass `ios/ci_scripts` for repos that nest it).
3. Add the package.json convenience script: `"version:check": "bash scripts/check-marketing-version.sh"`.
4. Point the Xcode Cloud post-clone at `<ci_scripts_dir>/ci_post_clone.sh`. No CI secrets needed — the build number comes from `CI_BUILD_NUMBER` and the version gate uses the public iTunes lookup.

Re-running `install.sh` refreshes the lib + scripts in place — that's how you propagate a fix to all repos.

## Diagnosing a rejected build

Apple rejects a build when CFBundleShortVersionString or CFBundleVersion collide. Check in order:

1. **Live version**: `curl -fsSL "https://itunes.apple.com/lookup?id=<APPLE_ID>&country=us" | plutil -extract results.0.version raw -o - -`
2. **Committed marketing version**: `sed -n 's/.*MARKETING_VERSION = \([^;]*\);/\1/p' <xcodeproj>/project.pbxproj | head -1`
   - If committed ≤ live → bump `MARKETING_VERSION` in `project.yml`, run `xcodegen`, commit both.
3. **Build number collision**: confirm CI wrote `CI_BUILD_NUMBER + buildNumberOffset` into `CURRENT_PROJECT_VERSION`. If a build number was reused/too low, the offset is wrong — compare against the highest build already on TestFlight (`asc builds list` if you have the CLI) and set `buildNumberOffset` so the sum clears it.
4. **Hook actually installed?** `git config core.hooksPath` should print `.githooks`. If empty, the local guard never ran — run `install.sh` again.

## Migrating an existing repo

When converging a repo that has the old setup:
- Delete its bespoke `check-marketing-version.sh`, `validate_xcode_cloud_release.sh`, `set_xcode_cloud_build_number.sh`, and any `next-build-number.sh` after running the installer.
- walkmon: move `WALKMON_BUILD_NUMBER_OFFSET`'s value into `buildNumberOffset` in `.asc-release.json`, and drop its auto-bump-on-equal behavior (standard is hard-fail).
- petalpal: the installer adds the pre-push hook it was missing. `buildNumberOffset` is 0.
- Keep per-project env names working: the CI validator derives `<PROJECT>_SKIP_VERSION_VALIDATE` from `projectName`.
