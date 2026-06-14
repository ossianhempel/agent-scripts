# Native build & promote — XcodeGen + Xcode Cloud

For repos with `IOS_RELEASE_BUILD_SYSTEM="xcodegen-xcodecloud"` (PlateSnap, Shotly, Walkmon, and most native Swift apps).

## Version source & xcodegen

- `MARKETING_VERSION` (`CFBundleShortVersionString`) and `CURRENT_PROJECT_VERSION` (`CFBundleVersion`) live in `IOS_RELEASE_VERSION_SOURCE` (`ios/project.yml` or root `project.yml`) — **not** the generated `.xcodeproj`.
- After any version change **or any source file add/move/rename**, run `xcodegen` in `IOS_RELEASE_XCODEGEN_DIR` and **commit the regenerated `*.xcodeproj/project.pbxproj`**. Xcode Cloud builds the committed `.pbxproj`; if a repo's `ci_post_clone.sh` runs xcodegen it still expects a consistent committed project. Skipping the commit ships a stale project missing new Swift files → a wall of "Cannot find X in scope" build failures.

## Build number

- Xcode Cloud: `ci_scripts/set_xcode_cloud_build_number.sh` overwrites `CURRENT_PROJECT_VERSION` from `CI_BUILD_NUMBER` (some repos add an offset env var — see the repo notes file). Don't bump it manually for cloud archives.
- Local manual archive: set a new integer `CURRENT_PROJECT_VERSION` in the version source, run `xcodegen`, then archive. Never reuse a build number already in TestFlight.

## Channels

- Default mapping: `IOS_RELEASE_BETA_BRANCH` → TestFlight workflow, `IOS_RELEASE_RELEASE_BRANCH` → App Store workflow. Repos may expose `${IOS_RELEASE_ENV_PREFIX}_RELEASE_CHANNEL`, `_RELEASE_MARKETING_VERSION`, and branch-override env vars on the Xcode Cloud workflow for one-shot overrides.

## ⚠️ Archive distribution must be "TestFlight and App Store"

The single most common release-attach failure on native apps:

- A **TestFlight workflow** with Archive → Distribution = *Internal Testing Only* produces builds that appear `VALID` in `asc builds list` but are **pre-release builds**. The App Store version's build picker grays them out and `asc versions attach-build` rejects them: `409 Conflict: "The specified pre-release build could not be added."`
- The **Release workflow** (on the release branch) must have Archive → Distribution = *TestFlight and App Store*. Only its builds can attach to an App Store version.
- If an attach fails with that `409`, verify the producing workflow **first** before chasing pricing/availability/agreement causes.

## Local TestFlight candidate (bypass path)

Only when intentionally not using Xcode Cloud for the candidate:

```sh
# 1. set version/build in the version source, then:
cd "$IOS_RELEASE_XCODEGEN_DIR" && xcodegen
# 2. archive
xcodebuild -project <App>.xcodeproj -scheme <App> -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/<App>.xcarchive archive
# 3. export
xcodebuild -exportArchive -archivePath build/<App>.xcarchive \
  -exportOptionsPlist <ExportOptions-AppStore.plist> -exportPath build/export
# 4. upload that IPA (asc-xcode-build / asc publish testflight), then promote that same build.
```

`asc-xcode-build` covers archive/export/version-number helpers; use it only when producing a local candidate. The normal path is Xcode Cloud.

## Release config

- Production secrets for local Release builds live in an untracked `*.xcconfig` (e.g. `Config/Release.local.xcconfig`); Xcode Cloud generates one from workflow env vars instead. Exact required keys and validation rules are repo-specific — see the repo's `IOS_RELEASE_NOTES_FILE`.
- Confirm the Release config points at the environment you intend to ship before cutting a non-internal build.
