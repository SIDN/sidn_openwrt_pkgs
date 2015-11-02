#!/bin/sh

/sbin/ifconfig br-lan | grep inet6 | head -1 | cut -d ' ' -f 13 | cut -d '/' -f 1
