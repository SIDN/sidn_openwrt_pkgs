
local _m = {}

-- Config file wrapper
--
-- local c = _m.read_config("/tmp/valibox")
-- c:print()
-- if c:updated() then print("updated") else print("not updated") end
-- print(c:get('language', 'language'))
--

function _m.read_config(filename)
  -- table of tables (sections/elements)
  local config = {}

  config.read = function()
    config.sections = {}
    config.last_modified = config.read_last_modified()

    local f = io.open(config.filename)
    if not f then
      io.stderr:write("Error, unable to open " .. config.filename .. "\n")
      return nil
    end

    local current_section = {}
    local current_section_name = nil
    for line in f:lines() do
      sname = line:match("config%s+(%S+)")
      qoname,qoval = line:match("%s*option%s+(%S+)%s+'([^']+)'")
      oname,oval = line:match("%s*option%s+(%S+)%s+([%S]+)")
      if sname then
        if current_section_name then
          config.sections[current_section_name] = current_section
          current_section = {}
        end
        current_section_name = sname
      elseif qoname and qoval then
        if not current_section_name then
          io.stderr:write("Parse error in " .. config.filename .. ": option outside of section")
          return nil
        end
        current_section[qoname] = qoval
      elseif oname and oval then
        if not current_section_name then
          io.stderr:write("Parse error in " .. config.filename .. ": option outside of section")
          return nil
        end
        current_section[oname] = oval
      end
    end
    if current_section_name then
      config.sections[current_section_name] = current_section
    end
    f:close()

    return true
  end

  config.read_last_modified = function()
    local f = io.popen("stat -c %Y " .. config.filename)
    return f:read()
  end

  config.print = function(self)
    for sname,sdata in pairs(config.sections) do
      print("config " .. sname)
      for n,v in pairs(sdata) do
        print("\toption " .. n .. " '" .. v .. "'")
      end
    end
  end

  config.updated = function(self, reload)
    local result = config.last_modified ~= config.read_last_modified()
    if reload then return self.load() else return result end
  end

  config.get = function(self, sname, option)
    if not config.sections[sname] then
      io.stderr:write("Warning: unknown section '" .. sname .. "'\n")
      return nil
    end
    if not config.sections[sname][option] then
      io.stderr:write("Warning: option '" .. option .. "' not found in section '" .. sname .. "'")
    end
    return config.sections[sname][option]
  end

  -- init and return
  config.filename = filename
  if not config.read() then return nil else return config end
end

return _m

