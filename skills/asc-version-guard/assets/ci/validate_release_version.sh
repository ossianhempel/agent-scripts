#!/bin/sh
# Version-gate that runs inside Xcode Cloud, branch-aware to match the
# two-workflow setup:
#
#   - non-release branches (develop, feature/*, hotfix/*): log only —
#     bumping MARKETING_VERSION every internal build is churn, and the
#     build number (asc-next) already keeps CFBundleVersion unique.
#   - protected release branches: STRICT — fail unless MARKETING_VERSION is
#     strictly greater than the live App Store version. Equal fails too;
#     this standard never auto-bumps (bump deliberately in project.yml).
#
# Override with <PROJECT>_SKIP_VERSION_VALIDATE=1 for a one-off hotfix.
# Local equivalent: scripts/check-marketing-version.sh.
set -eu

if [ "${CI_XCODE_CLOUD:-false}" != "true" ] && [ "${CI:-false}" != "TRUE" ]; then
  echo "Not in Xcode Cloud — skipping release version validation."
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/asc-version-lib.sh"

REPO_DIR="${CI_PRIMARY_REPOSITORY_PATH:-$(asc_find_root "$SCRIPT_DIR")}"
PROJECT_NAME="$(asc_cfg "$REPO_DIR" projectName)"

# Per-project skip env, e.g. PLATESNAP_SKIP_VERSION_VALIDATE.
skip_var="$(printf '%s' "$PROJECT_NAME" | tr '[:lower:]' '[:upper:]')_SKIP_VERSION_VALIDATE"
eval "skip_val=\${$skip_var:-0}"
if [ "$skip_val" = "1" ]; then
  echo "$skip_var=1 — skipping release version validation."
  exit 0
fi

# Restrict the strict gate to protected release branches.
protected="$(asc_cfg "$REPO_DIR" protectedBranches)"
ci_branch="${CI_BRANCH:-}"
is_protected=0
for b in $protected; do
  [ "$ci_branch" = "$b" ] && is_protected=1 && break
done
if [ "$is_protected" -eq 0 ]; then
  echo "Branch '$ci_branch' is not a protected release branch — skipping strict MARKETING_VERSION check."
  exit 0
fi

APP_APPLE_ID="$(asc_cfg "$REPO_DIR" appAppleId)"
LOOKUP_COUNTRY="$(asc_cfg "$REPO_DIR" lookupCountry)"
XCODEPROJ="$(asc_cfg "$REPO_DIR" xcodeprojPath)"
PROJECT_FILE="$REPO_DIR/$XCODEPROJ/project.pbxproj"
[ -f "$PROJECT_FILE" ] || asc_fail "Missing $PROJECT_FILE"

target_version="$(sed -n 's/.*MARKETING_VERSION = \([^;]*\);/\1/p' "$PROJECT_FILE" | head -n 1)"
[ -n "$target_version" ] || asc_fail "Could not parse MARKETING_VERSION from $PROJECT_FILE"
asc_validate_shape "$target_version"

live_version="$(asc_live_app_store_version "$APP_APPLE_ID" "$LOOKUP_COUNTRY")"
if [ -z "$live_version" ]; then
  printf 'MARKETING_VERSION %s (no live App Store version yet — OK)\n' "$target_version"
  exit 0
fi
asc_validate_shape "$live_version"

if [ "$(asc_compare "$target_version" "$live_version")" = "1" ]; then
  printf 'MARKETING_VERSION %s > live App Store %s (OK)\n' "$target_version" "$live_version"
  exit 0
fi

cat >&2 <<EOF
error: MARKETING_VERSION ($target_version) is not higher than the live App Store version ($live_version).

Bump MARKETING_VERSION in project.yml (run xcodegen) and push again.
Xcode Cloud won't build a release that collides with the live version.
EOF
exit 1
