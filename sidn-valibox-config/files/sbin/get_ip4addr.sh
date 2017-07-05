#!/bin/sh

/sbin/ifconfig br-lan | grep inet | head -1 | cut -d ' ' -f 12 | cut -d ':' -f 2
