#!/bin/zsh
set -u

APP_DIR="${0:A:h:h}"
SCREENOFF_SCRIPT="$APP_DIR/Resources/screenoff.sh"
LAUNCH_LOG="/tmp/sleepycat-screen-off-launch.log"

/bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') Launching fixed 8-hour display sleep script: $SCREENOFF_SCRIPT" >> "$LAUNCH_LOG"
/bin/zsh "$SCREENOFF_SCRIPT" >> "$LAUNCH_LOG" 2>&1
exit $?
