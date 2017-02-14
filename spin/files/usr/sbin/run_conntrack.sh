#!/bin/sh
conntrack -E -o timestamp > $1
