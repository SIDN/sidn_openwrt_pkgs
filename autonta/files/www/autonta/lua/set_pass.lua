#!/usr/bin/env lua

local an = require 'autonta'
local au = require 'autonta_util'
local posix = require 'posix'

function prompt(msg, allow_space, quiet)
  local line
  while true do
    if not quiet then io.stdout:write(msg) end
    io.stdout:flush()
    line = io.read("*line"):gsub("[%s\n]+$", "")
    if not allow_space and line:find("%s") then
      print("Error: white space not allowed")
    else
      break
    end
  end
  return line
end

local argparse = require 'argparse'

local parser = argparse()

parser:flag("-q --quiet", "Do not prompt for values")
parser:flag("-w --wait", "Wait 2 seconds before activating change")

local args = parser:parse()

local autonta = an.create()
local old_wifi_name = autonta:get_wifi_name()
local wifi_name = prompt("Wireless network name [" .. old_wifi_name .. "]: ", true, args.quiet)
local wifi_pass = prompt("Wireless password [keep current]: ", false, args.quiet)
local admin_pass = prompt("Administrator password [keep current]: ", false, args.quiet)

if args.wait then posix.sleep(2) end

autonta:update_wifi_and_password(wifi_name, wifi_pass, admin_pass)
