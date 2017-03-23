--
-- Functions to check, download, and install valibox updates
--
-- This can be called from the web-interface through autonta,
-- or from the command line (update_cli.lua)
--

local au = require 'autonta_util'
local mio = require 'mio'

local vu = {}

-- Read the version number from the relevant file
function vu.get_current_version()
  local version_file = io.open("/etc/valibox.version")
  if version_file then
    -- version should be on first line
    return version_file:read("*line")
  end
  return "<error reading version file>"
end

-- Read the board name from the relevant file
function vu.get_board_name()
  local board_file = io.open("/tmp/sysinfo/board_name")
  if board_file then
    -- version should be on first line
    return board_file:read("*line")
  end
  return "<error reading board name>"
end

-- Firmware version info is a mapping of:
-- 'board_name' -> { version: <most recent available  version>,
--                   sha256sum: <sha256 sum of image file>,
--                   base_url: <base URL>
--                   firmware_url: <relative url of image file>,
--                   info_url: <url with release info> }
function vu.fetch_firmware_info(base_url, fetch_options)
  local result = {}
  local url = base_url .. "/versions.txt"
  local info = vu.fetch_file(url, "/tmp/firmware_info.txt", true, fetch_options)
  local pattern = "%s*(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s*"
  if info then
    for line in info do
      local board_name
      local bi = {}
      board_name,bi.version,bi.firmware_url,bi.info_url,bi.sha256sum = line:match(pattern)
      if board_name then
        bi.base_url = base_url
        result[board_name] = bi
      end
    end
  else
    au.debug("Error fetching firmware info from " .. url)
    return false
  end
  return result
end

function vu.get_sha256_sum(filename)
  local cmd, args = mio.split_cmd("/usr/bin/sha256sum " .. filename)
  local p,err = mio.subprocess(cmd, args, nil, true)
  if p == nil then
    au.debug("[XX] error in sha256sum...")
    return nil, err
  end
  local line,lerr = p:read_line(true, 5000)
  if line == nil then return nil, lerr end
  local result = line:match("^([0-9a-f]+)")
  p:close()
  au.debug("[XX] LINE FROM SHA256: " .. au.obj2str(result))
  return result
end

-- Downloads and verifies the sha256sum of the image file for the given
-- board name (if found)
-- Returns local filename upon success, nil upon failure
function vu.download_image(board_firmware_info, fetch_options)
  local image_filename = "/tmp/firmware_update.bin"
  if board_firmware_info then
    local image_url = board_firmware_info.base_url .. "/" .. board_firmware_info.firmware_url
    au.debug("Downloading new image file from " .. image_url)
    if vu.fetch_file(image_url, image_filename, false, fetch_options) then
      -- check sha256
      local file_sha256_sum, err = vu.get_sha256_sum(image_filename)
      if file_sha256_sum == nil then
        au.debug("Error getting SHA256 of file: " .. err)
        return nil, "Error getting SHA256 of file: " .. err
      end
      au.debug("File SHA256: " .. file_sha256_sum)
      if file_sha256_sum == board_firmware_info.sha256sum then
        au.debug("SHA256 sum matches")
        return image_filename
      else
        au.debug("SHA256 mismatch, file sum: '" .. file_sha256_sum .. "' expected: '" .. board_firmware_info.sha256sum .. "', aborting update")
        return nil, "SHA256 mismatch, file sum: '" .. file_sha256_sum .. "' expected: '" .. board_firmware_info.sha256sum .. "', aborting update"
      end
    end
  else
    return nil, "download image called with nil firmware info object"
  end
end

function vu.install_image(filename, keep_settings)
  local cmd = "/sbin/sysupgrade"
  local args = {}
  if not keep_settings then
    table.insert(args, "-n")
  end
  table.insert(args, filename)
  au.debug("Calling sysupgrade command: " .. cmd)
  --os.execute(cmd)
  -- use io.popen instead of os.execute so we can return
  local subp = mio.subprocess(cmd, args)
  return subp:wait()
end

-- Fetch a file using wget
-- Optionally return the data
-- Arguments:
-- url: the url to fetch
-- output_file: the local file to store the fetch document in
-- return_data: if true, return the contents of the file as an iterator
-- (returns false if fetching failed)
function vu.fetch_file(url, output_file, return_data, fetch_options)
  au.debug("Fetch file from " .. url .. " and store in " .. output_file)
  local cmd = "curl -s -o " .. output_file .. " " .. url
  if fetch_options then cmd = cmd .. " " .. fetch_options end
  au.debug("Command: " .. cmd)
  local rcode = os.execute(cmd)
  if rcode and return_data then
    local of = io.open(output_file)
    if of then return of:lines() else return "Failed to download firmware info file" end
  else
    return rcode
  end
end

-- Returns a version string if there is an update available
-- returns nil if not
function vu.update_available(board_firmware_info)
  local current_version = vu.get_current_version()
  au.debug("Current version: " .. current_version)
  if board_firmware_info and board_firmware_info.version ~= current_version then
    return board_firmware_info.version
  end
end

-- returns a string containing the version info text for the current
-- version/update
function vu.fetch_update_info_txt(board_firmware_info, fetch_options)
  local info_url = board_firmware_info.base_url .. "/" .. board_firmware_info.info_url
  au.debug("Retrieving info txt from " .. info_url)
  local lines = vu.fetch_file(info_url, "/tmp/valibox_changelog.txt", true, fetch_options)
  local result_txt = ""
  for line in lines do
    result_txt = result_txt .. line .. "\n"
  end
  return result_txt
end


-- Retrieve information about the available firmware
-- Parameters:
-- beta: if true, install the current beta version
-- alternative_base_url: if not nil, use this instead of the default base url
-- debug_msgs: print debug messages (currently always true)
function vu.get_firmware_info(beta, fetch_options, debug_msgs)
  local base_url = "https://valibox.sidnlabs.nl/downloads/valibox/"
  --if alternative_base_url then base_url = alternative_base_url end
  if beta then base_url = base_url .. "beta/" end
  au.debug("Downloading upgrade information from " .. base_url)

  return vu.fetch_firmware_info(base_url, fetch_options)
end

function vu.get_firmware_board_info(beta, fetch_options, debug_msgs, board_name)
  local all_firmware_info = vu.get_firmware_info(beta, fetch_options, debug_msgs)
  if all_firmware_info[board_name] then return all_firmware_info[board_name] end
  au.debug("Unable to download firmware info, or board type not found")
  return nil
end

-- Downloads, checks and installs a new version
-- Does NOT check if the version is actually different; you can
-- reinstall the same version with this, if necessary
-- keep_settings: if true, keep the current settings
function vu.install_update(board_firmware_info, keep_settings, fetch_options)
  local image_file = vu.download_image(board_firmware_info, fetch_options)
  if image_file then
    au.debug("Checks passed, installing update")
    return vu.install_image(image_file, keep_settings)
  else
    au.debug("Checks failed. Update aborted.")
    return nil
  end
end

return vu
