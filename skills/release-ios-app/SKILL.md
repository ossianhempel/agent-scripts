---
name: release-ios-app
description: "Release iOS (and Expo iOS/Android) apps to TestFlight and the App Store — version-bump policy, develop→main promotion PR, build via Xcode Cloud or EAS, the version-must-exceed-live gate, promote-the-validated-build golden rule, backend deploy safeguard, and App Store submission via the asc flow. Use whenever a user mentions an iOS/Expo release, cutting a build, bumping MARKETING_VERSION or expo.version, shipping to TestFlight, submitting to App Store review, or troubleshooting the release flow for PlateSnap, Shotly, Walkmon, GainsLog, or any app with a .ios-release.env manifest."
---

# iOS App Release

One release flow for all of Ossian's iOS apps. The shared decision/submission logic lives
here; each repo owns a `.ios-release.env` manifest with its app-specific values and a
`references/`-style notes file for genuine repo gotchas. This mirrors `release-mac-app`
(global skill + repo-owned `.mac-release.env`).

## Rules

- Work from the app repo.
- Read `.ios-release.env` first — it is the repo-owned release manifest (no secrets).
- Then read the file named by `IOS_RELEASE_NOTES_FILE` for repo-unique gotchas **before** making release moves.
- Branch the build mechanics on `IOS_RELEASE_BUILD_SYSTEM`:
  - `xcodegen-xcodecloud` → [`references/native-xcodecloud.md`](references/native-xcodecloud.md)
  - `eas` → [`references/expo-eas.md`](references/expo-eas.md)
- Keep app-specific build/sign/upload behavior in repo scripts / the relevant CLI (`xcodebuild`, `xcodegen`, `eas`, `asc`). This skill orchestrates; it does not re-implement them.
- **Never auto-merge the `develop` → `main` release PR.** Open it, then stop and wait for Ossian to merge.
- Never print secrets or key material.
- Final App Store readiness and submission run through the `asc` release flow (the `asc-release` / `asc-release-flow` skill). What's New copy goes through `asc-whats-new-writer`.

## Version-bump policy (decide this first)

`MARKETING_VERSION` (native) / `expo.version` (Expo) is `MAJOR.MINOR.PATCH`. Pick the bump from what the release actually contains:

- **User-facing changes → bump MINOR**, reset PATCH to 0 (`1.4.2` → `1.5.0`). Anything a user can see or feel: new/changed features, new screens or flows, redesigned UI, user-visible copy, onboarding/paywall changes.
- **Non-user-facing changes → bump PATCH** (`1.4.2` → `1.4.3`). Bug fixes, performance/refactor work, internal tooling, dependency bumps, build/CI/signing config, and App Store **metadata-only** updates.
- **MAJOR** is reserved for deliberate large releases — never bump it automatically, only when explicitly asked.

If a release mixes both, the user-facing change wins → bump MINOR. **State the chosen bump and the reason before editing the version source** (e.g. `"user-facing: new export templates → minor, 1.4.2 → 1.5.0"`). The build number (`CFBundleVersion` / `CURRENT_PROJECT_VERSION`) always increases on every upload regardless of which part you bump; never reuse one.

## Decision tree

1. **Determine the target.**
   - **TestFlight / beta** — normally from `IOS_RELEASE_BETA_BRANCH`. Keep the current release train unless intentionally starting the next one.
   - **App Store / production** — first promote the candidate from `IOS_RELEASE_BETA_BRANCH` to `IOS_RELEASE_RELEASE_BRANCH` through a PR. Do **not** begin ASC submission while required release changes only exist on the beta branch. (If the manifest sets the two branches equal — e.g. Walkmon before it has `develop` — skip the promotion PR and treat the release branch as both.)

2. **Decide the version bump** (policy above) before opening the release PR. Continuing the current unreleased train → keep the version. Starting the next train → bump now, then for `xcodegen` repos run `xcodegen` in `IOS_RELEASE_XCODEGEN_DIR` and commit the regenerated `*.xcodeproj/project.pbxproj`.

