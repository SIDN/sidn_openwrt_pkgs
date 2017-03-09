liluat = require'liluat'     
language_keys = require 'language_keys'

autonta = {}

autonta.base_template_name = "base.html"
autonta.templates = {}

-- initial setup, load templates, etc.
function autonta.init()
    autonta.load_templates()
    language_keys.load()
end


-- we have a two-layer template system; rather than adding headers
-- and footers to each template, we have a base template, which gets
-- the output from the 'inner' template as an argument ('main_html')
-- The outer template is called BASE
function autonta.render(template_name, args)
    if not autonta.templates[template_name] then
        return "<Error: could not find template " .. template_name .. ">"
    end
    args['langkeys'] = language_keys
    args['main_html'] = liluat.render(autonta.templates[template_name], args)
    return liluat.render(autonta.templates['base.html'], args)
end

function autonta.render_raw(template_name, args)
    args['langkeys'] = language_keys
    return liluat.render(autonta.templates[template_name], args)
end

-- main rendering function called by the wrapper
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
