#!/bin/sh
# CI build-number strategy: CI_BUILD_NUMBER + buildNumberOffset (converged standard).
#
# Xcode Cloud injects a monotonic integer CI_BUILD_NUMBER per workflow run, so
# CFBundleVersion is unique without any external dependency — no asc CLI, no
# ASC_* creds, no network round-trip to fail on. We write it straight into the
# committed .pbxproj (Xcode Cloud builds the checked-in project as-is).
#
# buildNumberOffset (in .asc-release.json, default 0) covers the one-time case
# where builds were uploaded BEFORE Xcode Cloud took over: set it to the highest
# pre-existing build number so CI_BUILD_NUMBER + offset clears them. It's a
# static migration constant, not an ongoing dependency.
#
# Optional MARKETING_VERSION override: caller resolves <PROJECT>_RELEASE_MARKETING_VERSION
# into MARKETING_VERSION_OVERRIDE to promote a marketing version without a commit.
set -eu

if [ "${CI_XCODE_CLOUD:-false}" != "true" ] && [ "${CI:-false}" != "TRUE" ]; then
  echo "Not in Xcode Cloud — skipping build-number sync."
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/asc-version-lib.sh"

REPO_DIR="${CI_PRIMARY_REPOSITORY_PATH:-$(asc_find_root "$SCRIPT_DIR")}"
PROJECT_NAME="$(asc_cfg "$REPO_DIR" projectName)"
XCODEPROJ="$(asc_cfg "$REPO_DIR" xcodeprojPath)"
OFFSET="$(asc_cfg_opt "$REPO_DIR" buildNumberOffset 0)"
PROJECT_FILE="$REPO_DIR/$XCODEPROJ/project.pbxproj"
[ -f "$PROJECT_FILE" ] || asc_fail "Missing $PROJECT_FILE"

BUILD_NUMBER="${CI_BUILD_NUMBER:-}"
[ -n "$BUILD_NUMBER" ] || asc_fail "CI_BUILD_NUMBER is unset; cannot prepare a unique CFBundleVersion."
case "$BUILD_NUMBER" in *[!0-9]* ) asc_fail "CI_BUILD_NUMBER must be an integer, got: $BUILD_NUMBER" ;; esac
case "${OFFSET:-0}" in *[!0-9]* ) asc_fail "buildNumberOffset must be a non-negative integer, got: $OFFSET" ;; esac

BUILD_NUMBER=$((BUILD_NUMBER + ${OFFSET:-0}))

MARKETING_VERSION_OVERRIDE="${MARKETING_VERSION_OVERRIDE:-}"
if [ -n "$MARKETING_VERSION_OVERRIDE" ]; then
  asc_validate_shape "$MARKETING_VERSION_OVERRIDE"
  sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $MARKETING_VERSION_OVERRIDE;/g" "$PROJECT_FILE"
  echo "Set MARKETING_VERSION to $MARKETING_VERSION_OVERRIDE in $PROJECT_FILE"
fi

sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" "$PROJECT_FILE"
echo "Set CURRENT_PROJECT_VERSION to $BUILD_NUMBER (CI_BUILD_NUMBER + offset ${OFFSET:-0}) for $PROJECT_NAME"
