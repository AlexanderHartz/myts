#!/bin/sh

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PATH

TERM=xterm
export TERM

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd) || exit 1
SELF="$SCRIPT_DIR/myts.sh"
BIN_DIR="$SCRIPT_DIR/bin"
FIFO="/var/tmp/myts.special"
PIDFILE="/var/tmp/myts.pid"
LOG_FILE="/tmp/myts.log"

if type nohup >/dev/null 2>&1; then
    NOHUP=nohup
else
    NOHUP=
fi

log() {
    printf '%s\n' "$*" >>"$LOG_FILE"
}

fatal() {
    log "$*"
    eips 0 0 "$*" >/dev/null 2>&1
    sleep 2
    exit 1
}

is_running() {
    [ -s "$PIDFILE" ] || return 1
    pid=$(cat "$PIDFILE" 2>/dev/null) || return 1
    kill -0 "$pid" 2>/dev/null
}

stop_myts() {
    if is_running; then
        pid=$(cat "$PIDFILE" 2>/dev/null)
        kill "$pid" 2>/dev/null
        sleep 1
        kill -9 "$pid" 2>/dev/null
    fi
    killall myts 2>/dev/null
    rm -f "$PIDFILE" "$FIFO"
}

start_myts() {
    if is_running; then
        return 0
    fi
    killall myts 2>/dev/null
    rm -f "$PIDFILE" "$FIFO"
    if [ ! -p "$FIFO" ]; then
        mknod "$FIFO" p || fatal "myts: cannot create special fifo"
    fi
    cd "$BIN_DIR" || fatal "myts: cannot enter $BIN_DIR"
    $NOHUP ./myts </dev/null >>"$LOG_FILE" 2>&1 &
    printf '%s\n' "$!" >"$PIDFILE"
    sleep 1
    is_running || fatal "myts: failed to start, see $LOG_FILE"
}

open_terminal() {
    printf 'A%s\n' "$1" >"$FIFO" || return 1
    echo send 0 >/proc/keypad 2>/dev/null || true
    return 0
}

queue_terminal() {
    $NOHUP sh "$SELF" __open "$1" </dev/null >/dev/null 2>&1 &
}

[ -d "$BIN_DIR" ] || fatal "myts: missing $BIN_DIR"
[ -f "$BIN_DIR/myts" ] || fatal "myts: missing myts binary"
[ -x "$BIN_DIR/myts" ] || chmod +x "$BIN_DIR/myts" 2>/dev/null || fatal "myts: binary is not executable"

cd "$BIN_DIR" || fatal "myts: cannot enter $BIN_DIR"
for f in myts.ini keydefs.ini ter-u12n.hex; do
    [ -f "$f" ] || fatal "myts: missing $f"
done

case "${1:-1}" in
    __open)
        sleep 3
        is_running || exit 0
        open_terminal "${2:-1}" || fatal "myts: cannot open terminal"
        ;;
    kill|stop|quit)
        stop_myts
        ;;
    restart)
        stop_myts
        start_myts
        queue_terminal 1
        ;;
    1|2|3)
        start_myts
        queue_terminal "$1"
        ;;
    *)
        start_myts
        queue_terminal 1
        ;;
esac

exit 0
