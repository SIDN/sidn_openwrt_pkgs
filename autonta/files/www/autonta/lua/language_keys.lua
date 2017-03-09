
lk = {}
lk.keys = {}

-- todo: add args
function lk.get(key)
    if lk.keys[key] then
      return lk.keys[key]
    else
      return "[LANGUAGE KEY " .. key .. " NOT FOUND]"
    end
end

function lk.load()
    -- todo
    lk.keys['SIDNLABS'] = "SIDN Labs"
end

return lk
