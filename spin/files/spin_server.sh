#!/bin/sh
# create and secure a better one here
PIPENAME=/tmp/spin_pipe

# create a pipe
if [ ! -e ${PIPENAME} ]; then
    mkfifo ${PIPENAME}
fi

(cd /usr/lib/spin; lua ./server.lua)
