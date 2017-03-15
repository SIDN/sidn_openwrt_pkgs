
local au = {}

local debug_enabled = true

function au.debug(msg)
  if debug_enabled then
    io.stderr:write(msg .. "\n")
  end
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


return au
