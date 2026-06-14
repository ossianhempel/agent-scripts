# `.ios-release.env` manifest

Each iOS app repo owns a `.ios-release.env` at its root. It is a `KEY=value` shell file
(sourced, not executed) and **must contain no secrets** — only paths, IDs, commands, and
flags. The global `release-ios-app` skill and `scripts/ios-release` read it.

## Keys

| Key | Required | Meaning |
|---|---|---|
| `IOS_RELEASE_APP_ID` | yes | App Store Connect app Apple ID (numeric), used for the live-version lookup and `asc`. |
| `IOS_RELEASE_BUNDLE_ID` | yes | App bundle identifier. |
| `IOS_RELEASE_BUILD_SYSTEM` | yes | `xcodegen-xcodecloud` or `eas`. Selects the build reference + mechanics. |
| `IOS_RELEASE_VERSION_SOURCE` | yes | Path (repo-relative) to the file owning the marketing version: `ios/project.yml`, `project.yml`, `app.json`, or `app.config.*`. |
| `IOS_RELEASE_XCODEGEN_DIR` | xcodegen only | Dir to run `xcodegen` in (`ios` or `.`). Empty/unset for non-xcodegen. |
| `IOS_RELEASE_RELEASE_BRANCH` | yes | App Store channel branch (usually `main`). |
| `IOS_RELEASE_BETA_BRANCH` | yes | TestFlight channel branch (usually `develop`). Set equal to the release branch if the repo has no develop branch yet. |
| `IOS_RELEASE_VERSION_CHECK_CMD` | optional | Repo command that enforces version > live (e.g. `pnpm run version:check`). `scripts/ios-release check-version` is the manifest-driven fallback. |
| `IOS_RELEASE_TEST_CMDS` | optional | `;`-separated test commands to run for changed surfaces. |
| `IOS_RELEASE_BACKEND_DEPLOY` | optional | `convex` or `none`. If `convex`, confirm prod deploy before shipping. |
| `IOS_RELEASE_ENV_PREFIX` | optional | Xcode Cloud env-override prefix (e.g. `PLATESNAP`, `WALKMON`). |
| `IOS_RELEASE_APPSTORE_LOOKUP_COUNTRY` | optional | iTunes lookup storefront, default `us`. |
| `IOS_RELEASE_CONTACT_EMAIL` | optional | Public/App-Review contact email for the listing. |
| `IOS_RELEASE_ANDROID` | optional | `true` for Expo dual-platform apps that must also ship Android. Default `false`. |
| `IOS_RELEASE_NOTES_FILE` | optional | Repo-relative path to the repo-gotchas notes file the flow reads first. |

## Annotated example (native, PlateSnap)

```sh
# .ios-release.env — repo-owned iOS release manifest. NO SECRETS.
IOS_RELEASE_APP_ID="6759206859"
IOS_RELEASE_BUNDLE_ID="com.ossianhempel.platesnap"
IOS_RELEASE_BUILD_SYSTEM="xcodegen-xcodecloud"
IOS_RELEASE_VERSION_SOURCE="ios/project.yml"
IOS_RELEASE_XCODEGEN_DIR="ios"
IOS_RELEASE_RELEASE_BRANCH="main"
IOS_RELEASE_BETA_BRANCH="develop"
IOS_RELEASE_VERSION_CHECK_CMD="pnpm run version:check"
IOS_RELEASE_TEST_CMDS="pnpm run test:convex; pnpm run test:ios"
IOS_RELEASE_BACKEND_DEPLOY="convex"
IOS_RELEASE_ENV_PREFIX="PLATESNAP"
IOS_RELEASE_APPSTORE_LOOKUP_COUNTRY="us"
IOS_RELEASE_CONTACT_EMAIL="hemposse@gmail.com"
IOS_RELEASE_ANDROID="false"
IOS_RELEASE_NOTES_FILE=".ios-release-notes.md"
```

## Annotated example (Expo, GainsLog)

```sh
IOS_RELEASE_APP_ID="<app-store-apple-id>"
IOS_RELEASE_BUNDLE_ID="com.ossianhempel.gainslog"
IOS_RELEASE_BUILD_SYSTEM="eas"
IOS_RELEASE_VERSION_SOURCE="app.json"        # expo.version
IOS_RELEASE_RELEASE_BRANCH="main"
IOS_RELEASE_BETA_BRANCH="develop"
IOS_RELEASE_VERSION_CHECK_CMD="pnpm run submit:ios"   # blocks re-submitting the same expo.version
IOS_RELEASE_TEST_CMDS="pnpm test; pnpm run test:convex"
IOS_RELEASE_BACKEND_DEPLOY="convex"
IOS_RELEASE_APPSTORE_LOOKUP_COUNTRY="us"
IOS_RELEASE_ANDROID="true"
IOS_RELEASE_NOTES_FILE=".ios-release-notes.md"
```

## Notes file (`IOS_RELEASE_NOTES_FILE`)

Holds only the **non-shared** repo knowledge — environment caveats, distribution traps,
secret-validation rules, build-number offsets, EAS-Submit fallbacks. The shared flow lives
in the global skill; do not duplicate it here. Keep it short.
