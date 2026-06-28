#!/bin/zsh
set -u

LOG_FILE="/tmp/sleepycat-screen-off-8h.log"
LOCK_DIR="/tmp/sleepycat-screen-off.lock"
DURATION_SECONDS=28800
INITIAL_DISPLAY_SLEEP_DELAY=5
DISPLAY_SLEEP_ATTEMPTS=12
DISPLAY_SLEEP_RETRY_SECONDS=5
ARM_IDLE_SECONDS=3
ARM_WAIT_SECONDS=20
ACTIVITY_IDLE_SECONDS=2
caffeinate_pid=""

log() {
  /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}

cleanup() {
  if [[ -n "$caffeinate_pid" ]] && /bin/kill -0 "$caffeinate_pid" 2>/dev/null; then
    /bin/kill "$caffeinate_pid" 2>/dev/null || true
    log "Stopped caffeinate process: $caffeinate_pid"
  fi
  if [[ -d "$LOCK_DIR" ]] && [[ "$(/bin/cat "$LOCK_DIR/pid" 2>/dev/null || true)" == "$$" ]]; then
    /bin/rm -rf "$LOCK_DIR" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

acquire_lock() {
  if /bin/mkdir "$LOCK_DIR" 2>/dev/null; then
    /bin/echo "$$" > "$LOCK_DIR/pid"
    return 0
  fi

  local old_pid
  old_pid="$(/bin/cat "$LOCK_DIR/pid" 2>/dev/null || true)"
  if [[ -n "$old_pid" ]] && /bin/kill -0 "$old_pid" 2>/dev/null; then
    log "Another screen-off instance is already running: $old_pid"
    exit 0
  fi

  /bin/rm -rf "$LOCK_DIR" 2>/dev/null || true
  if /bin/mkdir "$LOCK_DIR" 2>/dev/null; then
    /bin/echo "$$" > "$LOCK_DIR/pid"
    return 0
  fi

  log "Could not acquire lock"
  exit 1
}

current_idle_seconds() {
  local idle_ns
  idle_ns="$(/usr/sbin/ioreg -c IOHIDSystem | /usr/bin/awk '/HIDIdleTime/ {print $NF; exit}')"
  if [[ -z "$idle_ns" ]]; then
    /bin/echo 999999
  else
    /bin/echo $(( idle_ns / 1000000000 ))
  fi
}

display_sleep_is_blocked() {
  /usr/bin/pmset -g assertions | /usr/bin/grep -Eq 'NoDisplaySleepAssertion|PreventUserIdleDisplaySleep named'
}

request_display_sleep() {
  local pmset_output pmset_status idle_seconds

  idle_seconds="$(current_idle_seconds)"
  log "Requesting display sleep; input idle=${idle_seconds}s"

  pmset_output="$(/usr/bin/osascript -e 'do shell script "/usr/bin/pmset displaysleepnow 2>&1"' 2>&1)"
  pmset_status=$?
  if [[ -n "$pmset_output" ]]; then
    log "pmset output: $pmset_output"
  fi
  if [[ "$pmset_status" -ne 0 || "$pmset_output" == *"Failed"* || "$pmset_output" == *"failed"* || "$pmset_output" == *"error"* ]]; then
    log "Display sleep request failed with status $pmset_status"
    return 1
  fi

  log "Requested display sleep with status $pmset_status"
  return 0
}

wait_until_monitor_armed() {
  local waited=0
  local idle_seconds=0

  while [[ "$waited" -lt "$ARM_WAIT_SECONDS" ]]; do
    idle_seconds="$(current_idle_seconds)"
    if [[ "$idle_seconds" -ge "$ARM_IDLE_SECONDS" ]]; then
      log "Display sleep monitor armed after input idle reached ${idle_seconds}s"
      return 0
    fi
    /bin/sleep 1
    waited=$(( waited + 1 ))
  done

  log "Input never became idle after display sleep request; exiting"
  return 1
}

if [[ "${SLEEPYCAT_DRY_RUN:-0}" == "1" ]]; then
  log "Dry run: fixed 8-hour mode"
  exit 0
fi

acquire_lock

log "Starting monitored fixed 8-hour display sleep mode"

/bin/sleep "$INITIAL_DISPLAY_SLEEP_DELAY"

display_sleep_started=0
for attempt in $(/usr/bin/seq 1 "$DISPLAY_SLEEP_ATTEMPTS"); do
  log "Display sleep attempt $attempt of $DISPLAY_SLEEP_ATTEMPTS"
  if display_sleep_is_blocked; then
    log "Display sleep is blocked by another process; exiting without caffeinate"
    exit 1
  fi

  if request_display_sleep; then
    display_sleep_started=1
    break
  fi

  /bin/sleep "$DISPLAY_SLEEP_RETRY_SECONDS"
done

if [[ "$display_sleep_started" -ne 1 ]]; then
  log "Could not put displays to sleep after retries; exiting without caffeinate"
  exit 1
fi

/usr/bin/caffeinate -i -m -w "$$" >> "$LOG_FILE" 2>&1 &
caffeinate_pid=$!
log "Started caffeinate process: $caffeinate_pid while displays are asleep"

if ! wait_until_monitor_armed; then
  exit 1
fi

start_epoch="$(/bin/date +%s)"
while /bin/kill -0 "$caffeinate_pid" 2>/dev/null; do
  now_epoch="$(/bin/date +%s)"
  if [[ $(( now_epoch - start_epoch )) -ge "$DURATION_SECONDS" ]]; then
    log "Reached ${DURATION_SECONDS}s display-off limit"
    break
  fi

  idle_seconds="$(current_idle_seconds)"
  if [[ "$idle_seconds" -le "$ACTIVITY_IDLE_SECONDS" ]]; then
    log "Detected user activity after display sleep"
    break
  fi

  /bin/sleep 1
done

exit 0
