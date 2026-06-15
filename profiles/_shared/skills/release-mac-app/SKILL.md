---
name: release-mac-app
description: "Release direct-download macOS apps with Sparkle appcasts, Developer ID signing, notarization, GitHub Releases, appcast verification, and release closeout. Use whenever a user mentions macOS release flow, Sparkle, appcast.xml, check for updates, notarization, Developer ID, GitHub release assets, or porting a CodexBar/RepoBar-style release setup."
---

# Mac App Release

Use for Completia and other direct-download Sparkle-updated macOS apps.
This is adapted from Peter Steinberger's `release-mac-app` skill for Ossian's
profile-scoped macOS app repos.

## Rules

- Work from the app repo.
- Read `.mac-release.env`; it is the repo-owned release manifest.
- Use `scripts/mac-release` from this skill for shared release/appcast/verify work.
  If the app repo has its own `Scripts/mac-release` wrapper, prefer that wrapper
  because it can add repo-specific Sparkle tool paths or feed publishing steps.
- Keep app-specific build/package/sign behavior in repo scripts unless it is already manifest-driven.
- Never print private key material.
- Prefer Keychain Sparkle signing. `SPARKLE_PRIVATE_KEY_FILE` is an explicit override only.

## Commands

```bash
./.agents/skills/release-mac-app/scripts/mac-release status
./.agents/skills/release-mac-app/scripts/mac-release notes [version] [output.md]
./.agents/skills/release-mac-app/scripts/mac-release changelog-html <version> [CHANGELOG.md]
./.agents/skills/release-mac-app/scripts/mac-release make-appcast <zip> [feed-url]
./.agents/skills/release-mac-app/scripts/mac-release verify-appcast [version]
./.agents/skills/release-mac-app/scripts/mac-release check-assets [tag]
./.agents/skills/release-mac-app/scripts/mac-release release
./.agents/skills/release-mac-app/scripts/mac-release codesign-run [--with-package-secrets] -- <command> [args...]
```

## Manifest

Each repo owns `.mac-release.env`. It must contain no secrets.

Required:

- `MAC_RELEASE_APP_NAME`
- `MAC_RELEASE_REPO`
- `MAC_RELEASE_BUNDLE_ID`
- `MAC_RELEASE_VERSION_FILE`
- `MAC_RELEASE_APPCAST`
- `MAC_RELEASE_FEED_URL`
- `MAC_RELEASE_DOWNLOAD_URL_PREFIX`
- `MAC_RELEASE_APP_ZIP`
- either `MAC_RELEASE_INFO_PLIST` or `MAC_RELEASE_SUPUBLIC_ED_KEY`
- `MAC_RELEASE_PACKAGE_CMD`

Common optional:

