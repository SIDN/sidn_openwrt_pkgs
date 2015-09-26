#!/bin/sh

/sbin/ifconfig | grep inet | head -1 | cut -d ' ' -f 12 | cut -d ':' -f 2
