liluat = require'liluat'
language_keys = require 'language_keys'
au = require 'autonta_util'
vu = require 'valibox_update'
config = require 'config'
posix = require 'posix'

autonta = {}

-- initial setup, load templates, etc.
function autonta.init()
  autonta.templates = {}
  autonta.load_templates()
  autonta.base_template_name = "base.html"

  autonta.config = config.read_config("/etc/config/valibox")

  local language_file = "/usr/lib/valibox/autonta_lang/" .. autonta.config:get('language', 'language')
  language_keys.load(language_file)
  au.debug("Language file " .. language_file .. " loaded")

  -- When handling requests or posts, the specific handler
  -- is found here; in order the REQUEST_URI value is matched
  -- the first match is the handler that is called
  if not autonta.mapping then
    autonta.mapping = {}
    table.insert(autonta.mapping, { pattern = '^/$', handler = autonta.handle_autonta_main })
    table.insert(autonta.mapping, { pattern = '^/autonta$', handler = autonta.handle_autonta_main })

    --table.insert(autonta.mapping, { pattern = '^/$', handler = autonta.handle_autonta_main })
    table.insert(autonta.mapping, { pattern = '^/autonta/nta_list$', handler = autonta.handle_ntalist })
    table.insert(autonta.mapping, { pattern = '^/autonta/set_nta/([a-zA-Z0-9.-]+)', handler = autonta.handle_set_nta })
    table.insert(autonta.mapping, { pattern = '^/autonta/remove_nta/([a-zA-Z0-9.-]+)$', handler = autonta.handle_remove_nta })
    table.insert(autonta.mapping, { pattern = '^/autonta/ask_nta/([a-zA-Z0-9.-]+)$', handler = autonta.handle_ask_nta })
    table.insert(autonta.mapping, { pattern = '^/autonta/update_check$', handler = autonta.handle_update_check })
    table.insert(autonta.mapping, { pattern = '^/autonta/update_install', handler = autonta.handle_update_install })
    table.insert(autonta.mapping, { pattern = '^/autonta/set_passwords', handler = autonta.handle_set_passwords })
  end
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
  local dirname = 'templates/'
  local p = mio.subprocess(mio.split_cmd('ls ' .. dirname))
  for name in p:readlines(true) do
    if string_endswith(name, '.html') then
      autonta.templates[name] = liluat.compile_file("templates/" .. name)
    end
  end
  p:close()
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
  -- TODO
  return posix.stat("/etc/valibox_name_set") == nil
end

function get_wifi_option(key)
  local f = io.open("/etc/config/wireless", "r")
  if not f then return "<no wireless config found>" end
  local qpattern = "^%s+option%s+([a-z]+)%s+'?([^']+)"
  local pattern = "^%s+option%s+([a-z]+)%s+(%S+)"

  for line in f:lines() do
    local ckey,cval = line:match(qpattern)
    if ckey and cval and ckey == key then return cval end
    ckey,cval = line:match(pattern)
    if ckey and cval and ckey == key then return cval end
  end
  return "<no name found>"
end

function autonta.get_wifi_name()
  return get_wifi_option("ssid")
end

function get_wifi_pass()
  return get_wifi_option("key")
end

function update_wifi(wifi_name, wifi_pass)
  if not wifi_name then wifi_name = autonta.get_wifi_name() end
  if not wifi_pass then wifi_pass = get_wifi_pass() end

  local f_in, err = io.open("/etc/config/wireless.in", "r")
  if not f_in then
    au.debug("Error: could not read /etc/config/wireless.in: " .. err)
    return
  end
  local f_out, err = io.open("/etc/config/wireless", "w")
  if not f_out or not f_out then
    au.debug("Error: could not write to /etc/config/wireless" .. err)
    return
  end
  for line in f_in:lines() do
    if line:find("XHWADDRX") then
      f_out:write("\toption encryption 'psk2'\n")
      f_out:write("\toption key '" .. wifi_pass .. "'\n")
      f_out:write("\toption ssid '" .. wifi_name .. "'\n")
    else
      f_out:write(line)
      if not string_endswith(line, "\n") then
        f_out:write("\n")
      end
    end
  end
  f_out:close()
  f_in:close()
  mio.subprocess("./restart_network.sh", {}, 3)
end

