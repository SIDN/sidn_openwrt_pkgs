#!/bin/sh

PID=0

stop_conntrack() {
  if [ $PID != 0 ]; then
    kill $PID
  fi
  exit
}

run_conntrack() {
  conntrack -E -o timestamp --buffer-size 327680 > /tmp/spin_pipe &
  PID=$!
  wait $PID
}

trap stop_conntrack TERM KILL INT 
while true; do
  run_conntrack
done
