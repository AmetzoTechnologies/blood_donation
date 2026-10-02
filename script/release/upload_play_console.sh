#!/usr/bin/env bash
# Build and upload Donormate to Google Play Console.
#
# Versioning (automatic — no manual --build-number needed):
#   Default: auto-bump build (+N) from Play Console highest versionCode + 1
#   --bump-version patch   → 1.0.2 → 1.0.3 (then Play sets +N)
#   --bump-version minor   → 1.0.2 → 1.1.0 (then Play sets +N)
#   --bump-version major   → 1.0.2 → 2.0.0 (then Play sets +N)
#   --no-bump              → use pubspec version as-is
#
# Usage:
#   ./script/release/upload_play_console.sh
#   ./script/release/upload_play_console.sh --bump-version patch
#   ./script/release/upload_play_console.sh --track internal
#   ./script/release/upload_play_console.sh --build-only
#   ./script/release/upload_play_console.sh --upload-only
#   ./script/release/upload_play_console.sh --no-bump
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=./_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

AAB_FLUTTER_PATH="${ROOT}/build/app/outputs/bundle/release/app-release.aab"
AAB_PATH="${AAB_FLUTTER_PATH}"
DEFAULT_JSON_KEY="${ROOT}/android/play-service-account.json"
PLAY_JSON_KEY="${PLAY_JSON_KEY:-${DEFAULT_JSON_KEY}}"
PUBSPEC_PATH="${ROOT}/pubspec.yaml"

UPLOAD_ONLY=false
BUILD_ONLY=false
SKIP_CLEAN=false
NO_BUMP=false
BUILD_NAME=""
BUILD_NUMBER=""
BUILD_NAME_EXPLICIT=false
BUILD_NUMBER_EXPLICIT=false
VERSION_BUMP=""
TRACK="internal"

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upload-only) UPLOAD_ONLY=true; shift ;;
    --build-only) BUILD_ONLY=true; shift ;;
    --skip-clean) SKIP_CLEAN=true; shift ;;
    --no-bump) NO_BUMP=true; shift ;;
    --bump-version)
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        VERSION_BUMP="$2"
        shift 2
      else
        VERSION_BUMP="patch"
        shift
      fi
      ;;
    --build-name)
      BUILD_NAME="${2:-}"
      BUILD_NAME_EXPLICIT=true
      shift 2
      ;;
    --build-number)
      BUILD_NUMBER="${2:-}"
      BUILD_NUMBER_EXPLICIT=true
      shift 2
      ;;
    --track)
      TRACK="${2:-}"
      shift 2
      ;;
    -h|--help) usage 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage 1
      ;;
  esac
done

if [[ "$UPLOAD_ONLY" == true && "$BUILD_ONLY" == true ]]; then
  echo "Use either --upload-only or --build-only, not both." >&2
  exit 1
fi

if [[ -n "$VERSION_BUMP" && "$BUILD_NAME_EXPLICIT" == true ]]; then
  echo "Cannot use --bump-version with --build-name (pick one)." >&2
  exit 1
fi

case "$TRACK" in
  internal|alpha|beta|production) ;;
  *)
    echo "Invalid --track: ${TRACK} (use internal, alpha, beta, or production)" >&2
    exit 1
    ;;
esac

require_play_json_key() {
  if [[ ! -f "$PLAY_JSON_KEY" ]]; then
    echo "Play service-account JSON not found at: ${PLAY_JSON_KEY}" >&2
    echo "Set PLAY_JSON_KEY or place the key at android/play-service-account.json" >&2
    exit 1
  fi
}

fetch_play_max_version_code() {
  local track output result codes max code
  max=0

  for track in internal alpha beta production; do
    output="$(
      FASTLANE_OPT_OUT_USAGE=1 FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_DISABLE_COLORS=1 \
        fastlane run google_play_track_version_codes \
          package_name:"${PACKAGE_NAME}" \
          track:"${track}" \
          json_key:"${PLAY_JSON_KEY}" 2>&1
    )" || true

    result="$(printf '%s\n' "$output" | grep -E 'Result: \[' | tail -1 || true)"
    if [[ -z "$result" ]]; then
      continue
    fi

    codes="$(printf '%s\n' "$result" | sed -n 's/.*Result: \[\(.*\)\]/\1/p' | tr ',' ' ')"
    if [[ -z "$codes" ]]; then
      continue
    fi

    for code in $codes; do
      if [[ "$code" =~ ^[0-9]+$ ]] && (( code > max )); then
        max=$code
      fi
    done
  done

  echo "$max"
}

