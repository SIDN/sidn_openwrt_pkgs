
local _m = {}

local mio = require 'valibox.mio'

-- Config file wrapper
--
-- local c = _m.read_config("/tmp/valibox")
-- c:print()
-- if c:updated() then print("updated") else print("not updated") end
-- print(c:get('language', 'language'))
--

local config = {}
config.__index = config

function _m.create(filename)
  local cf = {}             -- our new object
  setmetatable(cf,config)  -- make Account handle lookup
  cf.filename = filename
  return cf
end

function config:read_config()
  self.sections = {}
  self.last_modified = self:read_last_modified()

  local cfr, err = mio.file_reader(self.filename)
  if cfr == nil then
    io.stderr:write("Error, unable to open " .. self.filename .. ": " .. err .. "\n")
    return nil, err
  end

  local current_section = {}
  local current_section_name = nil
  for line in cfr:read_line_iterator() do
    local sname = line:match("config%s+(%S+)")
    local qoname,qoval = line:match("%s*option%s+(%S+)%s+'([^']+)'")
    local oname,oval = line:match("%s*option%s+(%S+)%s+([%S]+)")
    if sname then
      if current_section_name then
        self.sections[current_section_name] = current_section
        current_section = {}
      end
      current_section_name = sname
    elseif qoname and qoval then
      if not current_section_name then
        io.stderr:write("Parse error in " .. self.filename .. ": option outside of section")
        return nil
      end
      current_section[qoname] = qoval
    elseif oname and oval then
      if not current_section_name then
        io.stderr:write("Parse error in " .. self.filename .. ": option outside of section")
        return nil
      end
      current_section[oname] = oval
    end
  end
  if current_section_name then
    self.sections[current_section_name] = current_section
  end
  cfr:close()

  return true
end

function config:read_last_modified()
  return mio.file_last_modified(self.filename)
end

function config:print()
  for sname,sdata in pairs(self.sections) do
    print("config " .. sname)
    for n,v in pairs(sdata) do
      print("\toption " .. n .. " '" .. v .. "'")
    end
  end
end

function config:updated(reload)
  local result = self.last_modified ~= self:read_last_modified()
  if reload then return self:read_config() else return result end
end

function config:get(sname, option)
  if not self.sections[sname] then
    io.stderr:write("Warning: unknown section '" .. sname .. "'\n")
    return nil
  end
  if not self.sections[sname][option] then
    io.stderr:write("Warning: option '" .. option .. "' not found in section '" .. sname .. "'")
  end
  return self.sections[sname][option]
end

return _m
