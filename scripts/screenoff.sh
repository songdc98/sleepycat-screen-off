#!/bin/zsh
set -u

LOG_FILE="/tmp/sleepycat-screen-off-8h.log"
DURATION_SECONDS=28800

log() {
  /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}

if [[ "${SLEEPYCAT_DRY_RUN:-0}" == "1" ]]; then
  log "Dry run: fixed 8-hour mode"
  exit 0
fi

log "Starting simple fixed 8-hour display sleep mode"
/usr/bin/nohup /usr/bin/caffeinate -i -m -t "$DURATION_SECONDS" >> "$LOG_FILE" 2>&1 &
caffeinate_pid=$!
log "Started caffeinate process: $caffeinate_pid for ${DURATION_SECONDS}s"

/bin/sleep 1

/usr/bin/pmset displaysleepnow >> "$LOG_FILE" 2>&1
pmset_status=$?
log "Requested display sleep with status $pmset_status"
exit "$pmset_status"
