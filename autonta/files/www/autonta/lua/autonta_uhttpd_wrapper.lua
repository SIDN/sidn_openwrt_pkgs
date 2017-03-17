autonta=require'autonta'
au = require 'autonta_util'

-- essentially, this script does not do much by itself
-- But if we want to generalize to other wrappers, this
-- is where conversion from env to a request class with data
-- would take place.
-- right now, we simple pass the env variable

-- initial setup, load templates, etc.
autonta.init()

-- main handler function.
function handle_request(env)
        if env.REQUEST_METHOD == "POST" then
            au.debug("  -- Received HTTP POST --")
            local content_length = env.CONTENT_LENGTH
            -- check recv size? does function itself read it all?
            _, env.POST_DATA = uhttpd.recv(env.CONTENT_LENGTH)
        else
            au.debug("  -- Received HTTP GET --")
        end

        headers, html = autonta.handle_request(env)
        for k,v in pairs(headers) do
          uhttpd.send(k .. ": " .. v .. "\r\n")
        end
        uhttpd.send("\r\n")
        uhttpd.send(html)
        au.debug("  -- HTTP request handled --")
end
