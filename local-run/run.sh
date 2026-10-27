#!/bin/bash
# Run this checkout's services in the background, each on the port this checkout owns.
#
#   dev-notes/local-run/run.sh start|stop|restart|status [service...]   (default: every service in project.sh)
#
# Run it from inside a checkout (main or worktree); everything below is per checkout:
# Logs:  <checkout>/.run/logs/<svc>.log (previous kept as .log.prev; rotated at 50 MB while running)
# PIDs:  <checkout>/.run/pids/<svc>.pid (process-group leader; stop kills the whole group)
# Ports: <checkout>/.run/ports, lines like `web=3010`, written by setup-worktree.sh; main_port in project.sh otherwise.
# Needs: lsof.
set -u

HERE="$(cd "$(dirname "$0")" && pwd -P)"   # -P: resolve the dev-notes symlink
. "$HERE/project.sh"
ROOT="${RUN_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$ROOT" ] || { echo "run.sh: run it from inside a checkout (or set RUN_ROOT)"; exit 1; }
LOGS="$ROOT/.run/logs"
PIDS="$ROOT/.run/pids"
mkdir -p "$LOGS" "$PIDS"
LOG_MAX=$((50 * 1024 * 1024))

port_of() {
  local p; p=$(grep -s "^$1=" "$ROOT/.run/ports" | cut -d= -f2)
  if [ -n "$p" ]; then echo "$p"; else main_port "$1"; fi
}

alive() { [ -f "$PIDS/$1.pid" ] && kill -0 "$(cat "$PIDS/$1.pid")" 2>/dev/null; }

start() {
  if alive "$1"; then echo "$1: already running (pid $(cat "$PIDS/$1.pid"))"; return; fi
  local cmd; cmd=$(service_cmd "$1" "$(port_of "$1")")
  [ -n "$cmd" ] || { echo "$1: no service_cmd in project.sh"; return 1; }
  [ -f "$LOGS/$1.log" ] && mv "$LOGS/$1.log" "$LOGS/$1.log.prev"
  set -m   # background job gets its own process group, so stop can kill children too
  nohup bash -c "$cmd" </dev/null >>"$LOGS/$1.log" 2>&1 &   # no stdin: dev servers that read it die once the terminal goes
  local pid=$!
  echo "$pid" >"$PIDS/$1.pid"
  set +m
  # >> (O_APPEND) lets the log be truncated while the service writes to it.
  ( log="$LOGS/$1.log"
    while kill -0 "$pid" 2>/dev/null; do
      [ "$(wc -c <"$log" 2>/dev/null || echo 0)" -gt "$LOG_MAX" ] && cp "$log" "$log.prev" && : >"$log"
      sleep 30
    done ) </dev/null >/dev/null 2>&1 &
  disown
  echo "$1: started (pid $pid, port $(port_of "$1"), log $LOGS/$1.log)"
}

stop() {
  alive "$1" && kill -TERM -- "-$(cat "$PIDS/$1.pid")" 2>/dev/null
  rm -f "$PIDS/$1.pid"
  # Also clear anything else holding the port (e.g. started by hand, outside this script).
  local port pids; port=$(port_of "$1")
  pids=$(lsof -ti "tcp:$port" -sTCP:LISTEN 2>/dev/null)
  [ -n "$pids" ] && kill $pids 2>/dev/null
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    lsof -ti "tcp:$port" -sTCP:LISTEN >/dev/null 2>&1 || break
    sleep 0.5
  done
  echo "$1: stopped"
}

status() {
  local listen; listen=$(lsof -ti "tcp:$(port_of "$1")" -sTCP:LISTEN 2>/dev/null | head -1)
  if alive "$1"; then echo "$1: running (pid $(cat "$PIDS/$1.pid"), port $(port_of "$1")${listen:+, listening})"
  elif [ -n "$listen" ]; then echo "$1: port $(port_of "$1") held by pid $listen (not started by this script)"
  else echo "$1: stopped"; fi
}

action="${1:-}"; shift || true
[ $# -eq 0 ] && set -- "${SERVICES[@]}"

case "$action" in
  start)   for s in "$@"; do start "$s"; done ;;
  stop)    for s in "$@"; do stop "$s"; done ;;
  restart) for s in "$@"; do stop "$s"; start "$s"; done ;;
  status)  for s in "$@"; do status "$s"; done ;;
  *) echo "usage: $0 start|stop|restart|status [${SERVICES[*]}]"; exit 1 ;;
esac
