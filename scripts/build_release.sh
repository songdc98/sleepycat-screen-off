#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"

set_plist_string() {
  local app_path="$1"
  local key="$2"
  local value="$3"
  /usr/libexec/PlistBuddy -c "Set :$key $value" "$app_path/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :$key string $value" "$app_path/Contents/Info.plist"
}

build_app() {
  local app_name="$1"
  local bundle_id="$2"
  local zip_name="$3"
  local app_path="$BUILD_DIR/$app_name.app"
  local zip_path="$DIST_DIR/$zip_name"

  /usr/bin/osacompile -o "$app_path" "$ROOT_DIR/src/Launcher.applescript"
  cp "$ROOT_DIR/scripts/screenoff.sh" "$app_path/Contents/Resources/screenoff.sh"
  cp "$ROOT_DIR/assets/AppIcon.icns" "$app_path/Contents/Resources/applet.icns"
  rm -f "$app_path/Contents/Resources/Assets.car"

  set_plist_string "$app_path" "CFBundleIdentifier" "$bundle_id"
  set_plist_string "$app_path" "CFBundleName" "$app_name"
  set_plist_string "$app_path" "CFBundleDisplayName" "$app_name"
  set_plist_string "$app_path" "CFBundleIconFile" "applet"
  set_plist_string "$app_path" "CFBundleShortVersionString" "1.0.0"
  set_plist_string "$app_path" "CFBundleVersion" "1"
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$app_path/Contents/Info.plist" 2>/dev/null || true

  chmod 755 "$app_path/Contents/Resources/screenoff.sh"

  codesign --force --deep --sign - "$app_path" >/dev/null
  ditto -c -k --sequesterRsrc --keepParent "$app_path" "$zip_path"

  echo "Built: $app_path"
  echo "Release zip: $zip_path"
}

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

build_app "SleepyCat Screen Off" "com.song.sleepycat-screen-off.en" "SleepyCat-Screen-Off-macOS.zip"
build_app "猫猫熄屏" "com.song.sleepycat-screen-off" "MaoMao-Screen-Off-macOS.zip"
