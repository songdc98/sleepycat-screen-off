#!/bin/zsh
set -u

LOG_FILE="${TMPDIR:-/tmp}/sleepycat-screen-off.log"
LOCK_DIR="${TMPDIR:-/tmp}/sleepycat-screen-off.lock"
START_DELAY_SECONDS="${SLEEPYCAT_START_DELAY_SECONDS:-4}"
caffeinate_pid=""

log() {
  /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}

acquire_lock() {
  if /bin/mkdir "$LOCK_DIR" 2>/dev/null; then
    /bin/echo "$$" > "$LOCK_DIR/pid"
    return 0
  fi

  local old_pid
  old_pid="$(/bin/cat "$LOCK_DIR/pid" 2>/dev/null || true)"
  if [[ -n "$old_pid" ]] && /bin/kill -0 "$old_pid" 2>/dev/null; then
    log "Another instance is already running: $old_pid"
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

request_display_sleep() {
  local attempt output status
  for attempt in 1 2 3 4; do
    output="$(/usr/bin/pmset displaysleepnow 2>&1)"
    status=$?
    if [[ -n "$output" ]]; then
      log "pmset output on attempt $attempt: $output"
    fi
    if [[ "$status" -eq 0 && "$output" != *"Failed"* && "$output" != *"failed"* && "$output" != *"error"* ]]; then
      log "Requested display sleep"
      return 0
    fi
    log "Display sleep request failed on attempt $attempt with status $status"
    /bin/sleep 2
  done
  return 1
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
acquire_lock

if [[ "${SLEEPYCAT_DRY_RUN:-0}" == "1" ]]; then
  log "Dry run: lock acquired, exiting before display sleep"
  exit 0
fi

# Keep the Mac awake only while this script is alive. Do not use -d, because
# the display should be allowed to sleep.
/usr/bin/caffeinate -i -m -s -w "$$" >> "$LOG_FILE" 2>&1 &
caffeinate_pid=$!
log "Started caffeinate process: $caffeinate_pid"

# A Dock click is also mouse activity. Wait briefly so the click does not keep
# the display-sleep request from being accepted.
/bin/sleep "$START_DELAY_SECONDS"

if ! request_display_sleep; then
  log "Could not put displays to sleep"
  exit 1
fi

# Give macOS time to enter display sleep before interpreting HID activity.
/bin/sleep 8

while /bin/kill -0 "$caffeinate_pid" 2>/dev/null; do
  idle_seconds="$(current_idle_seconds)"
  if [[ "$idle_seconds" -le 2 ]]; then
    log "Detected user activity after display sleep"
    break
  fi
  /bin/sleep 5
done