maybe_bump_play_build_number() {
  local play_max

  if [[ "$NO_BUMP" == true ]]; then
    echo "==> Skipping Play build auto-bump (--no-bump)"
    return
  fi
  if [[ "$BUILD_NUMBER_EXPLICIT" == true ]]; then
    echo "==> Skipping Play build auto-bump (explicit --build-number ${BUILD_NUMBER})"
    return
  fi
  if [[ "$UPLOAD_ONLY" == true ]]; then
    return
  fi

  require_play_json_key
  echo "==> Checking Play Console version codes..."
  play_max="$(fetch_play_max_version_code)"
  echo "==> Highest Play versionCode: ${play_max}"
  echo "==> Current pubspec build: ${BUILD_NUMBER}"

  if (( BUILD_NUMBER <= play_max )); then
    BUILD_NUMBER=$((play_max + 1))
    write_pubspec_version "$BUILD_NAME" "$BUILD_NUMBER"
    echo "==> Play auto-bump → ${BUILD_NAME}+${BUILD_NUMBER}"
  else
    echo "==> pubspec build ${BUILD_NUMBER} is already higher than Play (${play_max})"
  fi
}

build_aab() {
  echo "==> Building AAB (${BUILD_NAME}, build ${BUILD_NUMBER})"
  cd "${ROOT}"

  if [[ "$SKIP_CLEAN" != true ]]; then
    flutter clean
  fi

  flutter pub get

  flutter build appbundle --release \
    --build-name="${BUILD_NAME}" \
    --build-number="${BUILD_NUMBER}"

  if [[ ! -f "$AAB_FLUTTER_PATH" ]]; then
    echo "AAB not found at: ${AAB_FLUTTER_PATH}" >&2
    exit 1
  fi

  verify_aab_version "$AAB_FLUTTER_PATH" "$BUILD_NUMBER" "$BUILD_NAME"
  archive_release_artifact "$AAB_FLUTTER_PATH" android aab
  AAB_PATH="${RELEASE_ARTIFACT_PATH}"
}

resolve_aab_path() {
  if resolve_archived_artifact android aab; then
    AAB_PATH="${RELEASE_ARTIFACT_PATH}"
    return 0
  fi

  if [[ -f "$AAB_FLUTTER_PATH" ]]; then
    AAB_PATH="$AAB_FLUTTER_PATH"
    return 0
  fi

  echo "AAB not found. Expected:" >&2
  echo "  ${OUTPUT_DIR}/android/$(release_artifact_basename).aab" >&2
  echo "  or ${AAB_FLUTTER_PATH}" >&2
  return 1
}

upload_aab() {
  if [[ ! -f "$AAB_PATH" ]]; then
    if ! resolve_aab_path; then
      echo "Run without --upload-only to build first." >&2
      exit 1
    fi
  fi

  require_play_json_key

  echo "==> Uploading to Play Console (${TRACK}) as ${PACKAGE_NAME}"
  fastlane supply \
    --package_name "${PACKAGE_NAME}" \
    --aab "${AAB_PATH}" \
    --json_key "${PLAY_JSON_KEY}" \
    --track "${TRACK}" \
    --skip_upload_metadata \
    --skip_upload_images \
    --skip_upload_screenshots \
    --skip_upload_changelogs

  echo ""
  echo "Upload submitted successfully."
  echo "Check Play Console → ${TRACK} track."
  echo "Package: ${PACKAGE_NAME}"
  echo "Version: ${BUILD_NAME} (${BUILD_NUMBER})"
}

main() {
  require_command flutter
  require_command fastlane
  read_pubspec_version
  # Marketing version first; Play sets the build number (+N).
  maybe_bump_version_name false

  if [[ "$UPLOAD_ONLY" == true || "$BUILD_ONLY" != true ]]; then
    require_play_json_key
  elif [[ "$NO_BUMP" != true && "$BUILD_NUMBER_EXPLICIT" != true ]]; then
    require_play_json_key
  fi

  maybe_bump_play_build_number
  sync_version_from_pubspec

  if [[ "$UPLOAD_ONLY" == true ]]; then
    upload_aab
    return
  fi

  build_aab

  if [[ "$BUILD_ONLY" == true ]]; then
    return
  fi

  upload_aab
}

main
