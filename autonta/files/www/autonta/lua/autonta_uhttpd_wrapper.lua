liluat=require'liluat'     

autonta=require'autonta'

-- initial setup, load templates, etc.
autonta.init()

-- main handler function.
-- This function is called by uhttpd
function oldhandle_request(env)
        uhttpd.send("Status: 200 OK\r\n")
        uhttpd.send("Content-Type: text/html\r\n\r\n")
        uhttpd.send("Hello world.\n")
        for k,v in pairs(env) do
          uhttpd.send(k .. ": " .. type(v) .. "<br />")
        end
        
        uhttpd.send("\r\n\r\n<br />CONTENT<br />\r\n")
        
        template = liluat.compile_file("templates/test.template")
        args = {
                title = "A fine selection of vegetables.",
                    vegetables = {
                        "carrot",
                        "cucumber",
                        "broccoli",
                        "tomato"
                    }
        }
        html = liluat.render(template, args)
        uhttpd.send(html)
        uhttpd.send("<br />END OF CONTENT\r\n")
end

function handle_request(env)
        headers, html = autonta.handle_request(env)
        for k,v in pairs(headers) do
          uhttpd.send(k .. ": " .. v .. "\r\n")
        end
        uhttpd.send("\r\n")
        uhttpd.send(html)
end
