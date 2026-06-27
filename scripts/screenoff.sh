#!/bin/zsh
set -u

LOG_FILE="/tmp/sleepycat-screen-off-8h.log"
DURATION_SECONDS=28800
START_DELAY_SECONDS=4
PMSET_BIN="${SLEEPYCAT_PMSET_BIN:-/usr/bin/pmset}"

log() {
  /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}

if [[ "${SLEEPYCAT_DRY_RUN:-0}" == "1" ]]; then
  log "Dry run: fixed 8-hour mode"
  exit $?
fi

log "Starting fixed 8-hour display sleep mode"
/usr/bin/caffeinate -i -m -t "$DURATION_SECONDS" >> "$LOG_FILE" 2>&1 &
caffeinate_pid=$!
log "Started caffeinate process: $caffeinate_pid for ${DURATION_SECONDS}s"

/bin/sleep "$START_DELAY_SECONDS"

for attempt in 1 2 3 4; do
  pmset_output="$("$PMSET_BIN" displaysleepnow 2>&1)"
  pmset_status=$?
  if [[ -n "$pmset_output" ]]; then
    log "pmset output on attempt $attempt: $pmset_output"
  fi
  if [[ "$pmset_status" -eq 0 && "$pmset_output" != *"Failed"* && "$pmset_output" != *"failed"* && "$pmset_output" != *"error"* ]]; then
    log "Requested display sleep on attempt $attempt"
    exit 0
  fi
  log "Display sleep request failed on attempt $attempt with status $pmset_status"
  /bin/sleep 2
done

log "Could not put displays to sleep"
exit 1
