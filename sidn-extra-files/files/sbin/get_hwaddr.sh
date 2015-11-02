#!/bin/sh

/sbin/ifconfig br-lan | grep HWaddr | head -1 | sed 's/^.*\(.\).\(.\)\(.\)..$/\1\2\3/' | awk '{print tolower($0)}'
