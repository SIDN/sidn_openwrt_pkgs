#!/usr/bin/env lua

local vu = require 'valibox_update'
local ua = require 'autonta_util'

print("hello world")

print(vu.get_current_version())
print(vu.get_board_name())
print(au.obj2str(vu.get_beta_info()))
