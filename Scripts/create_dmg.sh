#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="/private/tmp/ArchivePeekDerivedData"
STAGING_DIR="$(mktemp -d /private/tmp/archivepeek-dmg.XXXXXX)"
DMG_PATH="$ROOT_DIR/dist/ArchivePeek-1.0.dmg"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
mkdir -p dist

xcodebuild \
  -project ArchivePeek.xcodeproj \
  -scheme ArchivePeek \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

ditto "$DERIVED_DATA_PATH/Build/Products/Release/ArchivePeek.app" "$STAGING_DIR/ArchivePeek.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname ArchivePeek \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created $DMG_PATH"
