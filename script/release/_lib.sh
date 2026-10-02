#!/usr/bin/env bash
# Shared helpers for Donormate release scripts.
# Source from upload_*.sh — do not run directly.
#
# Expects ROOT to be set by the caller (repo root).

PUBSPEC_PATH="${PUBSPEC_PATH:-${ROOT}/pubspec.yaml}"
APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-Donormate}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT}/output}"

release_artifact_basename() {
  echo "${APP_DISPLAY_NAME}_${BUILD_NAME}_${BUILD_NUMBER}"
}

# Copy a built artifact to output/<platform>/Donormate_X.Y.Z_N.<ext>
# Sets RELEASE_ARTIFACT_PATH to the destination path.
archive_release_artifact() {
  local src="$1"
  local platform="$2"
  local ext="$3"
  local dest dir basename

  if [[ ! -f "$src" ]]; then
    echo "Cannot archive missing file: ${src}" >&2
    return 1
  fi

  basename="$(release_artifact_basename)"
  dir="${OUTPUT_DIR}/${platform}"
  mkdir -p "$dir"
  dest="${dir}/${basename}.${ext}"
  cp "$src" "$dest"
  RELEASE_ARTIFACT_PATH="$dest"
  echo "==> Release artifact: ${dest}"
}

resolve_archived_artifact() {
  local platform="$1"
  local ext="$2"
  local dest

  dest="${OUTPUT_DIR}/${platform}/$(release_artifact_basename).${ext}"
  if [[ -f "$dest" ]]; then
    RELEASE_ARTIFACT_PATH="$dest"
    return 0
  fi
  return 1
}

# Re-read pubspec into BUILD_NAME / BUILD_NUMBER (clears cached values).
sync_version_from_pubspec() {
  BUILD_NAME=""
  BUILD_NUMBER=""
  read_pubspec_version
}

bundletool_jar() {
  local jar="${ROOT}/script/release/.tools/bundletool-all.jar"
  if [[ ! -f "$jar" ]]; then
    echo "==> Downloading bundletool for version verification..." >&2
    mkdir -p "$(dirname "$jar")"
    curl -fsSL \
      "https://github.com/google/bundletool/releases/download/1.17.2/bundletool-all-1.17.2.jar" \
      -o "$jar"
  fi
  printf '%s\n' "$jar"
}

# Fail if the AAB's embedded versionCode/versionName don't match what we built.
verify_aab_version() {
  local aab_path="$1"
  local expected_code="$2"
  local expected_name="$3"
  local jar manifest actual_code actual_name

  require_command java
  jar="$(bundletool_jar)"
  manifest="$(java -jar "$jar" dump manifest --bundle "$aab_path")"
  actual_code="$(sed -n 's/.*android:versionCode="\([0-9]*\)".*/\1/p' <<< "$manifest")"
  actual_name="$(sed -n 's/.*android:versionName="\([^"]*\)".*/\1/p' <<< "$manifest")"

  if [[ -z "$actual_code" || -z "$actual_name" ]]; then
    echo "Could not read version from AAB manifest" >&2
    exit 1
  fi

  if [[ "$actual_code" != "$expected_code" || "$actual_name" != "$expected_name" ]]; then
    echo "AAB version mismatch (filename can lie; Play reads the embedded manifest):" >&2
    echo "  Expected: ${expected_name} (${expected_code})" >&2
    echo "  In AAB:   ${actual_name} (${actual_code})" >&2
    echo "  File:     ${aab_path}" >&2
    exit 1
  fi

  echo "==> Verified AAB: ${expected_name} (${expected_code})"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

read_pubspec_version() {
  local version_line
  version_line="$(grep -E '^version:' "${PUBSPEC_PATH}" | head -1 | awk '{print $2}')"
  if [[ -z "$version_line" ]]; then
    echo "Could not read version from pubspec.yaml" >&2
    exit 1
  fi

  if [[ -z "${BUILD_NAME:-}" ]]; then
    BUILD_NAME="${version_line%%+*}"
  fi
  if [[ -z "${BUILD_NUMBER:-}" ]]; then
    BUILD_NUMBER="${version_line#*+}"
    if [[ "${BUILD_NUMBER}" == "$version_line" ]]; then
      echo "pubspec version must include a build number (example: 1.0.2+12)" >&2
      exit 1
    fi
  fi
}

write_pubspec_version() {
  local name="$1"
  local number="$2"
  local current_line new_line

  current_line="$(grep -E '^version:' "${PUBSPEC_PATH}" | head -1)"
  if [[ -z "$current_line" ]]; then
    echo "Could not find version: line in pubspec.yaml" >&2
    exit 1
  fi

  new_line="version: ${name}+${number}"
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^version: .*/${new_line}/" "${PUBSPEC_PATH}"
  else
    sed -i "s/^version: .*/${new_line}/" "${PUBSPEC_PATH}"
  fi

  echo "==> Updated pubspec.yaml: ${current_line#version: } → ${name}+${number}"
}

bump_semver_name() {
  local current="$1"
  local part="${2:-patch}"
  local major minor patch

  if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Version name must be X.Y.Z (got: ${current})" >&2
    exit 1
  fi

  IFS='.' read -r major minor patch <<< "$current"

  case "$part" in
    patch) patch=$((patch + 1)) ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    major) major=$((major + 1)); minor=0; patch=0 ;;
    *)
      echo "Invalid version bump: ${part} (use patch, minor, or major)" >&2
      exit 1
      ;;
  esac

  echo "${major}.${minor}.${patch}"
}

