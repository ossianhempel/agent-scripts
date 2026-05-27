#!/usr/bin/env bash
# Install / update the ASC version guard in a target repo.
#
#   install.sh <repo_root> [ci_scripts_dir]
#
#   <repo_root>       absolute path to the target repo
#   [ci_scripts_dir]  CI scripts dir relative to repo root
#                     (default: ci_scripts; some repos use ios/ci_scripts)
#
# Prereqs: <repo_root>/.asc-release.json already exists and is filled in
# (appAppleId, projectName, sourceOfTruth, xcodeprojPath, protectedBranches,
# lookupCountry). Copy assets/.asc-release.json there and edit it first.
#
# Idempotent: re-running refreshes the shared lib + scripts in place.

set -euo pipefail

ASSET_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${1:?usage: install.sh <repo_root> [ci_scripts_dir]}"
CI_DIR_REL="${2:-ci_scripts}"

[ -f "$REPO_ROOT/.asc-release.json" ] || {
  echo "error: $REPO_ROOT/.asc-release.json not found — copy and fill assets/.asc-release.json first." >&2
  exit 1
}

mkdir -p "$REPO_ROOT/scripts" "$REPO_ROOT/.githooks" "$REPO_ROOT/$CI_DIR_REL"

# Shared lib goes next to BOTH the local scripts and the CI scripts so each
# can source it with a relative path (CI runners only check out the repo).
cp "$ASSET_DIR/asc-version-lib.sh"        "$REPO_ROOT/scripts/asc-version-lib.sh"
cp "$ASSET_DIR/asc-version-lib.sh"        "$REPO_ROOT/$CI_DIR_REL/asc-version-lib.sh"
cp "$ASSET_DIR/check-marketing-version.sh" "$REPO_ROOT/scripts/check-marketing-version.sh"
cp "$ASSET_DIR/pre-push"                  "$REPO_ROOT/.githooks/pre-push"
cp "$ASSET_DIR/ci/ci_post_clone.sh"       "$REPO_ROOT/$CI_DIR_REL/ci_post_clone.sh"
cp "$ASSET_DIR/ci/set_build_number.sh"    "$REPO_ROOT/$CI_DIR_REL/set_build_number.sh"
cp "$ASSET_DIR/ci/validate_release_version.sh" "$REPO_ROOT/$CI_DIR_REL/validate_release_version.sh"

chmod +x "$REPO_ROOT/scripts/check-marketing-version.sh" \
         "$REPO_ROOT/.githooks/pre-push" \
         "$REPO_ROOT/$CI_DIR_REL/ci_post_clone.sh" \
         "$REPO_ROOT/$CI_DIR_REL/set_build_number.sh" \
         "$REPO_ROOT/$CI_DIR_REL/validate_release_version.sh"

git -C "$REPO_ROOT" config core.hooksPath .githooks

echo "Installed ASC version guard into $REPO_ROOT (ci dir: $CI_DIR_REL)."
echo "Next:"
echo "  - Add a package.json script:  \"version:check\": \"bash scripts/check-marketing-version.sh\""
echo "  - Point the Xcode Cloud workflow's post-clone at $CI_DIR_REL/ci_post_clone.sh"
echo "  - Ensure asc CLI + ASC_* creds are available in ci_post_clone.sh (see its header)."
