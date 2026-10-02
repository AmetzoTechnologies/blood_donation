#!/usr/bin/env bash
# Build and upload Donormate to App Store Connect / TestFlight.
#
# Versioning (automatic — no manual --build-number needed):
#   Default: auto-bump build (+N) by 1 in pubspec.yaml
#   --bump-version patch   → 1.0.2+12 → 1.0.3+13
#   --bump-version minor   → 1.0.2+12 → 1.1.0+13
#   --bump-version major   → 1.0.2+12 → 2.0.0+13
#   --no-bump              → use pubspec version as-is
#
# Usage:
#   ./script/release/upload_testflight.sh
#   ./script/release/upload_testflight.sh --bump-version patch
#   ./script/release/upload_testflight.sh --build-only
#   ./script/release/upload_testflight.sh --upload-only
#   ./script/release/upload_testflight.sh --skip-clean
#   APPLE_ID=you@email.com ./script/release/upload_testflight.sh
#
set -euo pipefail

APPLE_ID="${APPLE_ID:-faseencm0@gmail.com}"
KEYCHAIN_ITEM="${KEYCHAIN_ITEM:-AC_PASSWORD}"
BUNDLE_ID="com.amtzo.bloodDonation"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=./_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

IPA_DIR="${ROOT}/build/ios/ipa"
IPA_PATH=""
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

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
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

resolve_ipa_path() {
  if resolve_archived_artifact ios ipa; then
    IPA_PATH="${RELEASE_ARTIFACT_PATH}"
    return 0
  fi

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
    echo "Expected archived: ${OUTPUT_DIR}/ios/$(release_artifact_basename).ipa" >&2
    return 1
  fi
  if [[ "$count" -gt 1 ]]; then
    echo "Multiple .ipa files found in ${IPA_DIR}; using: ${found}" >&2
  fi

  IPA_PATH="$found"
  return 0
}

prepare_auth() {
  PASSWORD_ARG=""

  if [[ -n "${APP_SPECIFIC_PASSWORD:-}" ]]; then
    echo "==> Auth: APP_SPECIFIC_PASSWORD env"
    PASSWORD_ARG="@env:APP_SPECIFIC_PASSWORD"
    return
  fi

  if security find-generic-password -l "${KEYCHAIN_ITEM}" -a "${APPLE_ID}" >/dev/null 2>&1; then
    APP_SPECIFIC_PASSWORD="$(security find-generic-password -l "${KEYCHAIN_ITEM}" -a "${APPLE_ID}" -w)"
    export APP_SPECIFIC_PASSWORD
    echo "==> Auth: keychain item ${KEYCHAIN_ITEM} via @env"
    PASSWORD_ARG="@env:APP_SPECIFIC_PASSWORD"
    return
  fi

  echo "==> Auth: @keychain:${KEYCHAIN_ITEM}"
  PASSWORD_ARG="@keychain:${KEYCHAIN_ITEM}"
}

build_ipa() {
  echo "==> Building IPA (${BUILD_NAME}, build ${BUILD_NUMBER})"
  cd "${ROOT}"

  if [[ "$SKIP_CLEAN" != true ]]; then
    flutter clean
  fi

  flutter pub get
  (
    cd ios
    pod install
  )

  flutter build ipa --release \
    --build-name="${BUILD_NAME}" \
    --build-number="${BUILD_NUMBER}"

  if ! resolve_ipa_path; then
    exit 1
  fi

  archive_release_artifact "$IPA_PATH" ios ipa
  IPA_PATH="${RELEASE_ARTIFACT_PATH}"
}

upload_ipa() {
  if [[ -z "$IPA_PATH" ]] || [[ ! -f "$IPA_PATH" ]]; then
    if ! resolve_ipa_path; then
      echo "Run without --upload-only to build first." >&2
      exit 1
    fi
  fi

  prepare_auth

  echo "==> Uploading to App Store Connect as ${APPLE_ID}"
  echo "==> IPA: ${IPA_PATH}"
  xcrun altool --upload-app \
    -f "${IPA_PATH}" \
    -t ios \
    -u "${APPLE_ID}" \
    -p "${PASSWORD_ARG}"

  unset APP_SPECIFIC_PASSWORD || true

  echo ""
  echo "Upload submitted successfully."
  echo "Check TestFlight in App Store Connect in ~5-30 minutes."
  echo "Bundle ID: ${BUNDLE_ID}"
  echo "Version: ${BUILD_NAME} (${BUILD_NUMBER})"
}

main() {
  require_command flutter
  require_command xcrun
  read_pubspec_version
  maybe_bump_version_name true
  maybe_bump_local_build_number
  sync_version_from_pubspec

  if [[ "$UPLOAD_ONLY" == true ]]; then
    upload_ipa
    return
  fi

  build_ipa

  if [[ "$BUILD_ONLY" == true ]]; then
    return
  fi

  upload_ipa
}

main
