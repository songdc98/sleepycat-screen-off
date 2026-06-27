#!/bin/zsh
set -u

LOG_FILE="/tmp/sleepycat-screen-off-8h.log"
DURATION_SECONDS=28800
START_DELAY_SECONDS=4
PMSET_BIN="${SLEEPYCAT_PMSET_BIN:-/usr/bin/pmset}"
SCRIPT_DIR="${0:A:h}"
DISPLAY_IDLE_BIN="${SLEEPYCAT_DISPLAY_IDLE_BIN:-$SCRIPT_DIR/request_display_idle}"
caffeinate_pid=""

log() {
  /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}

stop_caffeinate() {
  if [[ -n "$caffeinate_pid" ]] && /bin/kill -0 "$caffeinate_pid" 2>/dev/null; then
    /bin/kill "$caffeinate_pid" 2>/dev/null || true
    log "Stopped caffeinate process after failed display sleep request: $caffeinate_pid"
  fi
}

request_display_sleep_iokit() {
  local output status
  if [[ ! -x "$DISPLAY_IDLE_BIN" ]]; then
    log "IOKit display sleep helper is not executable: $DISPLAY_IDLE_BIN"
    return 1
  fi

  output="$("$DISPLAY_IDLE_BIN" 2>&1)"
  status=$?
  if [[ -n "$output" ]]; then
    log "IOKit output: $output"
  fi
  if [[ "$status" -eq 0 ]]; then
    log "Requested display sleep via IOKit"
    return 0
  fi

  log "IOKit display sleep request failed with status $status"
  return 1
}

request_display_sleep_pmset() {
  local output status
  output="$("$PMSET_BIN" displaysleepnow 2>&1)"
  status=$?
  if [[ -n "$output" ]]; then
    log "pmset output: $output"
  fi
  if [[ "$status" -eq 0 && "$output" != *"Failed"* && "$output" != *"failed"* && "$output" != *"error"* ]]; then
    log "Requested display sleep via pmset"
    return 0
  fi

  log "pmset display sleep request failed with status $status"
  return 1
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
  log "Display sleep attempt $attempt"
  if request_display_sleep_iokit; then
    exit 0
  fi
  if request_display_sleep_pmset; then
    exit 0
  fi
  /bin/sleep 2
done

stop_caffeinate
log "Could not put displays to sleep"
exit 1
