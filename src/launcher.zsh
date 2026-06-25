#!/bin/zsh
set -u

APP_DIR="${0:A:h:h}"
SCREENOFF_SCRIPT="$APP_DIR/Resources/screenoff.sh"

/bin/zsh "$SCREENOFF_SCRIPT" >/tmp/sleepycat-screen-off-launch.log 2>&1 &
exit 0
