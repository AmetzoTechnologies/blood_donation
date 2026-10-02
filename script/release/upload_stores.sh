#!/usr/bin/env bash
# Build and upload Donormate to both stores.
#
# Versioning (automatic):
#   Default: Android Play sets +N, iOS reuses same pubspec (no double bump)
#   --bump-version patch|minor|major  → marketing version suffix bump
#   --no-bump                         → use pubspec as-is
#
# Usage:
#   ./script/release/upload_stores.sh
#   ./script/release/upload_stores.sh --bump-version patch
#   ./script/release/upload_stores.sh --bump-version minor
#   ./script/release/upload_stores.sh --track internal
#   ./script/release/upload_stores.sh --ios-only
#   ./script/release/upload_stores.sh --android-only
#   ./script/release/upload_stores.sh --build-only
#   ./script/release/upload_stores.sh --upload-only
#   ./script/release/upload_stores.sh --no-bump
#   ./script/release/upload_stores.sh --ios-first
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=./_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

PLAY_SCRIPT="${SCRIPT_DIR}/upload_play_console.sh"
IOS_SCRIPT="${SCRIPT_DIR}/upload_testflight.sh"
PUBSPEC_PATH="${ROOT}/pubspec.yaml"

UPLOAD_ONLY=false
BUILD_ONLY=false
SKIP_CLEAN=false
NO_BUMP=false
IOS_ONLY=false
ANDROID_ONLY=false
IOS_FIRST=false
VERSION_BUMP=""
TRACK="internal"

usage() {
  sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upload-only) UPLOAD_ONLY=true; shift ;;
    --build-only) BUILD_ONLY=true; shift ;;
    --skip-clean) SKIP_CLEAN=true; shift ;;
    --no-bump) NO_BUMP=true; shift ;;
    --ios-only) IOS_ONLY=true; shift ;;
    --android-only) ANDROID_ONLY=true; shift ;;
    --ios-first) IOS_FIRST=true; shift ;;
    --bump-version)
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        VERSION_BUMP="$2"
        shift 2
      else
        VERSION_BUMP="patch"
        shift
      fi
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

if [[ "$IOS_ONLY" == true && "$ANDROID_ONLY" == true ]]; then
  echo "Use either --ios-only or --android-only, not both." >&2
  exit 1
fi

if [[ -n "$VERSION_BUMP" ]]; then
  case "$VERSION_BUMP" in
    patch|minor|major) ;;
    *)
      echo "Invalid --bump-version: ${VERSION_BUMP} (use patch, minor, or major)" >&2
      exit 1
      ;;
  esac
fi

case "$TRACK" in
  internal|alpha|beta|production) ;;
  *)
    echo "Invalid --track: ${TRACK} (use internal, alpha, beta, or production)" >&2
    exit 1
    ;;
esac

read_pubspec_version_line() {
  local version_line
  version_line="$(grep -E '^version:' "${PUBSPEC_PATH}" | head -1 | awk '{print $2}')"
  if [[ -z "$version_line" ]]; then
    echo "Could not read version from pubspec.yaml" >&2
    exit 1
  fi
  echo "${version_line%%+*} ${version_line#*+}"
}

run_android() {
  local -a args=()
  local skip_clean="$1"
  local pass_version_bump="$2"

  args+=(--track "${TRACK}")

  if [[ "$UPLOAD_ONLY" == true ]]; then
    args+=(--upload-only)
  elif [[ "$BUILD_ONLY" == true ]]; then
    args+=(--build-only)
  fi
  if [[ "$skip_clean" == true ]]; then
    args+=(--skip-clean)
  fi
  if [[ "$NO_BUMP" == true ]]; then
    args+=(--no-bump)
  fi
  if [[ "$pass_version_bump" == true && -n "$VERSION_BUMP" ]]; then
    args+=(--bump-version "${VERSION_BUMP}")
  fi

  echo ""
  echo "======== Google Play ========"
  "${PLAY_SCRIPT}" ${args[@]+"${args[@]}"}
}

run_ios() {
  local -a args=()
  local skip_clean="$1"
  local pass_version_bump="$2"

  if [[ "$UPLOAD_ONLY" == true ]]; then
    args+=(--upload-only)
  elif [[ "$BUILD_ONLY" == true ]]; then
    args+=(--build-only)
  fi
  if [[ "$skip_clean" == true ]]; then
    args+=(--skip-clean)
  fi
  if [[ "$NO_BUMP" == true ]]; then
    args+=(--no-bump)
  elif [[ "$pass_version_bump" != true ]]; then
    # Android already bumped pubspec; don't double-bump on iOS.
    args+=(--no-bump)
  fi
  if [[ "$pass_version_bump" == true && -n "$VERSION_BUMP" ]]; then
    args+=(--bump-version "${VERSION_BUMP}")
  fi

  echo ""
  echo "======== App Store / TestFlight ========"
  "${IOS_SCRIPT}" ${args[@]+"${args[@]}"}
}

main() {
  if [[ ! -x "$PLAY_SCRIPT" ]]; then
    echo "Missing or not executable: ${PLAY_SCRIPT}" >&2
    exit 1
  fi
  if [[ ! -x "$IOS_SCRIPT" ]]; then
    echo "Missing or not executable: ${IOS_SCRIPT}" >&2
    exit 1
  fi

  local name number

  if [[ "$ANDROID_ONLY" == true ]]; then
    run_android "$SKIP_CLEAN" true
    echo ""
    echo "Done (Android only)."
    return
  fi

  if [[ "$IOS_ONLY" == true ]]; then
    run_ios "$SKIP_CLEAN" true
    echo ""
    echo "Done (iOS only)."
    return
  fi

  if [[ "$IOS_FIRST" == true ]]; then
    run_ios "$SKIP_CLEAN" true
    read -r name number <<< "$(read_pubspec_version_line)"
    run_android true false
  else
    run_android "$SKIP_CLEAN" true
    read -r name number <<< "$(read_pubspec_version_line)"
    run_ios true false
  fi

  read -r name number <<< "$(read_pubspec_version_line)"
  echo ""
  echo "======== Both stores complete ========"
  echo "Version: ${name}+${number}"
  echo "Play track: ${TRACK}"
  echo "TestFlight: check App Store Connect in ~5-30 minutes"
}

main
