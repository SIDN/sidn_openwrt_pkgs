m = Map("valibox", "Valibox") -- We want to edit the uci config file /etc/config/valibox

s = m:section(TypedSection, "language", "Language")
s.anonymous = true

o = s:option(ListValue, "language", translate("Language"))
o.description = translate("The language of the main Valibox pages (independent of OpenWrt/LuCI)")
o.default = "en_US"
o.optional = false
o.rmempty = false
o.widget = "select"

o:value("en_US")
o:value("nl_NL")

s = m:section(TypedSection, "options", "Options")
s.anonymous = true

o = s:option(Flag, "disable_nta", translate("Disable NTA management"))
o.description = "Do not let users set Negative trust anchors; only show DNSSEC errors"
o.default = o.disabled
o.rmempty = false

o = s:option(ListValue, "loglevel", translate("AutoNTA Log level"))
o.description = translate("The level of messages that are logged from AutoNTA.")
o.default = "INFO"
o.optional = false
o.rmempty = false
o.widget = "select"

o:value("DEBUG")
o:value("INFO")
o:value("WARNING")
o:value("ERROR")
o:value("CRITICAL")

return m -- Returns the map
