#!/bin/zsh
set -u

LOG_FILE="/tmp/sleepycat-screen-off-8h.log"
DURATION_SECONDS=28800
START_DELAY_SECONDS="${SLEEPYCAT_START_DELAY_SECONDS:-4}"
PMSET_BIN="${SLEEPYCAT_PMSET_BIN:-/usr/bin/pmset}"
SCRIPT_DIR="${0:A:h}"
DISPLAY_IDLE_BIN="${SLEEPYCAT_DISPLAY_IDLE_BIN:-$SCRIPT_DIR/request_display_idle}"
caffeinate_pid=""
keep_caffeinate=0

log() {
  /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}

stop_caffeinate() {
  if [[ "$keep_caffeinate" -eq 0 && -n "$caffeinate_pid" ]] && /bin/kill -0 "$caffeinate_pid" 2>/dev/null; then
    /bin/kill "$caffeinate_pid" 2>/dev/null || true
    log "Stopped caffeinate process: $caffeinate_pid"
  fi
}

trap stop_caffeinate EXIT INT TERM

request_display_sleep_iokit() {
  local output exit_code
  if [[ ! -x "$DISPLAY_IDLE_BIN" ]]; then
    log "IOKit display sleep helper is not executable: $DISPLAY_IDLE_BIN"
    return 1
  fi

  output="$("$DISPLAY_IDLE_BIN" 2>&1)"
  exit_code=$?
  if [[ -n "$output" ]]; then
    log "IOKit output: $output"
  fi
  if [[ "$exit_code" -eq 0 ]]; then
    log "Requested display sleep via IOKit"
    return 0
  fi

  log "IOKit display sleep request failed with status $exit_code"
  return 1
}

request_display_sleep_pmset() {
  local output exit_code
  output="$("$PMSET_BIN" displaysleepnow 2>&1)"
  exit_code=$?
  if [[ -n "$output" ]]; then
    log "pmset output: $output"
  fi
  if [[ "$exit_code" -eq 0 && "$output" != *"Failed"* && "$output" != *"failed"* && "$output" != *"error"* ]]; then
    log "Requested display sleep via pmset"
    return 0
  fi

  log "pmset display sleep request failed with status $exit_code"
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
  request_display_sleep_iokit || true
  /bin/sleep 1
  if request_display_sleep_pmset; then
    keep_caffeinate=1
    exit 0
  fi
  /bin/sleep 2
done

stop_caffeinate
log "Could not put displays to sleep"
exit 1
