liluat = require'liluat'
language_keys = require 'language_keys'
au = require 'autonta_util'
vu = require 'valibox_update'

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
  table.insert(autonta.mapping, { pattern = '^/autonta/update_check$', handler = autonta.handle_update_check })
  table.insert(autonta.mapping, { pattern = '^/autonta/update_install', handler = autonta.handle_update_install })
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
  if not args then args = {} end
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
-- Backend logic functions; TODO: move this to a utility-class
--
function is_first_run()
  return false
end

-- Calls unbound-host to get dnssec failure information
-- returns a dict containing:
-- target_dname: the domain name that failed validation
-- err_msg: the error message
-- auth_server: the authoritative server that sent the bad reply
-- fail_type: the type of dnssec failure
-- fail_dname: the specific domain name where validation failed
function get_unbound_host_faildata(domain)
    local result = {}
    local cmd = 'unbound-host -C /etc/unbound/unbound.conf ' .. domain
    local pattern = "validation failure <([a-zA-Z.-]+) [A-Z]+ [A-Z]+>: (.*) from (.*) for (.*) (.*) while building chain of trust"
    for line in io.popen(cmd):lines() do
        result.target_dname, result.err_msg, result.auth_server, result.fail_type, result.fail_dname = line:match(pattern)
        if result.target_dname then
            return result
        end
    end
    au.debug("Error, no suitable output read from " .. cmd)
    return nil
end

function get_nta_list()
  local f = io.popen('unbound-control list_insecure')
  local result = {}
  for nta in f:lines() do
    table.insert(result, nta)
  end
  return result
end

function add_nta(domain)
  local f = io.popen('unbound-control insecure_add ' .. domain)
end

function remove_nta(domain)
  local f = io.popen('unbound-control insecure_remove ' .. domain)
end

function set_cookie(headers, cookie, value)
  headers['Set-Cookie'] = cookie .. "=" .. value .. ";Path=/"
end

function remove_cookie(headers, cookie)
  headers['Set-Cookie'] = cookie .. "=;Max-Age=0"
end

function get_cookie_value(env, cookie)
  au.debug("Find cookie: " .. cookie)
  local cookie_part = cookie .. "="
  local headers = env.headers
  for k,v in pairs(env) do
    au.debug("Try header '" .. k .. "'")
    if k == "HTTP_COOKIE" then
      au.debug("Try cookie '" .. v .. "'")
      if string_startswith(v, cookie_part) then
        local cookie_data = string.sub(v, string.len(cookie_part) + 1)
        au.debug("Cookie found! value: '" .. cookie_data .. "'")
        return cookie_data
      end
    end
  end
  au.debug("Cookie not found")
  return "<cookie not found>"
end

function get_referer_match_line(env, path)
  --local host_match = "https?://(valibox\.)|(192\.168\.8\.1)/autonta/ask_nta/" .. domain
  local host_match = "https?://" .. env.SERVER_ADDR
  if env.SERVER_PORT ~= 80 and env.SERVER_PORT ~= 443 then
    host_match = host_match .. ":" .. env.SERVER_PORT
  end
  return host_match .. path
end


--
-- Actual specific page handlers
--
function autonta.handle_autonta_main(env)
  local headers = {}
  headers['Status'] = "200 OK"
  headers['Content-Type'] = "text/html"

  args = {
      current_version = vu.get_current_version()
  }
  html = autonta.render_raw('index.html', args)

  return headers, html
end

function autonta.handle_ntalist(env, arg1, arg2, arg3, arg4)
  local headers = create_default_headers()
  -- todo: reload config?
  if is_first_run() then
    return redirect_to("/autonta/set_passwords")
  end

  args = { ntas = get_nta_list() }
  html = autonta.render('nta_list.html', args)
  return headers, html
end

function get_http_query_value(env, field_name)
  au.debug("Retrieving '" .. field_name .. "' from query string '" .. env.QUERY_STRING .."'")
  local hfield_name = field_name .. "="
  for field in env.QUERY_STRING:gmatch("([^&]+)") do
    au.debug("Try " .. field)
    if string_startswith(field, hfield_name) then
      local result = field.sub(field, string.len(hfield_name) + 1)
      au.debug("Found! value: '"..result.."'")
      return result
    end
  end
  au.debug("query field not found: " .. field_name)
  return "<query field not found: " .. field_name .. ">"
end

