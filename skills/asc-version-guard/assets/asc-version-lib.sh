# shellcheck shell=sh
# asc-version-lib.sh — shared version/build-number helpers for the ASC release guard.
#
# POSIX sh. Source it; do not execute. Every per-repo script (local pre-push
# check + Xcode Cloud CI scripts) sources this single file so the
# normalize / compare / validate logic never drifts between copies.
#
#   . "$(dirname "$0")/asc-version-lib.sh"   # CI scripts live alongside the lib
#   . "$ROOT_DIR/scripts/asc-version-lib.sh" # local scripts point at it
#
# Reads repo config from .asc-release.json at the repo root via asc_cfg().

asc_fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

asc_require_tool() {
  command -v "$1" >/dev/null 2>&1 || asc_fail "Missing required tool: $1"
}

# asc_find_root <start_dir> — walk up from start_dir until .asc-release.json
# is found; print that dir. Robust regardless of how deep the CI scripts nest.
asc_find_root() {
  _dir="$1"
  while [ "$_dir" != "/" ]; do
    [ -f "$_dir/.asc-release.json" ] && { printf '%s\n' "$_dir"; return; }
    _dir="$(dirname "$_dir")"
  done
  asc_fail "Could not find .asc-release.json walking up from $1"
}

# asc_cfg <root_dir> <json_key> — read a top-level string key from .asc-release.json.
# Array keys (protectedBranches) print space-separated.
asc_cfg() {
  _root="$1"; _key="$2"
  _file="$_root/.asc-release.json"
  [ -f "$_file" ] || asc_fail "Missing $_file (run the asc-version-guard installer)"
  asc_require_tool python3
  python3 - "$_file" "$_key" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
val = data.get(sys.argv[2])
if val is None:
    sys.exit(f"asc-release.json missing key: {sys.argv[2]}")
print(" ".join(val) if isinstance(val, list) else val)
PY
}

# asc_cfg_opt <root_dir> <json_key> <default> — like asc_cfg but returns
# <default> when the key is absent (for optional fields like buildNumberOffset).
asc_cfg_opt() {
  _root="$1"; _key="$2"; _default="$3"
  _file="$_root/.asc-release.json"
  [ -f "$_file" ] || { printf '%s\n' "$_default"; return; }
  asc_require_tool python3
  python3 - "$_file" "$_key" "$_default" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
val = data.get(sys.argv[2], sys.argv[3])
print(" ".join(val) if isinstance(val, list) else val)
PY
}

# asc_validate_shape <version> — must look like 1.2 or 1.2.3.
asc_validate_shape() {
  printf '%s' "$1" | grep -Eq '^[0-9]+(\.[0-9]+){1,2}$' \
    || asc_fail "Version must look like 1.2 or 1.2.3, got: $1"
}

# asc_normalize "1.2" -> "1 2 0"
asc_normalize() {
  asc_validate_shape "$1"
  _old_ifs="$IFS"; IFS=.; set -- $1; IFS="$_old_ifs"
  printf '%s %s %s\n' "${1:-0}" "${2:-0}" "${3:-0}"
}

# asc_compare <left> <right> — prints -1 / 0 / 1 for left<right / == / left>right.
asc_compare() {
  set -- $(asc_normalize "$1") $(asc_normalize "$2")
  _lM="$1"; _lm="$2"; _lp="$3"; _rM="$4"; _rm="$5"; _rp="$6"
  if [ "$_lM" -gt "$_rM" ]; then echo 1; return; fi
  if [ "$_lM" -lt "$_rM" ]; then echo -1; return; fi
  if [ "$_lm" -gt "$_rm" ]; then echo 1; return; fi
  if [ "$_lm" -lt "$_rm" ]; then echo -1; return; fi
  if [ "$_lp" -gt "$_rp" ]; then echo 1; return; fi
  if [ "$_lp" -lt "$_rp" ]; then echo -1; return; fi
  echo 0
}

# asc_marketing_version_from_yml <project.yml> — first MARKETING_VERSION: "x.y.z".
asc_marketing_version_from_yml() {
  sed -nE 's/^[[:space:]]*MARKETING_VERSION:[[:space:]]*"([^"]+)".*/\1/p' "$1" | head -n 1
}

# asc_live_app_store_version <apple_id> <country>
# Prints the live App Store version, or empty if the app isn't live yet.
# Exits nonzero only on a hard tooling failure (handled by callers).
asc_live_app_store_version() {
  asc_require_tool curl
  asc_require_tool plutil
  _url="https://itunes.apple.com/lookup?id=${1}&country=${2}"
  _json="$(curl -fsSL "$_url" 2>/dev/null || true)"
  _count="$(printf '%s' "$_json" | plutil -extract resultCount raw -o - - 2>/dev/null || echo 0)"
  [ "${_count:-0}" = "0" ] && return 0   # not live yet -> empty, not an error
  printf '%s' "$_json" | plutil -extract results.0.version raw -o - - 2>/dev/null || true
}
