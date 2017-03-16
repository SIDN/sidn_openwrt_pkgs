#!/usr/bin/env lua

local vu = require 'valibox_update'
local au = require 'autonta_util'

local argparse = require 'argparse'

local parser = argparse()

parser:flag("-b --beta", "Install beta version")
parser:flag("-o --override-host", "Use fixed IP address to download from (if DNS is not available)")
parser:flag("-k --keep-settings", "Keep current settings")
parser:flag("-d --debug", "Print debug messages")
parser:flag("-i --install", "Proceed with installation after checks")
parser:flag("-c --changelog", "Print changelog")

local args = parser:parse()

local fetch_options = ""
if args.override_host then
  fetch_options = "--resolve valibox.sidnlabs.nl:443:94.198.159.35"
end

--local board_name = vu.get_board_name()
local board_name = "gl-ar150"
local firmware_info = vu.get_firmware_info(args.beta, fetch_options, args.debug)

if not firmware_info then
  print("Failed to retrieve firmware information")
  return
end

board_firmware_info = firmware_info[board_name]
if not board_firmware_info then
  print("No firmware found for board type '" .. board_name .. "'")
  return
end

local update_version = vu.update_available(board_firmware_info)
if update_version then
  print("Update available: " .. update_version)
end

if args.changelog then
  print(vu.fetch_update_info_txt(board_firmware_info, fetch_options))
end

if args.install then
  vu.install_update(board_firmware_info, args.keep_settings, fetch_options)
end

--args.get_help()
