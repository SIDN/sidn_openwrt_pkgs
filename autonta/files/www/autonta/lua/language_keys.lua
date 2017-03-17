au = require 'autonta_util'

lk = {}
lk.keys = {}

-- todo: add args
function lk.get(key, ...)
    if lk.keys[key] then
      result = lk.keys[key]
      -- todo: verify argument counts
      for i,v in ipairs(arg) do
        au.debug("Replace key with '" .. v .. "'")
        result = result:gsub("%%s", v, 1)
      end
      au.debug("Result: '" .. result .. "'")
      return result
    else
      au.debug("Error: language key not found")
      return "[LANGUAGE KEY " .. key .. " NOT FOUND]"
    end
end

-- load language keys from the given file
function lk.load(filename)
    lk.keys = {}
    local f = io.open(filename, "r")
    -- todo: report error
    if not f then return nil end
    s = f:read("*all")
    f:close()
    for key,value in string.gmatch(s, "(%S+):%s*([^\n]*)") do
        lk.keys[key] = value
        --print("[XX] KEY: '" .. key .."': " .. value)
    end
end

return lk
