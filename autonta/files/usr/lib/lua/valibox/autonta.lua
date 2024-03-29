local liluat = require 'valibox.liluat'
local language_keys = require 'valibox.language_keys'
local au = require 'valibox.autonta_util'
local vu = require 'valibox.valibox_update'
local cfg = require 'valibox.config'
local mio = require 'valibox.mio'
local posix = require 'posix'

local an_M = {}

local autonta = {}
autonta.__index = autonta

local ip4 = {} -- Store current IPv4 address

function an_M.create(config_file, fixed_langkey_file)
  local an = {}             -- our new object
  setmetatable(an,autonta)  -- make Account handle lookup
  an:init(config_file, fixed_langkey_file)
  return an
end

-- initial setup, load templates, etc.
function autonta:init(config_file, fixed_langkey_file)
  self:load_templates()

  self.config = cfg.create(config_file)
  self.config:read_config()

  local language_file = fixed_langkey_file
  if fixed_langkey_file == nil then
    language_file = "/usr/lib/valibox/autonta_lang/" .. self.config:get('language', 'language')
  end
  language_keys.load(language_file)
  au.debug("Language file " .. language_file .. " loaded")

  -- When handling requests or posts, the specific handler
  -- is found here; in order the REQUEST_URI value is matched
  -- the first match is the handler that is called
  if not self.mapping then
    self.mapping = {}
    table.insert(self.mapping, { pattern = '^/$', handler = self.handle_autonta_main })
    table.insert(self.mapping, { pattern = '^/autonta$', handler = self.handle_autonta_main })

    --table.insert(self.mapping, { pattern = '^/$', handler = self:handle_autonta_main })
    table.insert(self.mapping, { pattern = '^/autonta/nta_list$', handler = self.handle_ntalist })
    table.insert(self.mapping, { pattern = '^/autonta/set_nta/([a-zA-Z0-9.-]+)', handler = self.handle_set_nta })
    table.insert(self.mapping, { pattern = '^/autonta/remove_nta/([a-zA-Z0-9.-]+)$', handler = self.handle_remove_nta })
    table.insert(self.mapping, { pattern = '^/autonta/ask_nta/([a-zA-Z0-9.-]+)$', handler = self.handle_ask_nta })
    table.insert(self.mapping, { pattern = '^/autonta/set_passwords', handler = self.handle_set_passwords })

    -- redirect to SPIN
    table.insert(self.mapping, { pattern = '^/spin/start$', handler = self.handle_redirect_spin })
  end

  -- this is possibly called too early, but we try anyway
  local p = mio.subprocess("/sbin/get_ip4addr.sh", {}, nil, true, false, true)
  ip4 = p:read_line(true)
  p:close()
end

