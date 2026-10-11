#!/usr/bin/env bash
set -e

TARGET_VERSION="$1"
if [ -z "$TARGET_VERSION" ]; then
  TARGET_VERSION=$(git describe --tags --exact-match 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

if [ -z "$TARGET_VERSION" ]; then
  echo "Usage: ./scripts/sync-version.sh <version-or-tag>"
  exit 1
fi

CLEAN_VERSION="${TARGET_VERSION#v}"
IFS='.' read -r MAJOR MINOR PATCH <<< "${CLEAN_VERSION%%-*}"
MAJOR=${MAJOR:-0}
MINOR=${MINOR:-0}
PATCH=${PATCH:-0}
BUILD_NUMBER=$(( MAJOR * 1000000 + MINOR * 1000 + PATCH ))

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PUBSPEC="$ROOT_DIR/pubspec.yaml"

if [ -f "$PUBSPEC" ]; then
  sed -i "s/^version: .*/version: ${CLEAN_VERSION}+${BUILD_NUMBER}/" "$PUBSPEC"
  echo "✓ pubspec.yaml -> ${CLEAN_VERSION}+${BUILD_NUMBER}"
else
  echo "Error: pubspec.yaml not found at $PUBSPEC"
  exit 1
fi

