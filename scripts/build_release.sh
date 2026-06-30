#!/bin/zsh
set -euo pipefail

APP_NAME="猫猫熄屏"
ZIP_NAME="SleepyCat-Screen-Off-macOS.zip"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

set_plist_string() {
  local key="$1"
  local value="$2"
  /usr/libexec/PlistBuddy -c "Set :$key $value" "$APP_PATH/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :$key string $value" "$APP_PATH/Contents/Info.plist"
}

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

/usr/bin/osacompile -o "$APP_PATH" "$ROOT_DIR/src/Launcher.applescript"
cp "$ROOT_DIR/scripts/screenoff.sh" "$APP_PATH/Contents/Resources/screenoff.sh"
cp "$ROOT_DIR/assets/AppIcon.icns" "$APP_PATH/Contents/Resources/applet.icns"
rm -f "$APP_PATH/Contents/Resources/Assets.car"

set_plist_string "CFBundleIdentifier" "com.song.sleepycat-screen-off"
set_plist_string "CFBundleName" "$APP_NAME"
set_plist_string "CFBundleDisplayName" "$APP_NAME"
set_plist_string "CFBundleIconFile" "applet"
set_plist_string "CFBundleShortVersionString" "1.0.0"
set_plist_string "CFBundleVersion" "1"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$APP_PATH/Contents/Info.plist" 2>/dev/null || true

chmod 755 "$APP_PATH/Contents/Resources/screenoff.sh"

codesign --force --deep --sign - "$APP_PATH" >/dev/null
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Built: $APP_PATH"
echo "Release zip: $ZIP_PATH"
