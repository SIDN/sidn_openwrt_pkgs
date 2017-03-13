
lk = {}
lk.keys = {}

-- todo: add args
function lk.get(key, ...)
    if lk.keys[key] then
      result = lk.keys[key]
      -- todo: verify argument counts
      for i,v in ipairs(arg) do
        result = result:gsub("%%s", v)
      end
      return result
    else
      return "[LANGUAGE KEY " .. key .. " NOT FOUND]"
    end
end

-- load language keys from the given file
function lk.load(filename)
    local f = io.open(filename, "r")
    -- todo: report error
    if not f then return nil end
    s = f:read("*all")
    f:close()
    for key,value in string.gmatch(s, "(%S+):%s*([^\n]*)") do
        lk.keys[key] = value
        print("[XX] KEY: '" .. key .."': " .. value)
    end
end

return lk
