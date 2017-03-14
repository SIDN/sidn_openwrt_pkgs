liluat = require'liluat'
language_keys = require 'language_keys'

autonta = {}



-- initial setup, load templates, etc.
function autonta.init()
  autonta.templates = {}
  autonta.load_templates()
  autonta.base_template_name = "base.html"

  language_keys.load("/usr/lib/valibox/autonta_lang/en_US")


  -- When handling requests or posts, the specific handler
  -- is found here; in order the REQUEST_URI value is matched
  -- the first match is the handler that is called
  autonta.mapping = {}
  table.insert(autonta.mapping, { pattern = '^/test$', handler = autonta.test_handler })
  table.insert(autonta.mapping, { pattern = '^/$', handler = autonta.handle_autonta_main })

  --table.insert(autonta.mapping, { pattern = '^/$', handler = autonta.handle_autonta_main })
  table.insert(autonta.mapping, { pattern = '^/autonta/nta_list$', handler = autonta.handle_ntalist })
  table.insert(autonta.mapping, { pattern = '^/autonta/set_nta/([a-zA-Z0-9.-]+)', handler = autonta.handle_set_nta })
  table.insert(autonta.mapping, { pattern = '^/autonta/remove_nta/([a-zA-Z0-9.-]+)$', handler = autonta.handle_remove_nta })
  table.insert(autonta.mapping, { pattern = '^/autonta/ask_nta/([a-zA-Z0-9.-]+)$', handler = autonta.handle_ask_nta })
end

--
-- General utility functions (move to util or something?
--

-- Some lua magic; this translates an unpacked variable number
-- of arguments into one array (useful if functions return an unknown
-- number of values, like the page pattern matcher)
function pack(...)
  return arg
end

function string_endswith(str, e)
  return e == '' or string.sub(str, -string.len(e)) == e
end

function string_startswith(str, s)
  return string.sub(str, 1, string.len(s))==s
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

--
-- a few (temporary) helper functions
--
function print_indent(indent)
  local result = ""
  for i=1,indent do
    result = result .. " "
  end
  return result
end

function print_object(obj, indent)
  local t = type(obj)
  local result = ""
  if not indent then indent = 0 end
  if t == "string" or t == "number" then
    result = result .. obj
    result = result .. "\n"
  elseif t == "table" then
  result = result .. "<table>\n"
  for k,v in pairs(obj) do
    result = result .. print_indent(indent)
    result = result .. k .. ": "
    result = result .. print_object(v, indent + 2)
  end
  else
  result = result .. "<unprintable type: " .. t .. ">\n"
  end
  return result
end

--
-- Backend logic functions; TODO: move this to a utility-class
--
function is_first_run()
  return false
end

function get_nta_list()
  local f = io.popen('unbound-control list_insecure')
  result = {}
  for nta in f:lines() do
    table.insert(result, nta)
  end
  return result
end

function set_cookie(headers, cookie, value)
  headers['Set-Cookie'] = cookie .. "=" .. value
end

function remove_cookie(headers, cookie)
  headers['Set-Cookie'] = cookie .. "=;Max-Age=0"
end

function get_cookie_value(env, cookie)
  local headers = env.headers
  return ""
end


--
-- Actual specific page handlers
--
function autonta.handle_autonta_main(env)
  local headers = {}
  headers['Status'] = "200 OK"
  headers['Content-Type'] = "text/html"

  args = {
      current_version = "1.2.3"
  }
  html = autonta.render_raw('index.html', args)

  return headers, html
end

function autonta.handle_ntalist(env, arg1, arg2, arg3, arg4)
  local headers = create_default_headers()
  -- todo: reload config?
  if is_first_run() then
    return redirect_to("http://valibox./autonta/set_passwords")
  end

  args = { ntas = get_nta_list() }
  html = autonta.render('nta_list.html', args)
  return headers, html
end

function check_validity(env, host_match, dst_cookie_val)
  if not env.HTTP_REFERER:match(host_match) then
    io.stderr:write("Referer match failure\n")
    return false
  else
    local query_string = env.QUERY_STRING
    -- todo: generalize query string match
    local q_dst_val = string.sub(query_string, 4)
    if q_dst_val ~= dst_cookie_val then
      io.stderr:write("DST cookie mismatch: " .. dst_cookie_val .. " != " .. q_dst_val .. "\n")
      return false
    else
      return true
    end
  end
end

function autonta.handle_set_nta(env, args)
  local headers = create_default_headers()
  local domain = args[1]
  -- todo: reload config, and check config

  local host_match = "https?://(valibox\.)|(192\.168\.8\.1)/autonta/ask_nta/" .. domain
  local dst_cookie_val = get_cookie_value(env, "valibox_nta")
  if check_validity(env, host_match, dst_cookie_val) then
    add_nta(domain)
    remove_cookie(headers, "valibox_nta")
    html = autonta.render('nta_set.html', domain)
    return headers, html
  else
    return redirect_to("/autonta/ask_nta/" .. domain)
  end
end

function autonta.handle_remove_nta(env, domain)
  local headers = create_default_headers()
  return headers, "TODO"
end

local charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

function string.random(length)
  math.randomseed(os.time())

  if length > 0 then
    return string.random(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
end

function create_dst()
  return string.random(12)
end

function autonta.handle_ask_nta(env, args)
  local headers = create_default_headers()
  local domain = args[1]
  -- todo: reload config, and check config
  if is_first_run() then
    return redirect_to("http://valibox./autonta/set_passwords")
  end

  -- create a double-submit token
  local dst = create_dst()
  set_cookie(headers, "valibox_nta", dst)

  -- TODO: unbound-host
  local err = {}
  err.auth_server = "ns.nl.nl"
  err.err_msg = "some error, hmkay"
  err.fail_type = "failtype"
  err.fail_dname = "subdomain.with.error"

  -- TODO: check config
  local nta_disabled = false
  -- TODO: split on .
  local hosts = {}
  table.insert(hosts, domain)
  table.insert(hosts, "foo.bar")
  table.insert(hosts, "baz")
  local targs = { dst = dst, name = domain, names = hosts, err = err, nta_disabled = nta_disabled }
  html = autonta.render('ask_nta.html', targs)
  return headers, html
end


function autonta.handle_(env)
  return create_default_headers(), html
end

function create_default_headers()
  local headers = {}
  headers['Status'] = "200 OK"
  headers['Content-Type'] = "text/html"
  -- is it necessary to make these optional
  -- additionally, can we have multiple headers with the same name?
  headers['Cache-Control'] = 'no-store, no-cache, must-revalidate'
  --web.header('Cache-Control', 'post-check=0, pre-check=0', False)
  headers['Pragma'] = 'no-cache'

  return headers
end

function redirect_to(url)
  headers = {}
  headers['Status'] = "303 See Other"
  headers['Location'] = url
  return headers, ""
end

-- main rendering function called by the wrapper
-- todo: should be add header utility functions? perhaps a response class
--     with reasonable defaults
function autonta.handle_request(env)
  request_uri = env.REQUEST_URI
  io.stderr:write(print_object(env))
  for _,v in pairs(autonta.mapping) do
    --a1, a2, a3, a4 = request_uri:match(v.pattern)
    match_elements = pack(request_uri:match(v.pattern))
    if #match_elements > 0 then
      --return create_default_headers(), print_object(v)
      return v.handler(env, match_elements)
    end
  end
  local headers = {}
  headers['Status'] = "404 Not found"
  headers['Content-Type'] = "text/html"
  html = "Path " .. request_uri .. " not found"
  return headers, html
end

return autonta
