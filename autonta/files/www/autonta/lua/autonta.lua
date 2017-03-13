liluat = require'liluat'
language_keys = require 'language_keys'

autonta = {}

autonta.base_template_name = "base.html"
autonta.templates = {}

--mapping = {
-- '/':
--}

-- initial setup, load templates, etc.
function autonta.init()
    autonta.load_templates()
    language_keys.load("/usr/lib/valibox/autonta_lang/en_US")
end

function string_endswith(str, e)
    return e == '' or string.sub(str, -string.len(e)) == e
end

-- load the templates
-- TODO: simply load every file in a (given?) directory
function autonta.load_templates()
    -- should we add a dependency on lfs? do we need reading files more often?
    -- note: relative directory. Make this config or hardcoded?
    dirname = 'templates/'
    f = io.popen('ls ' .. dirname)
    for name in f:lines() do
        if string_endswith(name, '.html') then
            autonta.templates[name] = liluat.compile_file("templates/" .. name)
        end
    end
end

-- we have a two-layer template system; rather than adding headers
-- and footers to each template, we have a base template, which gets
-- the output from the 'inner' template as an argument ('main_html')
-- The outer template is called BASE
function autonta.render(template_name, args)
    if not autonta.templates[template_name] then
        return "[Error: could not find template " .. template_name .. "]"
    end
    args['langkeys'] = language_keys
    args['main_html'] = liluat.render(autonta.templates[template_name], args)
    return liluat.render(autonta.templates['base.html'], args)
end

-- render just the page itself (no base.html supertemplate)
function autonta.render_raw(template_name, args)
    args['langkeys'] = language_keys
    return liluat.render(autonta.templates[template_name], args)
end

-- main rendering function called by the wrapper
-- todo: should be add header utility functions? perhaps a response class
--       with reasonable defaults
-- todo: mapping from path to handler (separate classes? just functions?
--       differ between GET and POST or let the callee handle that distinction?)

function autonta.handle_request(env)
    headers = {}
    headers['Status'] = "200 OK"
    headers['Content-Type'] = "text/html"

    args = {
            current_version = "1.2.3"
    }
    html = autonta.render_raw('index.html', args)

    return headers, html
end

return autonta