--
-- General utility functions (move to util or something?
--

-- load the templates
-- TODO: simply load every file in a (given?) directory
function autonta:load_templates()
  self.templates = {}
  self.base_template_name = "base.html"
  local dirname = 'templates/'
  local p = mio.subprocess('ls', {dirname}, nil, true)
  for name in p:read_line_iterator(true) do
    if au.string_endswith(name, '.html') then
      self.templates[name] = liluat.compile_file("templates/" .. name)
    end
  end
  p:close()
end

-- we have a two-layer template system; rather than adding headers
-- and footers to each template, we have a base template, which gets
-- the output from the 'inner' template as an argument ('main_html')
-- The outer template is called BASE
function autonta:render(template_name, args)
  if not args then args = {} end
  if not self.templates[template_name] then
    return "[Error: could not find template " .. template_name .. "]"
  end
  args['langkeys'] = language_keys
  args['main_html'] = liluat.render(self.templates[template_name], args)
  return liluat.render(self.templates['base.html'], args)
end

-- render just the page itself (no base.html supertemplate)
function autonta:render_raw(template_name, args)
  if not args then args = {} end
  if not self.templates[template_name] then
    return "[Error: could not find template " .. template_name .. "]"
  end
  args['langkeys'] = language_keys
  return liluat.render(self.templates[template_name], args)
end

--
-- Backend logic functions; TODO: move this to a utility-class
--
function autonta:is_first_run()
  return posix.stat("/etc/valibox_name_set") == nil
end

-- todo: we have a config file parser now, use that
function autonta:get_wifi_option(key)
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

function autonta:get_wifi_name()
  return self:get_wifi_option("ssid")
end

function autonta:get_wifi_pass()
  return self:get_wifi_option("key")
end

function autonta:update_wifi(wifi_name, wifi_pass)
  if not wifi_name or wifi_name == "" then wifi_name = self:get_wifi_name() end
  if not wifi_pass or wifi_pass == "" then wifi_pass = self:get_wifi_pass() end

  local f_in, err_in = io.open("/etc/config/wireless.in", "r")
  if not f_in then
    au.debug("Error: could not read /etc/config/wireless.in: " .. err_in)
    return
  end
  local f_out, err_out = io.open("/etc/config/wireless", "w")
  if not f_out or not f_out then
    au.debug("Error: could not write to /etc/config/wireless" .. err_out)
    return
  end
  for line in f_in:lines() do
    if line:find("XHWADDRX") then
      f_out:write("\toption encryption 'psk2'\n")
      f_out:write("\toption key '" .. wifi_pass .. "'\n")
      f_out:write("\toption ssid '" .. wifi_name .. "'\n")
    else
      f_out:write(line)
      if not au.string_endswith(line, "\n") then
        f_out:write("\n")
      end
    end
  end
  f_out:close()
  f_in:close()
  mio.subprocess("/sbin/wifi", { 'reload' }, nil, true):wait()
end

function autonta:update_admin_password(new_password)
  local p = mio.subprocess("/bin/passwd", {}, nil, true, false, true)
  p:read_line()
  p:write_line(new_password, true)
  p:write_line(new_password, true)
  local rcode = p:wait()
  if rcode ~= 0 then au.debug("Error running passwd: return code " .. rcode) end
  p:close()
end

function autonta:update_mqtt_password(new_password)
  local p = mio.subprocess("/usr/bin/mosquitto_passwd", { '/etc/spin/mosq_passwd', 'root' }, nil, true, false, true)
  p:write_line(new_password, true)
  p:write_line(new_password, true)
  local rcode = p:wait()
  if rcode ~= 0 then au.debug("Error running passwd: return code " .. rcode) end
  p:close()
end

function autonta:update_wifi_and_password(new_wifi_name, new_wifi_password, new_admin_password, new_mqtt_password)
  au.debug("Updating wifi and password settings")
  au.debug("ssid: " .. au.obj2str(new_wifi_name))

  if (new_wifi_name and new_wifi_name ~= "") or
     (new_wifi_password and new_wifi_password ~= "") then
    au.debug("Updating wireless settings")
    self:update_wifi(new_wifi_name, new_wifi_password)
  end

  if new_admin_password and new_admin_password ~= "" then
    au.debug("Updating administrator password")
    self:update_admin_password(new_admin_password)
    mio.execute("/usr/sbin/unbound-control local_zone_remove .", true)
    mio.execute("/etc/init.d/unbound restart", true)
  end

  if new_mqtt_password and new_mqtt_password ~= "" then
    au.debug("Updating MQTT password")
    self:update_mqtt_password(new_mqtt_password)
    mio.execute("/etc/init.d/spin restart", true)
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
function autonta:get_unbound_host_faildata(domain)
    local result = {}
    local cmd, args = mio.split_cmd('unbound-host -C /etc/unbound/unbound.conf ' .. domain)
    local pattern = "validation failure <([a-zA-Z.-]+) [A-Z]+ [A-Z]+>: (.*) from (.*) for (.*) (.*) while building chain of trust"
    local p = mio.subprocess(cmd, args, nil, true)
    -- todo: there a better way to know the process has spun up?
    posix.sleep(1)
    for line in p:read_line_iterator(true, 10000) do
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

function autonta:get_nta_list()
  local p = mio.subprocess('unbound-control', {'list_insecure'}, nil, true)
  local result = {}
  -- todo better way to see if subp is actually running
  posix.sleep(1)
  for nta in p:read_line_iterator(true, 10000) do
    table.insert(result, nta)
  end
  p:close()
  return result
end

function autonta:add_nta(domain)
  local p = mio.subprocess('unbound-control', {'insecure_add', domain}, nil, true)
  p:close()
end

function autonta:remove_nta(domain)
  local p = mio.subprocess('unbound-control', {'insecure_remove', domain}, nil, true)
  p:close()
end

function autonta:set_cookie(headers, cookie, value)
  headers['Set-Cookie'] = cookie .. "=" .. value .. ";Path=/"
end

function autonta:remove_cookie(headers, cookie)
  headers['Set-Cookie'] = cookie .. "=;Max-Age=0"
end

function autonta:get_cookie_value(env, cookie_name)
  au.debug("Find cookie: " .. cookie_name)
  local cookies = env.HTTP_COOKIE
  if not cookies then au.debug("No cookies sent") return nil end

  local hcookie_name = cookie_name .. "="
  for cookie in cookies:gmatch("([^;]+)") do
    cookie = cookie:match("%s*(%S+)%s*")
    --au.debug("Try " .. cookie)
    if au.string_startswith(cookie, hcookie_name) then
      local result = cookie.sub(cookie, string.len(hcookie_name) + 1)
      au.debug("Found! value: '"..result.."'")
      return result
    end
  end
  au.debug("cookie not found: " .. cookie_name)
  return "<cookie not found: " .. cookie_name .. ">"
end

function autonta:get_referer_match_line(env, path)
  --local host_match = "https?://(valibox\.)|(192\.168\.8\.1)/autonta/ask_nta/" .. domain
  local host_match = "https?://" .. env.HTTP_HOST .. "%.?"
  --if env.SERVER_PORT ~= 80 and env.SERVER_PORT ~= 443 then
  --  host_match = host_match .. ":" .. env.SERVER_PORT
  --end
  path = string.gsub(path, "%-", "%%-")
  return host_match .. path
end

-- if spin uses SSL, we need to set the link to https instead of http
function autonta:get_spinweb_protocol(env)
  local cmd, args = mio.split_cmd("/sbin/uci get spin.spind.spinweb_tls_certificate_file")
  local p,err = mio.subprocess(cmd, args, nil, true)
  if p == nil then
    return "http://"
  end
  local line,lerr = p:read_line(true, 20000)
  if line == nil then return "http://" end
  return "https://"
end

--
-- Actual specific page handlers
--
function autonta:handle_autonta_main(env)
  if self.config:updated() then self:init() end
  if self:is_first_run() then
    return self:redirect_to("//" .. ip4 .. "/autonta/set_passwords")
  end

  local headers = {}
  headers['Status'] = "200 OK"
  headers['Content-Type'] = "text/html"

  local args = {
      current_version = vu.get_current_version(),
  }
  local html = self:render_raw('index.html', args)

  return headers, html
end

function autonta:handle_ntalist(env, arg1, arg2, arg3, arg4)
  if self.config:updated() then self:init() end
  if self:is_first_run() then
    return self:redirect_to("//" .. ip4 .. "/autonta/set_passwords")
  end

  local headers = self:create_default_headers()
  local args = { ntas = self:get_nta_list() }
  local html = self:render('nta_list.html', args)
  return headers, html
end

function autonta:get_http_value(data, field_name)
  local hfield_name = field_name .. "="
  for field in data:gmatch("([^&]+)") do
    --au.debug("Try " .. field)
    if au.string_startswith(field, hfield_name) then
      local result = field.sub(field, string.len(hfield_name) + 1)
      au.debug("Found! value: '"..result.."'")
      return result
    end
  end
  au.debug("field not found: " .. field_name)
  return "<field not found: " .. field_name .. ">"
end

function autonta:get_http_post_value(env, field_name)
  if not env.POST_DATA then return "<no post data found for field: " .. field_name .. ">" end
  au.debug("Retrieving '" .. field_name .. "' from post data '" .. env.POST_DATA .."'")
  return self:get_http_value(env.POST_DATA, field_name)
end

function autonta:get_http_query_value(env, field_name)
  if not env.QUERY_STRING then return "<no query string found for field: " .. field_name .. ">" end
  au.debug("Retrieving '" .. field_name .. "' from query string '" .. env.QUERY_STRING .."'")
  return self:get_http_value(env.QUERY_STRING, field_name)
end

function autonta:check_validity(env, host_match, dst_cookie_val, dst_http_val)
  local http_referer = env.HTTP_REFERER
  if not http_referer then http_referer = "<not sent>" end
  if not dst_http_val then dst_http_val = "<not sent>" end
  if not http_referer:match(host_match) then
    au.debug("Referer match failure")
    au.debug("http referer: '" .. http_referer .. "'")
    au.debug("does not match: '" .. host_match .. "'")
    au.debug("\n")
    return false
  else
    if dst_http_val ~= dst_cookie_val then
      au.debug("DST cookie mismatch: " .. dst_http_val .. " != " .. dst_cookie_val)
      return false
    else
      return true
    end
  end
end

function autonta:handle_set_nta(env, args)
  if self.config:updated() then self:init() end

  local headers = self:create_default_headers()
  local domain = args[1]
  local host_match = self:get_referer_match_line(env, "/autonta/ask_nta/" .. domain)
  local dst_cookie_val = self:get_cookie_value(env, "valibox_nta")
  local q_dst_val = self:get_http_query_value(env, "dst")

  if self:check_validity(env, host_match, dst_cookie_val, q_dst_val) then
    self:add_nta(domain)
    self:remove_cookie(headers, "valibox_nta")
    local html = self:render('nta_set.html', { domain=domain })
    return headers, html
  else
    return self:redirect_to("//" .. ip4 .. "/autonta/ask_nta/" .. domain)
  end
end

function autonta:handle_remove_nta(env, args)
  local headers = self:create_default_headers()
  local domain = args[1]

  -- no DST needed here. Should we check referer?
  -- is it bad if a user is tricked into *removing* an NTA?
  self:remove_nta(domain)
  return self:redirect_to("/autonta/nta_list")
end

function autonta:create_dst()
  return au.randomstring(12)
end

function autonta:handle_ask_nta(env, args)
  local headers = self:create_default_headers()
  local domain = args[1]
  if self.config:updated() then self:init() end
  if self:is_first_run() then
    return self:redirect_to("//" .. ip4 .. "/autonta/set_passwords")
  end

  -- create a double-submit token
  local dst = self:create_dst()
  self:set_cookie(headers, "valibox_nta", dst)

  -- this one fails regularly (interrupted system call,
  -- seems an issue with lua 5.1 and perhaps nginx,
  -- Just try a number of times
  local psuc
  local err = self:get_unbound_host_faildata(domain)

  if err == nil then return self:redirect_to("//" .. domain) end

  local nta_disabled = self.config:get('options', 'disable_nta') == '1'

  -- add all superdomains
  if au.string_endswith(domain, ".") then domain = string.sub(domain, 1, string.len(domain)-1) end
  local hosts = {}
  local domain_part = domain
  table.insert(hosts, domain_part)
  while domain_part:find("%.") do
    domain_part = domain_part:sub(domain_part:find("%.")+1, domain_part:len())
    au.debug("add " .. domain_part)
    table.insert(hosts, domain_part)
  end

  local targs = { dst = dst, name = domain, names = hosts, err = err, nta_disabled = nta_disabled }
  local html = self:render('ask_nta.html', targs)
  return headers, html
end

function autonta:handle_set_passwords_get(env)
  local headers = self:create_default_headers()

  if self.config:updated() then self:init() end

  au.debug("set passwords (GET) called")

  -- todo: check first run? (wait, shouldnt we allow this page anyway?)

  local dst = self:create_dst()
  self:set_cookie(headers, "valibox_setpass", dst)

  local old_wifi_name = self:get_wifi_name()

  local html = self:render('askpasswords.html', { dst = dst, old_wifi_name = old_wifi_name })
  return headers, html
end

function replace_urlencoded_char(text)
  return string.char(tonumber(text:sub(2), 16))
end

function decode_www_formdata(text)
  local result = text:gsub("\+", " ")
  return result:gsub("%%[0-9a-fA-F][0-9a-fA-F]", replace_urlencoded_char)
end

function autonta:handle_set_passwords_post(env)
  au.debug("set passwords (POST) called")
  local headers = self:create_default_headers()
  local html = ""

  local dst = self:get_http_post_value(env, "dst")
  local wifi_name = decode_www_formdata(self:get_http_post_value(env, "wifi_name"))
  local wifi_password = decode_www_formdata(self:get_http_post_value(env, "wifi_password"))
  local wifi_password_repeat = decode_www_formdata(self:get_http_post_value(env, "wifi_password_repeat"))
  local admin_password = decode_www_formdata(self:get_http_post_value(env, "admin_password"))
  local admin_password_repeat = decode_www_formdata(self:get_http_post_value(env, "admin_password_repeat"))
  local mqtt_password = decode_www_formdata(self:get_http_post_value(env, "mqtt_password"))
  local mqtt_password_repeat = decode_www_formdata(self:get_http_post_value(env, "mqtt_password_repeat"))

  local host_match = self:get_referer_match_line(env, "/autonta/set_passwords")
  local dst_cookie_val = self:get_cookie_value(env, "valibox_setpass")
  if self:check_validity(env, host_match, dst_cookie_val, dst) then
    if wifi_password ~= wifi_password_repeat or admin_password ~= admin_password_repeat or mqtt_password ~= mqtt_password_repeat then
      dst = self:create_dst()
      self:set_cookie(headers, "valibox_setpass", dst)
      html = self:render('askpasswords.html', { dst = dst, old_wifi_name = wifi_name, error = language_keys.get('PASS_MISMATCH') })
      return headers, html
    end
    if wifi_password:len() < 8 then
      self:set_cookie(headers, "valibox_setpass", dst)
      html = self:render('askpasswords.html', { dst = dst, old_wifi_name = wifi_name, error = language_keys.get('PASS_TOOSHORT') })
      return headers, html
    end

    self:update_wifi_and_password(wifi_name, wifi_password, admin_password, mqtt_password)

    self:remove_cookie(headers, "valibox_setpass")
    html = self:render('passwordsset.html')
    return headers, html
  else
    return self:redirect_to("//" .. ip4 .. "/autonta/set_passwords")
  end
end

function autonta:handle_set_passwords(env)
  if self.config:updated() then self:init() end
  -- if these settings have been done already, the user should
  -- go through the LuCI interface which requires the administrator
  -- password
  if not self:is_first_run() then
    return self:redirect_to("/cgi-bin/luci")
  end


  if env.REQUEST_METHOD == "POST" then
    return self:handle_set_passwords_post(env)
  else
    return self:handle_set_passwords_get(env)
  end
end

function autonta:handle_domain(env, domain)
  if self.config:updated() then self:init() end
  if self:is_first_run() then
    return self:redirect_to("//" .. ip4 .. "/autonta/set_passwords")
  end

  return self:redirect_to("//" .. ip4 .. "/autonta/ask_nta/" .. domain)
end

function autonta:handle_redirect_spin(env, domain)
  return self:redirect_to(self.get_spinweb_protocol() .. ip4 .. ":13026/spin_graph/graph.html")
end

function autonta:create_default_headers()
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

function autonta:redirect_to(url)
  au.debug("Redirecting client to: " .. url)
  local headers = {}
  headers['Status'] = "303 See Other"
  headers['Location'] = url
  return headers, ""
end


-- main rendering function called by the wrapper
-- todo: should be add header utility functions? perhaps a response class
--     with reasonable defaults
function autonta:handle_request(env)
  -- if we are not directly called, do the NTA magic
  local domain, port = au.split_host_port(env.HTTP_HOST)
  au.debug("[XX] DOMAIN: '" .. domain .. "' PORT: " .. au.obj2str(port))
  if ip4 == nil then
      local p = mio.subprocess("/sbin/get_ip4addr.sh", {}, nil, true, false, true)
      ip4 = p:read_line(true)
      p:close()
  end
  if domain ~= "valibox" and domain ~= ip4 then
    return self:handle_domain(env, domain)
  end

  -- called directly, find the correct mapping
  local request_uri = env.REQUEST_URI
  au.debug(au.obj2str(env))
  au.debug("\n")
  for _,v in pairs(self.mapping) do
    local match_elements = au.pack(request_uri:match(v.pattern))
    if #match_elements > 0 then
      --return self:create_default_headers(), au.obj2str(v)
      -- handlers should return 2 or 3 elements;
      -- the HTTP headers, the HTML to send, and an optional
      -- function that will be called after rendering, which
      -- takes no arguments
      return v.handler(self, env, match_elements)
    end
  end
  local headers = {}
  headers['Status'] = "404 Not found"
  headers['Content-Type'] = "text/html"
  local html = "Path " .. request_uri .. " not found"
  return headers, html
end

return an_M
