#!/usr/bin/env bash
# Local guard: MARKETING_VERSION in the source-of-truth project.yml must be
# strictly higher than the version live on the App Store. Mirrors the strict
# check Xcode Cloud runs in ci/validate_release_version.sh, so a forgotten
# bump is caught before CI burns a build slot.
#
# Standard policy (converged across repos):
#   target  > live  -> OK
#   target == live  -> FAIL (bump deliberately; CI does not auto-bump)
#   target  < live  -> FAIL (rollback)
#
# Run via `pnpm run version:check` or the .githooks/pre-push hook.

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT_DIR/scripts/asc-version-lib.sh"

PROJECT_YML="$ROOT_DIR/$(asc_cfg "$ROOT_DIR" sourceOfTruth)"
APP_APPLE_ID="$(asc_cfg "$ROOT_DIR" appAppleId)"
LOOKUP_COUNTRY="$(asc_cfg "$ROOT_DIR" lookupCountry)"

[ -f "$PROJECT_YML" ] || asc_fail "Missing $PROJECT_YML"

target_version="$(asc_marketing_version_from_yml "$PROJECT_YML")"
[ -n "$target_version" ] || asc_fail "Could not parse MARKETING_VERSION from $PROJECT_YML"
asc_validate_shape "$target_version"

# Stale-project guard: Xcode Cloud builds the committed .pbxproj, but this hook
# reads project.yml. If they disagree, the dev bumped project.yml without
# regenerating — fail so the push can't ship a project CI will build with the
# old version. Skipped automatically when the .pbxproj isn't committed.
XCODEPROJ="$(asc_cfg "$ROOT_DIR" xcodeprojPath)"
PBXPROJ="$ROOT_DIR/$XCODEPROJ/project.pbxproj"
if [ -f "$PBXPROJ" ]; then
  pbxproj_version="$(sed -n 's/.*MARKETING_VERSION = \([^;]*\);/\1/p' "$PBXPROJ" | head -n 1)"
  pbxproj_version="${pbxproj_version%\"}"; pbxproj_version="${pbxproj_version#\"}"
  if [ -n "$pbxproj_version" ] && [ "$pbxproj_version" != "$target_version" ]; then
    cat >&2 <<EOF
error: MARKETING_VERSION is out of sync between source and the committed project:
  $(asc_cfg "$ROOT_DIR" sourceOfTruth): $target_version
  $XCODEPROJ/project.pbxproj: $pbxproj_version

Xcode Cloud builds the committed .pbxproj. Regenerate and commit it:
  (cd "\$(dirname "$PROJECT_YML")" && xcodegen)
  git add "$XCODEPROJ/project.pbxproj" && git commit
EOF
    exit 1
  fi
fi

if live_version="$(asc_live_app_store_version "$APP_APPLE_ID" "$LOOKUP_COUNTRY")"; then
  if [ -z "$live_version" ]; then
    printf 'MARKETING_VERSION %s (no live App Store version yet — OK)\n' "$target_version"
    exit 0
  fi
  asc_validate_shape "$live_version"
else
  # Lookup failed (offline / API error). Locally we warn and allow — the CI gate
  # (ci/validate_release_version.sh) fails closed and is the real enforcement.
  printf 'warning: could not reach the App Store to verify MARKETING_VERSION %s (lookup failed). Allowing push; Xcode Cloud enforces strictly.\n' "$target_version" >&2
  exit 0
fi

if [ "$(asc_compare "$target_version" "$live_version")" = "1" ]; then
  printf 'MARKETING_VERSION %s > live App Store %s (OK)\n' "$target_version" "$live_version"
  exit 0
fi

cat >&2 <<EOF
error: MARKETING_VERSION ($target_version) is not higher than the live App Store version ($live_version).

Fix before pushing — Xcode Cloud will reject the build otherwise:

  1. Edit $PROJECT_YML and bump MARKETING_VERSION above $live_version.
  2. (cd "\$(dirname $PROJECT_YML)" && xcodegen)
  3. Commit project.yml + the regenerated .xcodeproj/project.pbxproj.
EOF
exit 1
