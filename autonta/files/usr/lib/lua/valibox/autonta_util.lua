
local au = {}

local debug_enabled = false

function au.debug(msg)
  if debug_enabled then
    io.stderr:write(msg .. "\n")
  end
end

function au.set_debug(enabled)
  debug_enabled = enabled
end

-- Some lua magic; this translates an unpacked variable number
-- of arguments into one array (useful if functions return an unknown
-- number of values, like the page pattern matcher)
function au.pack(...)
  return arg
end

function au.string_endswith(str, e)
  return e == '' or string.sub(str, -string.len(e)) == e
end

function au.string_startswith(str, s)
  return string.sub(str, 1, string.len(s))==s
end

-- TODO: move to util
local charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

function au.randomstring(length)
  math.randomseed(os.time())

  if length > 0 then
    return au.randomstring(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
end

function au.split_host_port(host_str)
  local domain, port = host_str:match("([^:]+):([0-9]+)")
  if domain and port then return domain,port else return host_str end
end


function au.indent_str(indent)
  local result = ""
  for i=1,indent do
    result = result .. " "
  end
  return result
end

function au.obj2str(obj, indent)
  local t = type(obj)
  local result = ""
  if not indent then indent = 0 end
  if t == "string" or t == "number" then
    result = result .. obj
    --result = result .. "\n"
  elseif t == "table" then
  result = result .. "<table>\n"
  for k,v in pairs(obj) do
    result = result .. au.indent_str(indent)
    result = result .. k .. ": "
    result = result .. au.obj2str(v, indent + 2) .. "\n"
  end
  else
  result = result .. "<unprintable type: " .. t .. ">"
  end
  return result
end

function au.objprint(obj, indent, is_package)
  local t = type(obj)
  if not indent then indent = 0 end
  if t == "string" or t == "number" then
    io.stdout:write(obj)
    --result = result .. "\n"
  elseif t == "table" then
  io.stdout:write("<table>\n")
  for k,v in pairs(obj) do
    io.stdout:write(au.indent_str(indent))
    io.stdout:write("<"..k .. ">: ")
    if (k ~= '_G') then
      if k == 'package' or k == 'loaded' then
        if not is_package then
          au.objprint(v, indent + 2, true)
        end
      else
        au.objprint(v, indent + 2)
      end
    end
    io.stdout:write("\n")
  end
  else
  io.stdout:write("<unprintable type: " .. t .. ">")
  end
end


return au