# Bump marketing version (patch|minor|major) and increment build number.
# Expects: VERSION_BUMP, BUILD_NAME, BUILD_NUMBER, PUBSPEC_PATH
# Optional flags: UPLOAD_ONLY, NO_BUMP, BUILD_NAME_EXPLICIT
maybe_bump_version_name() {
  local also_increment_build="${1:-true}"
  local old_name old_number

  if [[ -z "${VERSION_BUMP:-}" ]]; then
    return
  fi

  case "${VERSION_BUMP}" in
    patch|minor|major) ;;
    *)
      echo "Invalid --bump-version: ${VERSION_BUMP} (use patch, minor, or major)" >&2
      exit 1
      ;;
  esac

  if [[ "${UPLOAD_ONLY:-false}" == true ]]; then
    echo "Cannot use --bump-version with --upload-only." >&2
    exit 1
  fi

  if [[ "${BUILD_NAME_EXPLICIT:-false}" == true ]]; then
    echo "Cannot use --bump-version with --build-name (pick one)." >&2
    exit 1
  fi

  old_name="$BUILD_NAME"
  old_number="$BUILD_NUMBER"
  BUILD_NAME="$(bump_semver_name "$BUILD_NAME" "$VERSION_BUMP")"

  if [[ "$also_increment_build" == true &&
    "${NO_BUMP:-false}" != true &&
    "${BUILD_NUMBER_EXPLICIT:-false}" != true ]]; then
    BUILD_NUMBER=$((BUILD_NUMBER + 1))
  fi

  write_pubspec_version "$BUILD_NAME" "$BUILD_NUMBER"
  echo "==> Bumped version (${VERSION_BUMP}): ${old_name}+${old_number} → ${BUILD_NAME}+${BUILD_NUMBER}"
}

# Increment local build number (+1) in pubspec.yaml.
maybe_bump_local_build_number() {
  if [[ "${NO_BUMP:-false}" == true ]]; then
    echo "==> Skipping build auto-bump (--no-bump)"
    return
  fi
  if [[ "${BUILD_NUMBER_EXPLICIT:-false}" == true ]]; then
    echo "==> Skipping build auto-bump (explicit --build-number ${BUILD_NUMBER})"
    return
  fi
  if [[ "${UPLOAD_ONLY:-false}" == true ]]; then
    return
  fi
  if [[ -n "${VERSION_BUMP:-}" ]]; then
    # iOS/local: version bump already adjusted build when also_increment_build=true.
    return
  fi

  local new_build=$((BUILD_NUMBER + 1))
  BUILD_NUMBER="$new_build"
  write_pubspec_version "$BUILD_NAME" "$BUILD_NUMBER"
  echo "==> Auto-bumped build number → ${BUILD_NAME}+${BUILD_NUMBER}"
}

parse_bump_version_flag() {
  case "$1" in
    --bump-version)
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        VERSION_BUMP="$2"
        return 2
      fi
      VERSION_BUMP="patch"
      return 1
      ;;
  esac
  return 1
}
