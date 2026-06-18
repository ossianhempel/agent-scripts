#!/bin/sh
# Xcode Cloud entry point. Runs right after clone, before package resolution.
# Order matters: set the build number first (CI_BUILD_NUMBER + offset), then
# gate the marketing version. No external deps — both scripts use only the
# CI-injected env, sed, curl/plutil (always present on macOS runners) and
# python3 for config parsing.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

sh "$SCRIPT_DIR/set_build_number.sh"
sh "$SCRIPT_DIR/validate_release_version.sh"
