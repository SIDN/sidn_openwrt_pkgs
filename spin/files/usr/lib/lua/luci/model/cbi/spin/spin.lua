m = Map("spin", "SPIN") -- We want to edit the uci config file /etc/config/spin

s = m:section(TypedSection, "spind", "General")
s.anonymous = true

s = m:section(TypedSection, "spind", translate("Logging"))
s.anonymous = true

o = s:option(Flag, "log_usesyslog", translate("Log to syslog"))
o = s:option(Value, "log_file", translate("Log to file"))
o.description = "Leave blank to disable direct file logging"
o = s:option(ListValue, "log_loglevel", translate("Log level"))
o.optional = false
o.rmempty = false
o.widget = "select"
o:value("0")
o:value("1")
o:value("2")
o:value("3")
o:value("4")
o:value("5")
o:value("6")

s = m:section(TypedSection, "spind", translate("Spinweb"))
s.anonymous = true

o = s:option(Value, "spinweb_interfaces", translate("addresses"))
o.description = "The IP addresses to listen on for the web API. Comma-separated list"
o = s:option(Value, "spinweb_port", translate("port"))
o.default = 13026
o.description = "The port to listen on for the web API"
o = s:option(Value, "spinweb_tls_certificate_file", translate("TLS certificate"))
o.description = "The public certificate for https. Leave blank to disable https for spinweb."
o = s:option(Value, "spinweb_tls_key_file", translate("Private key file for using HTTPS with spinweb"))
o.description = "The private key for https. Leave blank to disable https for spinweb."
o = s:option(Value, "spinweb_password_file", translate("HTTP authentication password file"))
o.description = "The password file for HTTP authentication of spinweb pages. Leave blank to disable HTTP authentication.";

s = m:section(TypedSection, "spind", translate("MQTT"))
s.anonymous = true

o = s:option(Flag, "pubsub_run_mosquitto", translate("Run own instance of mosquitto"))
o.description = "If enabled, spind will start its own instance of mosquitto"
o = s:option(Value, "pubsub_run_password_file", translate("Mosquitto password file"))
o.description = "The password file for setting mqtt users and passwords in own mosquitto instance. Disable to allow passwordless mqtt use. Update or create passwords with mosquitto_passwd tool."

o = s:option(Value, "pubsub_host", translate("IP or host of mqtt server (mqtt)"))
o.description = "If running own instance, this is the IP or host mosquitto will listen on. If not, this is the host spind and spinweb will connect to."
o = s:option(Value, "pubsub_port", translate("Port of mqtt server (mqtt)"))
o.description = "If running own instance, this is the port mosquitto will listen on. If not, this is the mqtt port spind and spinweb will connect to."

o = s:option(Value, "pubsub_websocket_host", translate("IP or host of mqtt server (websockets)"))
o.description = "See pubsub_host, but for websocket connections"
o = s:option(Value, "pubsub_websocket_port", translate("Port of mqtt server (websockets)"))
o.description = "See pubsub_port, but for websocket connections"


return m
