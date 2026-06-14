---
name: asc-release
description: Build, version, upload, and submit iOS/macOS apps to App Store Connect with the `asc` CLI. Use to create an IPA/PKG, bump Xcode version/build numbers, run asc commands, drive the release/submission flow (including first-time fixes for availability, IAP, subscriptions, Game Center, App Privacy), or wire repeatable `asc workflow` automations into CI.
---

# asc release

Everything for getting a build from Xcode into App Store Connect and submitted for review, plus the `asc` CLI conventions and repo-local automation harness that underpin it. Read the focused reference file for the task at hand — each is self-contained.

## Pick the reference

| You are... | Read |
|---|---|
| Running or designing any `asc` command (flags, output, auth, pagination, discovery) | [`reference/cli-usage.md`](reference/cli-usage.md) |
| Building / archiving / exporting an IPA or PKG, or editing Xcode version & build numbers | [`reference/xcode-build.md`](reference/xcode-build.md) |
| Deciding if the app is ready and driving the submission flow (first-time availability/IAP/subscription/Game Center/App Privacy blockers) | [`reference/release-flow.md`](reference/release-flow.md) |
| Defining/validating/running `.asc/workflow.json` multi-step automations for local + CI | [`reference/workflow.md`](reference/workflow.md) |

## Typical end-to-end order

1. **Build** — archive + export the artifact and set a unique build number (`reference/xcode-build.md`).
2. **Verify readiness** — `asc submit preflight` / `asc release stage`, resolve blockers (`reference/release-flow.md`).
3. **Submit** — `asc release run --dry-run` then `--confirm` (`reference/release-flow.md`).
4. **Automate** — capture the repeatable parts in `.asc/workflow.json` (`reference/workflow.md`).

`reference/cli-usage.md` is the conventions layer the other three assume (verb choice, `--confirm` on destructive ops, JSON output, auth/timeout env vars). Skim it once if you're new to `asc`.

> Related: version/build-number collision prevention as an installable CI standard lives in the separate **asc-version-guard** skill. App-pricing and RevenueCat catalog work lives in **asc-pricing**. Metadata, ASO, and release notes live in **asc-metadata**.
