#!/bin/zsh
set -u

LOG_FILE="${TMPDIR:-/tmp}/sleepycat-screen-off.log"

log() {
  /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
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

# Keep the Mac awake only while this script is alive. Do not use -d, because
# the display should be allowed to sleep.
/usr/bin/caffeinate -i -m -s -w "$$" >> "$LOG_FILE" 2>&1 &
caffeinate_pid=$!
log "Started caffeinate process: $caffeinate_pid"

cleanup() {
  if /bin/kill -0 "$caffeinate_pid" 2>/dev/null; then
    /bin/kill "$caffeinate_pid" 2>/dev/null || true
    log "Stopped caffeinate process: $caffeinate_pid"
  fi
}

trap cleanup EXIT INT TERM

/usr/bin/pmset displaysleepnow
log "Requested display sleep"

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
