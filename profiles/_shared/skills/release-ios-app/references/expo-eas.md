# Expo build & submit — EAS

For repos with `IOS_RELEASE_BUILD_SYSTEM="eas"` (GainsLog and other Expo apps). iOS and
Android share a single `expo.version`.

## Version source

- `expo.version` in `IOS_RELEASE_VERSION_SOURCE` (`app.json` / `app.config.*`) is the shared marketing version for both platforms. Apply the same MINOR/PATCH bump policy from the main skill.
- The build/version codes are managed by EAS (remote `appVersionSource` or local autoincrement, per the repo's `eas.json`). Never manually reuse a build number.

## Release notes

- Prefer the CI release-notes artifact (GitHub Actions) when on the release branch. Fallback: the repo's local changelog command (e.g. `pnpm run changelog:release`).
- If production tags are stale, do not paste generated notes verbatim — derive "What's New" from the actual commits since the last submitted App Store version, then run `asc-whats-new-writer`.

## iOS build & submit

- Submit through the repo's guarded command (e.g. `pnpm run submit:ios`), which typically wraps `eas build` + `eas submit` and **blocks re-submitting the same `expo.version`**.
- Ensure App Store Connect has a version record for the new marketing version before submitting; the guard intentionally fails when the ASC version is missing.
- **Treat EAS Submit success as binary-upload success only** — confirm the review-submission/version status in App Store Connect afterward.

### EAS Submit fallbacks

- If EAS Submit uploads the build but leaves the version in `PREPARE_FOR_SUBMISSION` / `READY_FOR_REVIEW`, drive the submission directly through the `asc` review flow rather than re-running EAS.
- If EAS Submit schedules but stalls without Apple receiving the build, fall back to a direct `asc` upload of the produced artifact — but still follow the golden rule (promote one build; don't double-upload a fresh IPA just for App Store).

## Android (when `IOS_RELEASE_ANDROID=true`)

- Android is **not optional** in a production release. Build Android locally and upload the artifact manually in Google Play Console.
- Do **not** queue an Android EAS production build unless the user explicitly asks.

## Post-submit bookkeeping

- Keep any repo "last submitted" marker accurate (e.g. `docs/last-ios-submitted.txt`) after a successful iOS review submission. Do not commit it when only the binary upload succeeded.
