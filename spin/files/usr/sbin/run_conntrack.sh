#!/bin/sh
while true; do
    conntrack -E -o timestamp > $1
done
