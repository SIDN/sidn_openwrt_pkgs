#!/bin/sh

(cd /usr/lib/lua/valibox; uhttpd -f -p 8001 -L ./autonta_uhttpd_wrapper.lua  -l "")
rm -f /var/autonta.pid