function update_admin_password(new_password)
  -- keep current streams, uhttpd will get confused otherwise
  --local orig_stdin = io.stdin
  --local orig_stdout = io.stdout
  --local orig_stderr = io.stderr
  local p = mio.subprocess("/usr/bin/passwd")
  p:writeline(new_password, true)
  p:writeline(new_password, true)
  p:close()
  --io.stdin = orig_stdin
  --io.stdout = orig_stdout
  --io.stderr = orig_stderr
end

function autonta.update_wifi_and_password(new_wifi_name, new_wifi_password, new_admin_password)
  au.debug("Updating wifi and password settings")
  au.debug("ssid: " .. au.obj2str(new_wifi_name))

  if new_admin_password and new_admin_password ~= "" then
    au.debug("Updating administrator password")
    update_admin_password(new_admin_password)
    os.execute("/usr/sbin/unbound-control local_zone_remove .")
    os.execute("/etc/init.d/unbound restart")
  end

  if (new_wifi_name and new_wifi_name ~= "") or
     (new_wifi_password and new_wifi_password ~= "") then
    au.debug("Updating wireless settings")
    update_wifi(new_wifi_name, new_wifi_password)
  end

  au.debug("Done updating wifi and password settings")
  local f = mio.file_writer("/etc/valibox_name_set")
  f:close()
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
    local p = mio.subprocess(mio.split_cmd(cmd))
    -- todo: there a better way to know the process has spun up?
    posix.sleep(1)
    for line in p:readlines(true, 10000) do
        au.debug("[XX] Line: " .. line)
        result.target_dname, result.err_msg, result.auth_server, result.fail_type, result.fail_dname = line:match(pattern)
        if result.target_dname then
            p:close()
            return result
        end
    end
    p:close()
    au.debug("Error, no suitable output read from " .. cmd)
    return nil
end

function get_nta_list()
  local p = mio.subprocess(mio.split_cmd('unbound-control list_insecure'))
  local result = {}
  -- todo better way to see if subp is actually running
  posix.sleep(1)
  for nta in p:readlines(true, 10000) do
    table.insert(result, nta)
  end
  p:close()
  return result
end

function add_nta(domain)
  local p = mio.subprocess(mio.split_cmd('unbound-control insecure_add ' .. domain))
  p:close()
end

function remove_nta(domain)
  local p = mio.subprocess(mio.split_cmd('unbound-control insecure_remove ' .. domain))
  p:close()
end

function set_cookie(headers, cookie, value)
  headers['Set-Cookie'] = cookie .. "=" .. value .. ";Path=/"
end

function remove_cookie(headers, cookie)
  headers['Set-Cookie'] = cookie .. "=;Max-Age=0"
end

function get_cookie_value(env, cookie_name)
  au.debug("Find cookie: " .. cookie_name)
  local cookies = env.HTTP_COOKIE
  if not cookies then au.debug("No cookies sent") return nil end

  local hcookie_name = cookie_name .. "="
  for cookie in cookies:gmatch("([^;]+)") do
    cookie = cookie:match("%s*(%S+)%s*")
    --au.debug("Try " .. cookie)
    if string_startswith(cookie, hcookie_name) then
      local result = cookie.sub(cookie, string.len(hcookie_name) + 1)
      au.debug("Found! value: '"..result.."'")
      return result
    end
  end
  au.debug("cookie not found: " .. cookie_name)
  return "<cookie not found: " .. cookie_name .. ">"
end

function get_referer_match_line(env, path)
  --local host_match = "https?://(valibox\.)|(192\.168\.8\.1)/autonta/ask_nta/" .. domain
  local host_match = "https?://" .. env.HTTP_HOST .. "%.?"
  --if env.SERVER_PORT ~= 80 and env.SERVER_PORT ~= 443 then
  --  host_match = host_match .. ":" .. env.SERVER_PORT
  --end
  return host_match .. path
end


--
-- Actual specific page handlers
--
function autonta.handle_autonta_main(env)
  if autonta.config:updated() then autonta.init() end
  if is_first_run() then
    return redirect_to("/autonta/set_passwords")
  end

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
  if autonta.config:updated() then autonta.init() end
  if is_first_run() then
    return redirect_to("/autonta/set_passwords")
  end

  local headers = create_default_headers()
  args = { ntas = get_nta_list() }
  html = autonta.render('nta_list.html', args)
  return headers, html