function check_validity(env, host_match, dst_cookie_val)
  if not env.HTTP_REFERER:match(host_match) then
    au.debug("Referer match failure")
    au.debug("http referer: '" .. env.HTTP_REFERER .. "'")
    au.debug("does not match: '" .. host_match .. "'")
    au.debug("\n")
    return false
  else
    local query_string = env.QUERY_STRING
    -- todo: generalize query string match (see above now)
    local q_dst_val = get_http_query_value(env, "dst")
    au.debug("Query string: " .. query_string)
    au.debug("q_dst_val: " .. q_dst_val)
    if q_dst_val ~= dst_cookie_val then
      au.debug("DST cookie mismatch: " .. dst_cookie_val .. " != " .. q_dst_val)
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

  local host_match = get_referer_match_line(env, "/autonta/ask_nta/" .. domain)
  local dst_cookie_val = get_cookie_value(env, "valibox_nta")
  if check_validity(env, host_match, dst_cookie_val) then
    add_nta(domain)
    remove_cookie(headers, "valibox_nta")
    html = autonta.render('nta_set.html', { domain=domain })
    return headers, html
  else
    return redirect_to("/autonta/ask_nta/" .. domain)
  end
end

function autonta.handle_remove_nta(env, args)
  local headers = create_default_headers()
  local domain = args[1]

  -- no DST needed here. Should we check referer?
  -- is it bad if a user is tricked into *removing* an NTA?
  remove_nta(domain)
  return redirect_to("/autonta/nta_list")
end

function autonta.handle_update_check(env)
  local headers = create_default_headers()

  -- todo: read config

  local current_version = vu.get_current_version()
  local currently_beta = false
  if current_version:find("beta") then
    currently_beta = true
  end

  local board_name = vu.get_board_name()

  -- fetch info for both the current line and the 'other' line,
  -- depending on whether this is a beta or release version
  local firmware_info = vu.get_firmware_board_info(currently_beta, "", true, board_name)
  au.debug("[XX] THIS VERSION INFO:")
  au.debug(au.obj2str(firmware_info))
  au.debug("[XX] OTHER VERSION INFO:")
  local other_firmware_info = vu.get_firmware_board_info(not currently_beta, "", true, board_name)
  au.debug(au.obj2str(other_firmware_info))
  au.debug("[XX] end of PSA")

  -- create a double-submit token
  local dst = create_dst()
  set_cookie(headers, "valibox_update", dst)

  local targs = {}
  targs.dst = dst
  targs.update_check_failed = false
  targs.update_available = false
  targs.current_version = current_version
  targs.currently_beta = currently_beta
  targs.other_version = ""
  targs.update_version = ""
  targs.update_info = ""

  if not firmware_info or not other_firmware_info then
    targs.update_check_failed = true
  else

    local update_version = vu.update_available(firmware_info)
    if vu.update_available(firmware_info) then
      targs.update_available = true
      targs.update_version = update_version
      targs.update_info = vu.fetch_update_info_txt(firmware_info, "")
    end
    targs.other_version = vu.update_available(other_firmware_info)
  end
  au.debug("[XX] passing arguments: ")
  au.debug(au.obj2str(targs))
  return headers, autonta.render('update_check.html', targs)
end

function autonta.handle_update_install(env)
  local headers = create_default_headers()
  local query_dst = get_http_query_value(env, "dst")
  local keep_settings = get_http_query_value(env, "keepsettings") == "on"
  local beta = get_http_query_value(env, "version") == "beta"

  local host_match = get_referer_match_line(env, "/autonta/update_check")
  local dst_cookie_val = get_cookie_value(env, "valibox_update")
  if check_validity(env, host_match, dst_cookie_val) then

    -- actual update call goes here
    local board_name = vu.get_board_name()
    local firmware_info = vu.get_firmware_board_info(beta, "", true, board_name)
    if firmware_info then
        local result = vu.install_update(firmware_info, keep_settings, "")
        html = autonta.render('update_install.html', { update_version=firmware_info.version, update_download_success=result})
        remove_cookie(headers, "valibox_update")
        return headers, html
    end
  end
  -- Invalid request or failure, send back to update page
  return redirect_to("/autonta/update_check")
end

-- TODO: move to util
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
    return redirect_to("autonta/set_passwords")
  end

  -- create a double-submit token
  local dst = create_dst()
  set_cookie(headers, "valibox_nta", dst)

  -- TODO: unbound-host

  local err = get_unbound_host_faildata(domain)

  -- TODO: check config to see if nta has not been disabled
  local nta_disabled = false

  -- add all superdomains
  if string_endswith(domain, ".") then domain = string.sub(domain, 1, string.len(domain)-1) end
  local hosts = {}
  table.insert(hosts, domain)
  while domain:find("%.") do
    domain = domain:sub(domain:find("%.")+1, domain:len())
    au.debug("add " .. domain)
    table.insert(hosts, domain)
  end

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
  au.debug(au.obj2str(env))
  au.debug("\n")
  for _,v in pairs(autonta.mapping) do
    --a1, a2, a3, a4 = request_uri:match(v.pattern)
    match_elements = pack(request_uri:match(v.pattern))
    if #match_elements > 0 then
      --return create_default_headers(), au.obj2str(v)
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