- `MAC_RELEASE_PRECHECK`
- `MAC_RELEASE_SOURCE_FILES` (space-separated app helper files to source before expanding artifact names)
- `MAC_RELEASE_SPARKLE_BIN_DIR` when Sparkle CLI tools are not on `PATH`
- `MAC_RELEASE_DSYM_ZIP`
- `MAC_RELEASE_REQUIRE_DSYM=0` for app-only releases
- `MAC_RELEASE_ARTIFACT_PREFIX`
- `MAC_RELEASE_TAG_SIGNED`
- `MAC_RELEASE_TAG_FORCE`
- `MAC_RELEASE_RELEASE_BRANCH`
- `MAC_RELEASE_SPARKLE_ACCOUNT`
- `MAC_RELEASE_SPARKLE_CHANNEL`
- `MAC_RELEASE_GENERATE_APPCAST_ARGS`
- `MAC_RELEASE_RUN_SPARKLE_UPDATE_TEST`
- `MAC_RELEASE_SIGNING_KEY_FILE` (local fallback path only; Keychain is used when the file is absent)
- `MAC_RELEASE_EXTRA_ASSET_PATTERNS`
- `MAC_RELEASE_EXTRA_ASSET_WAIT_SECONDS`
- `MAC_RELEASE_EXTRA_ASSET_WAIT_INTERVAL`
- `MAC_RELEASE_OP_ITEM` + `MAC_RELEASE_OP_FIELDS` for required packaging secrets. The release helper reads the known item once via `op` inside one persistent tmux session, then exports the requested fields for the package command.
- `MAC_RELEASE_OP_ACCOUNT` defaults to `my.1password.com`; `MAC_RELEASE_OP_VAULT`, `MAC_RELEASE_OP_TMUX_SESSION`, `MAC_RELEASE_OP_WAIT_SECONDS` are optional. Without a vault, service-account token env is unset for that single `op` read so the personal desktop account handles it.
- `MAC_RELEASE_CODESIGN_IDENTITY` + `MAC_RELEASE_CODESIGN_OP_ITEM` + `MAC_RELEASE_CODESIGN_KEYCHAIN_MANAGED=1` enable non-interactive Developer ID signing. The keychain must be replaceable, dedicated to release automation, separate from the default keychain, not shared with interactive use, and contain exactly one signing private key. The helper owns and may permanently normalize that key's partition ACL to `apple-tool:,apple:,codesign:`. After precheck, the same tmux credential pass reads `keychain_path` and `keychain_password`, takes a per-user release lock, supplies the password through a private file descriptor to a CLI PTY, prepends the keychain without hiding existing keychains, verifies a Developer ID Application canary, scopes package signing through a temporary `codesign --keychain` shim, then restores transient state, relocks, and releases the lock.
- `MAC_RELEASE_CODESIGN_OP_ACCOUNT`, `MAC_RELEASE_CODESIGN_OP_VAULT`, `MAC_RELEASE_CODESIGN_OP_USE_SERVICE_ACCOUNT`, `MAC_RELEASE_CODESIGN_OP_PATH_FIELD`, and `MAC_RELEASE_CODESIGN_OP_PASSWORD_FIELD` override the codesign credential item defaults; account, vault, and service-account mode otherwise inherit the primary item settings. Set vault empty and service-account mode `0` for a personal desktop-account item. `MAC_RELEASE_CODESIGN_KEYCHAIN` + `MAC_RELEASE_CODESIGN_KEYCHAIN_PASSWORD` may be supplied directly instead.
- `MAC_RELEASE_RUN_LOGIN_SHELL=1` opts command hooks back into `bash -lc`; default hooks use `env -u BASH_ENV bash -c` so shell startup files cannot override exported release secrets.

1Password rules:

- Prefer already-exported env vars first; no `op` call if all `MAC_RELEASE_OP_FIELDS` are present.
- If fields are missing, read configured package and codesign items in one tmux command for the whole release.
- Use service-account mode only with an explicit vault or `MAC_RELEASE_OP_USE_SERVICE_ACCOUNT=1`.
- Do not retry `op` reads in a fresh shell; rerun only from the same tmux session after explicit user direction.
- Never allow a release to reach app packaging with an unprepared Developer ID keychain. No SecurityAgent password windows during release; fail the signing canary first.
- For non-app release scripts, use `codesign-run` instead of copying keychain setup into the repository. Supply the codesign manifest fields through `.mac-release.env` or explicit `MAC_RELEASE_CODESIGN_*` environment configuration. It loads only codesign credentials by default; pass `--with-package-secrets` when the wrapped release script also needs the configured package/notary fields in the same 1Password pass. It runs the bounded signing canary, scopes `codesign` through the managed-keychain shim, and restores/relocks before returning.
- Disable shell xtrace and verbose mode before loading release secrets. Arm cleanup before keychain/search-list mutations, restore the dedicated keychain's original lock policy and user search list, and relock it after packaging.

## Done

- appcast entry has URL, length, Sparkle signature.
- downloaded enclosure verifies with Sparkle.
- extracted app passes `codesign`, `spctl`, and `stapler validate`.
- GitHub release has app zip, dSYM zip when configured, plus app-specific extra assets.
- release notes match the changelog section.
- after verified release, bump changelog to next patch `Unreleased` in the app repo.

## Ossian Notes

- For private source repos, keep the source private and publish `appcast.xml`
  through a small public feed repo/static host. Existing installs can only update
  from the `SUFeedURL` already embedded in their `Info.plist`.
- Do not treat every push to `main` as a public Sparkle release. Main should run
  build/test CI; an explicit release command should perform signing,
  notarization, appcast signing, asset upload, and verification.
- On this machine, the launcher prefers Apple's `/usr/bin/python3` for appcast
  XML parsing, and re-execs with Homebrew Bash when available so strict-mode
  array handling is reliable.