end

function get_http_value(data, field_name)
  local hfield_name = field_name .. "="
  for field in data:gmatch("([^&]+)") do
    --au.debug("Try " .. field)
    if string_startswith(field, hfield_name) then
      local result = field.sub(field, string.len(hfield_name) + 1)
      au.debug("Found! value: '"..result.."'")
      return result
    end
  end
  au.debug("field not found: " .. field_name)
  return "<field not found: " .. field_name .. ">"
end

function get_http_post_value(env, field_name)
  if not env.POST_DATA then return "<no post data found for field: " .. field_name .. ">" end
  au.debug("Retrieving '" .. field_name .. "' from post data '" .. env.POST_DATA .."'")
  return get_http_value(env.POST_DATA, field_name)
end

function get_http_query_value(env, field_name)
  if not env.QUERY_STRING then return "<no query string found for field: " .. field_name .. ">" end
  au.debug("Retrieving '" .. field_name .. "' from query string '" .. env.QUERY_STRING .."'")
  return get_http_value(env.QUERY_STRING, field_name)
end

function check_validity(env, host_match, dst_cookie_val, dst_http_val)
  if not dst_http_val then dst_http_val = "<not sent>" end
  if not env.HTTP_REFERER:match(host_match) then
    au.debug("Referer match failure")
    au.debug("http referer: '" .. env.HTTP_REFERER .. "'")
    au.debug("does not match: '" .. host_match .. "'")
    au.debug("\n")
    return false
  else
    if dst_http_val ~= dst_cookie_val then
      au.debug("DST cookie mismatch: " .. dst_http_val .. " != " .. q_dst_val)
      return false
    else
      return true
    end
  end
end