3. **Open the `develop` → `main` release PR, then stop.** Include the version bump and user-facing changes. Inspect CI/checks, code-review comments, and conflicts. If checks fail or review flags a risk, explain and fix before asking Ossian to merge. Ask Ossian to merge manually; continue only after he confirms.

4. **Validate readiness.** Run `IOS_RELEASE_VERSION_CHECK_CMD` (or `scripts/ios-release check-version`) — the selected version must be strictly greater than the live App Store version. Run `IOS_RELEASE_TEST_CMDS` for the changed surface when practical.

5. **Backend safeguard.** If `IOS_RELEASE_BACKEND_DEPLOY=convex`, confirm the production Convex deploy from the release branch has completed **before** shipping a binary that depends on backend changes. Don't ship against backend code that hasn't reached production.

6. **Build & distribute** — follow the build-system reference file.

7. **Promote & submit** — see the golden rule below, then drive submission with the `asc` flow.

## Golden rule: promote the validated TestFlight build

App Store submissions must **attach an already-uploaded, `VALID` TestFlight build** for the same version train — never a fresh direct App Store IPA upload. A second direct upload can reserve/consume the `CFBundleVersion` that Xcode Cloud / EAS is about to use, causing `PrepareBuildForAppStoreConnect` failures or `409` attach conflicts. Safe sequence: merge the release PR → let Xcode Cloud/EAS archive+upload the candidate → wait until the build is `VALID` in App Store Connect → distribute → attach that build to the App Store version → submit for review. Only upload a local IPA when intentionally bypassing CI for the TestFlight candidate, and then promote that same build.

## Submission

1. Confirm the version source matches the version you intend to submit.
2. Pick the uploaded, `VALID` TestFlight build to ship.
3. Use `asc-whats-new-writer` to draft/update What's New before submission. If tags are stale, derive notes from the actual commits since the last submitted App Store version.
4. Hand off to the `asc` release/submission flow to attach the build and run readiness (`asc validate`, screenshots, availability, IAP/subscriptions, App Privacy). **Never create the final review submission without explicit go-ahead.** If a command asks for an IPA path during App Store submission, stop and switch to the attach-existing-build path.

## Pitfalls

- **GitHub auth.** A `Repository not found` fetch/push error is usually the wrong active GitHub account, not a remote-URL problem — run `gh auth status` (or `gh auth switch`) before touching remotes.
- **Build-number reuse.** Never reuse a build number already in TestFlight.
- **Direct-upload trap.** See the golden rule — don't upload a second IPA just for App Store submission.
- **Pre-release-only builds (native).** An Xcode Cloud Archive set to *Internal Testing Only* shows as `VALID` but the App Store build picker grays it out and attach fails with `409 pre-release build`. The release workflow's Archive must be *TestFlight and App Store*. See `references/native-xcodecloud.md`.
- **Android (Expo).** For dual-platform Expo apps (`IOS_RELEASE_ANDROID=true`), Android is not optional in a production release — build it and upload to Google Play Console. See `references/expo-eas.md`.

## Commands

```bash
/Users/ossianhempel/Developer/agent-scripts/skills/release-ios-app/scripts/ios-release status
/Users/ossianhempel/Developer/agent-scripts/skills/release-ios-app/scripts/ios-release check-version [version]
/Users/ossianhempel/Developer/agent-scripts/skills/release-ios-app/scripts/ios-release live-version
```

## Manifest & references

- `.ios-release.env` schema and an annotated example: [`references/manifest.md`](references/manifest.md).
- Native (XcodeGen + Xcode Cloud) build/promote mechanics: [`references/native-xcodecloud.md`](references/native-xcodecloud.md).
- Expo / EAS build/submit + Android: [`references/expo-eas.md`](references/expo-eas.md).

## Done

- Release PR merged by Ossian; release branch has the version bump and user-facing changes.
- Selected build is `VALID` in App Store Connect and attached to the target version.
- `asc` readiness is clean (or only understood non-blocking warnings); What's New matches the shipped commits.
- Backend production deploy (when applicable) completed before the binary shipped.
- For Expo dual-platform: Android artifact uploaded to Play Console.
