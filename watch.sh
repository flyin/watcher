#!/usr/bin/env bash
echo -e "===> Start watching..."

PID=/tmp/project.pid
LOG=/tmp/project-notify.log
BINARY=/tmp/project-api
MAIN=cmd/server/main.go

ctrl_c() {
    echo -e "\n===> Asking $WATCHER_PID/inotifywait to terminate..."
    kill $WATCHER_PID

    cat $PID | xargs -I{} echo -e "===> Asking {}/app to terminate..."
    cat $PID | xargs kill
    exit 0
}
trap ctrl_c SIGINT

inotifywait --exclude "vendor/**/*|[^g][^o]$" -mrq -e close_write,move,delete "." >$LOG &
WATCHER_PID=$!

go build -o $BINARY ./cmd/server/main.go 
$BINARY $@ &
echo "$!" > $PID

tail -f $LOG | while read path action file; do
    echo -e "---- [${action}] Changed file ${path}${file}..."

    cat $PID | xargs -I{} echo -e "===> Asking {}/app to terminate..."
    cat $PID | xargs kill

    go build -o $BINARY $MAIN
    $BINARY $@ &
    echo "$!" > $PID
done
