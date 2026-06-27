#!/bin/zsh
set -euo pipefail

APP_NAME="猫猫熄屏"
ZIP_NAME="SleepyCat-Screen-Off-macOS.zip"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources" "$DIST_DIR"

cp "$ROOT_DIR/src/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$ROOT_DIR/src/launcher.zsh" "$APP_PATH/Contents/MacOS/SleepyCatScreenOff"
cp "$ROOT_DIR/scripts/screenoff.sh" "$APP_PATH/Contents/Resources/screenoff.sh"
cp "$ROOT_DIR/assets/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
/usr/bin/clang -framework CoreFoundation -framework IOKit \
  "$ROOT_DIR/src/request_display_idle.c" \
  -o "$APP_PATH/Contents/Resources/request_display_idle"

chmod 755 "$APP_PATH/Contents/MacOS/SleepyCatScreenOff"
chmod 755 "$APP_PATH/Contents/Resources/screenoff.sh"
chmod 755 "$APP_PATH/Contents/Resources/request_display_idle"
printf "APPL????" > "$APP_PATH/Contents/PkgInfo"

codesign --force --deep --sign - "$APP_PATH" >/dev/null
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Built: $APP_PATH"
echo "Release zip: $ZIP_PATH"
