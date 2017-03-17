#!/usr/bin/env lua

local autonta = require 'autonta'
local au = require 'autonta_util'

function prompt(msg, allow_space)
  local line
  while true do
    io.write(msg)
    line = io.read("*line"):gsub("[%s\n]+$", "")
    if not allow_space and line:find("%s") then
      print("Error: white space not allowed")
    else
      break
    end
  end
  return line
end

local old_wifi_name = autonta.get_wifi_name()
local wifi_name = prompt("Wireless network name [" .. old_wifi_name .. "]: ", true)
local wifi_pass = prompt("Wireless password [keep current]: ", false)
local admin_pass = prompt("Administrator password [keep current]: ", false)

autonta.update_wifi_and_password(wifi_name, wifi_pass, admin_pass)
