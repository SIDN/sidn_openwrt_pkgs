--
-- Functions to check, download, and install valibox updates
--
-- This can be called from the web-interface through autonta,
-- or from the command line (update_cli.lua)
--

au = require 'autonta_util'

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
-- 'board_name' -> { version: <most recent available version>,
--                   sha256sum: <sha256 sum of image file>,
--                   firmware_url: <url of image file>,
--                   info_url: <url with release info> }
function vu.get_firmware_info(base_url)
  local result = {}
  local info = vu.fetch_file(base_url .. "/versions.txt", "/tmp/firmware_info.txt", true)
  local pattern = "%s*(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s*"
  if info then
    for line in info do
      local board_name
      local bi = {}
      board_name,bi.version,bi.firmware_url,bi.info_url,bi.sha256sum = line:match(pattern)
      if board_name then
        result[board_name] = bi
      end
    end
  else
    au.debug("Error fetching firmware info from " .. url)
    return false
  end
  return result
end

function vu.get_release_info()
  return vu.get_firmware_info("https://valibox.sidnlabs.nl/downloads/valibox/")
end

function vu.get_beta_info()
  return vu.get_firmware_info("https://valibox.sidnlabs.nl/downloads/valibox/beta")
end

-- Fetch a file using wget
-- Optionally return the data
-- Arguments:
-- url: the url to fetch
-- output_file: the local file to store the fetch document in
-- return_data: if true, return the contents of the file as an iterator
-- (returns false if fetching failed)
function vu.fetch_file(url, output_file, return_data)
  au.debug("Fetch file from " .. url .. " and store in " .. output_file)
  local f = io.popen("wget -O " .. output_file .. " " .. url)
  local rcode = f:close()
  if rcode and return_data then
    return io.open(output_file):lines()
  else
    return rcode
  end
end


return vu
