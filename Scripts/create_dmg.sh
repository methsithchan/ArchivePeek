#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="/private/tmp/ArchivePeekDerivedData"
WORK_DIR="$(mktemp -d /private/tmp/archivepeek-dmg.XXXXXX)"
DMG_PATH="$ROOT_DIR/dist/ArchivePeek-1.0.dmg"
RW_DMG_PATH="$WORK_DIR/ArchivePeek-rw.dmg"
MOUNT_DIR="$WORK_DIR/mount"
VOLUME_NAME="ArchivePeek"
BACKGROUND_NAME="background.png"
BACKGROUND_SOURCE="${DMG_BACKGROUND:-$ROOT_DIR/ReleaseAssets/DMGBackground.png}"
WINDOW_WIDTH="${DMG_WINDOW_WIDTH:-800}"
WINDOW_HEIGHT="${DMG_WINDOW_HEIGHT:-480}"
ICON_SIZE="${DMG_ICON_SIZE:-128}"
APP_ICON_X="${DMG_APP_ICON_X:-196}"
APP_ICON_Y="${DMG_APP_ICON_Y:-268}"
APPLICATIONS_ICON_X="${DMG_APPLICATIONS_ICON_X:-612}"
APPLICATIONS_ICON_Y="${DMG_APPLICATIONS_ICON_Y:-268}"

cleanup() {
  if [[ -n "${MOUNT_DIR:-}" && -d "$MOUNT_DIR" ]]; then
    hdiutil detach "$MOUNT_DIR" -quiet || true
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
mkdir -p dist
mkdir -p "$MOUNT_DIR"

xcodebuild \
  -project ArchivePeek.xcodeproj \
  -scheme ArchivePeek \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

hdiutil create \
  "$RW_DMG_PATH" \
  -volname "$VOLUME_NAME" \
  -size 80m \
  -fs HFS+ \
  -ov

hdiutil attach "$RW_DMG_PATH" -readwrite -noverify -noautoopen -mountpoint "$MOUNT_DIR" >/dev/null

ditto "$DERIVED_DATA_PATH/Build/Products/Release/ArchivePeek.app" "$MOUNT_DIR/ArchivePeek.app"
ln -s /Applications "$MOUNT_DIR/Applications"
mkdir -p "$MOUNT_DIR/.background"

if [[ -f "$BACKGROUND_SOURCE" ]]; then
  cp "$BACKGROUND_SOURCE" "$MOUNT_DIR/.background/$BACKGROUND_NAME"
else
  echo "No custom DMG background found at $BACKGROUND_SOURCE"
  echo "Using generated fallback background."
  swift \
    -module-cache-path /private/tmp/archivepeek-module-cache \
    Tools/generate_dmg_background.swift \
    "$MOUNT_DIR/.background/$BACKGROUND_NAME"
fi

SetFile -a V "$MOUNT_DIR/.background" 2>/dev/null || true

osascript <<APPLESCRIPT
set mountedVolume to POSIX file "$MOUNT_DIR" as alias
set backgroundFile to POSIX file "$MOUNT_DIR/.background/$BACKGROUND_NAME" as alias
set windowWidth to $WINDOW_WIDTH
set windowHeight to $WINDOW_HEIGHT

tell application "Finder"
  open mountedVolume
  delay 1
  set dmgWindow to container window of mountedVolume
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set the bounds of dmgWindow to {100, 100, 100 + windowWidth, 100 + windowHeight}
  set theViewOptions to the icon view options of dmgWindow
  set arrangement of theViewOptions to not arranged
  set icon size of theViewOptions to $ICON_SIZE
  set background picture of theViewOptions to backgroundFile
  set position of item "ArchivePeek.app" of mountedVolume to {$APP_ICON_X, $APP_ICON_Y}
  set position of item "Applications" of mountedVolume to {$APPLICATIONS_ICON_X, $APPLICATIONS_ICON_Y}
  update mountedVolume without registering applications
  delay 1
  close dmgWindow
end tell
APPLESCRIPT

sync
hdiutil detach "$MOUNT_DIR" -quiet
MOUNT_DIR=""

hdiutil convert \
  "$RW_DMG_PATH" \
  -ov \
  -format UDZO \
  -o "$DMG_PATH"

echo "Created $DMG_PATH"
