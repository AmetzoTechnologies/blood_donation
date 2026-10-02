#!/usr/bin/env bash
# Build Donormate release artifacts locally (no store upload).
#
# Outputs versioned files under output/:
#   output/android/Donormate_1.0.2_13.aab
#   output/android/Donormate_1.0.2_13.apk
#   output/ios/Donormate_1.0.2_13.ipa
#
# Versioning (automatic):
#   Default: auto-bump build (+N) by 1 in pubspec.yaml
#   --bump-version patch|minor|major  → marketing version + build bump
#   --no-bump                         → use pubspec as-is
#
# Usage:
#   ./build_release.sh              # AAB + IPA
#   ./build_release.sh ios
#   ./build_release.sh android      # AAB
#   ./build_release.sh apk          # APK
#   ./build_release.sh --bump-version patch
#   ./build_release.sh --skip-clean
#   ./build_release.sh --no-bump
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=script/release/_lib.sh
source "${ROOT}/script/release/_lib.sh"

PUBSPEC_PATH="${ROOT}/pubspec.yaml"
AAB_FLUTTER_PATH="${ROOT}/build/app/outputs/bundle/release/app-release.aab"
APK_FLUTTER_PATH="${ROOT}/build/app/outputs/flutter-apk/app-release.apk"
IPA_DIR="${ROOT}/build/ios/ipa"

TARGET="all"
SKIP_CLEAN=false
NO_BUMP=false
BUILD_NAME=""
BUILD_NUMBER=""
VERSION_BUMP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    ios|android|apk|all)
      TARGET="$1"
      shift
      ;;
    --skip-clean)
      SKIP_CLEAN=true
      shift
      ;;
    --no-bump)
      NO_BUMP=true
      shift
      ;;
    --bump-version)
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        VERSION_BUMP="$2"
        shift 2
      else
        VERSION_BUMP="patch"
        shift
      fi
      ;;
    -h|--help)
      sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

prepare_project() {
  cd "${ROOT}"

  if [[ "$SKIP_CLEAN" != true ]]; then
    flutter clean
  fi

  flutter pub get

  if [[ "$TARGET" == "ios" || "$TARGET" == "all" ]]; then
    (
      cd ios
      pod install
    )
  fi
}

resolve_flutter_ipa_path() {
  local found=""
  local count=0

  if [[ ! -d "$IPA_DIR" ]]; then
    echo "IPA directory not found: ${IPA_DIR}" >&2
    return 1
  fi

  while IFS= read -r -d '' file; do
    found="$file"
    count=$((count + 1))
  done < <(find "${IPA_DIR}" -maxdepth 1 -type f -name '*.ipa' -print0 2>/dev/null)

  if [[ "$count" -eq 0 ]]; then
    echo "No .ipa found in: ${IPA_DIR}" >&2
    return 1
  fi

  echo "$found"
}

build_ios() {
  echo "==> Building iOS IPA (${BUILD_NAME}, build ${BUILD_NUMBER})"
  flutter build ipa --release \
    --build-name="${BUILD_NAME}" \
    --build-number="${BUILD_NUMBER}"

  local flutter_ipa
  flutter_ipa="$(resolve_flutter_ipa_path)"
  archive_release_artifact "$flutter_ipa" ios ipa
}

build_android_aab() {
  echo "==> Building Android AAB (${BUILD_NAME}, build ${BUILD_NUMBER})"
  flutter build appbundle --release \
    --build-name="${BUILD_NAME}" \
    --build-number="${BUILD_NUMBER}"

  if [[ ! -f "$AAB_FLUTTER_PATH" ]]; then
    echo "AAB not found at: ${AAB_FLUTTER_PATH}" >&2
    exit 1
  fi

  verify_aab_version "$AAB_FLUTTER_PATH" "$BUILD_NUMBER" "$BUILD_NAME"
  archive_release_artifact "$AAB_FLUTTER_PATH" android aab
}

build_android_apk() {
  echo "==> Building Android APK (${BUILD_NAME}, build ${BUILD_NUMBER})"
  flutter build apk --release \
    --build-name="${BUILD_NAME}" \
    --build-number="${BUILD_NUMBER}"

  if [[ ! -f "$APK_FLUTTER_PATH" ]]; then
    echo "APK not found at: ${APK_FLUTTER_PATH}" >&2
    exit 1
  fi

  archive_release_artifact "$APK_FLUTTER_PATH" android apk
}

require_command flutter
read_pubspec_version
maybe_bump_version_name true
maybe_bump_local_build_number
sync_version_from_pubspec
prepare_project

case "$TARGET" in
  ios) build_ios ;;
  android) build_android_aab ;;
  apk) build_android_apk ;;
  all)
    build_android_aab
    build_ios
    ;;
  *)
    echo "Unknown target: ${TARGET} (use ios, android, apk, or all)" >&2
    exit 1
    ;;
esac

echo ""
echo "Done. Version ${BUILD_NAME}+${BUILD_NUMBER}"
echo "Artifacts: ${OUTPUT_DIR}/"