function autonta.handle_set_nta(env, args)
  if autonta.config:updated() then autonta.init() end

  local headers = create_default_headers()
  local domain = args[1]
  local host_match = get_referer_match_line(env, "/autonta/ask_nta/" .. domain)
  local dst_cookie_val = get_cookie_value(env, "valibox_nta")
  local q_dst_val = get_http_query_value(env, "dst")

  if check_validity(env, host_match, dst_cookie_val, q_dst_val) then
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
  if autonta.config:updated() then autonta.init() end
  if is_first_run() then
    return redirect_to("/autonta/set_passwords")
  end

  local headers = create_default_headers()
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
  local q_dst_val = get_http_query_value(env, "dst")
  if check_validity(env, host_match, dst_cookie_val, q_dst_val) then
    -- actual update call goes here
    local cmd = "./update_system.lua"
    local args = {}
    table.insert(args, "-i")
    table.insert(args, "-w")
    if beta then table.insert(args, "-b") end
    if keep_settings then table.insert(args, "-k") end

    au.debug("Calling update command: " .. cmd .. " " .. strjoin(" ", args))
    mio.subprocess(cmd, args, 3)

    local board_name = vu.get_board_name()
    local firmware_info = vu.get_firmware_board_info(beta, "", true, board_name)
    html = autonta.render('update_install.html', { update_version=firmware_info.version, update_download_success=true})
    remove_cookie(headers, "valibox_update")
    return headers, html
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
  if autonta.config:updated() then autonta.init() end
  if is_first_run() then
    return redirect_to("/autonta/set_passwords")
  end

  -- create a double-submit token
  local dst = create_dst()
  set_cookie(headers, "valibox_nta", dst)

  -- this one fails regularly (interrupted system call,
  -- seems an issue with lua 5.1 and perhaps nginx,
  -- Just try a number of times
  local psuc
  local err
  for i=1,50 do
    psuc, err = pcall(get_unbound_host_faildata, domain)
    if psuc then break end
    au.debug("error calling unbound-host (attempt " .. i .. "): " .. err)
  end

  if err == nil then return redirect_to("//" .. domain) end

  local nta_disabled = autonta.config:get('options', 'disable_nta') == '1'

  -- add all superdomains
  if string_endswith(domain, ".") then domain = string.sub(domain, 1, string.len(domain)-1) end
  local hosts = {}
  local domain_part = domain
  table.insert(hosts, domain_part)
  while domain_part:find("%.") do
    domain_part = domain_part:sub(domain_part:find("%.")+1, domain_part:len())
    au.debug("add " .. domain_part)
    table.insert(hosts, domain_part)
  end

  local targs = { dst = dst, name = domain, names = hosts, err = err, nta_disabled = nta_disabled }
  html = autonta.render('ask_nta.html', targs)
  return headers, html
end

function autonta.handle_set_passwords_get(env)
  local headers = create_default_headers()

  if autonta.config:updated() then autonta.init() end

  au.debug("set passwords (GET) called")

  -- todo: check first run? (wait, shouldnt we allow this page anyway?)

  local dst = create_dst()
  set_cookie(headers, "valibox_setpass", dst)

  local old_wifi_name = autonta.get_wifi_name()

  local html = autonta.render('askpasswords.html', { dst = dst, old_wifi_name = old_wifi_name })
  return headers, html
end

function autonta.handle_set_passwords_post(env)
  au.debug("set passwords (POST) called")
  local headers = create_default_headers()
  local html = ""

  local dst = get_http_post_value(env, "dst")
  local wifi_name = get_http_post_value(env, "wifi_name")
  local wifi_password = get_http_post_value(env, "wifi_password")
  local wifi_password_repeat = get_http_post_value(env, "wifi_password_repeat")
  local admin_password = get_http_post_value(env, "admin_password")
  local admin_password_repeat = get_http_post_value(env, "admin_password_repeat")

  local host_match = get_referer_match_line(env, "/autonta/set_passwords")
  local dst_cookie_val = get_cookie_value(env, "valibox_setpass")
  if check_validity(env, host_match, dst_cookie_val, dst) then
    if wifi_password ~= wifi_password_repeat or admin_password ~= admin_password_repeat then
      dst = create_dst()
      set_cookie(headers, "valibox_setpass", dst)
      html = autonta.render('askpasswords.html', { dst = dst, old_wifi_name = wifi_name, error = language_keys.get('PASS_MISMATCH') })
      return headers, html
    end

    autonta.update_wifi_and_password(wifi_name, wifi_password, admin_password)

    remove_cookie(headers, "valibox_setpass")
    html = autonta.render('passwordsset.html')
    return headers, html
  else
    return redirect_to("/autonta/set_passwords")
  end
end

function autonta.handle_set_passwords(env)
  if autonta.config:updated() then autonta.init() end
  -- if these settings have been done already, the user should
  -- go through the LuCI interface which requires the administrator
  -- password
  if not is_first_run() then
    return redirect_to("/cgi-bin/luci")
  end


  if env.REQUEST_METHOD == "POST" then
    return autonta.handle_set_passwords_post(env)
  else
    return autonta.handle_set_passwords_get(env)
  end
end

function autonta.handle_domain(env, domain)
  if autonta.config:updated() then autonta.init() end
  if is_first_run() then
    return redirect_to("/autonta/set_passwords")
  end

  return redirect_to("//valibox./autonta/ask_nta/" .. domain)
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
  au.debug("Redirecting client to: " .. url)
  headers = {}
  headers['Status'] = "303 See Other"
  headers['Location'] = url
  return headers, ""
end

function split_host_port(host_str)
  local domain, port = host_str:match("([^:]+):([0-9]+)")
  if domain and port then return domain,port else return host_str end
end

-- main rendering function called by the wrapper
-- todo: should be add header utility functions? perhaps a response class
--     with reasonable defaults
function autonta.handle_request(env)
  -- if we are not directly called, do the NTA magic
  local domain, port = split_host_port(env.HTTP_HOST)
  au.debug("[XX] DOMAIN: '" .. domain .. "' PORT: " .. au.obj2str(port))
  if domain ~= "valibox" and domain ~= "192.168.8.1" then
    return autonta.handle_domain(env, domain)
  end

  -- called directly, find the correct mapping
  local request_uri = env.REQUEST_URI
  au.debug(au.obj2str(env))
  au.debug("\n")
  for _,v in pairs(autonta.mapping) do
    match_elements = pack(request_uri:match(v.pattern))
    if #match_elements > 0 then
      --return create_default_headers(), au.obj2str(v)
      -- handlers should return 2 or 3 elements;
      -- the HTTP headers, the HTML to send, and an optional
      -- function that will be called after rendering, which
      -- takes no arguments
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
