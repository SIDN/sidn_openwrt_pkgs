module("luci.controller.valibox.valibox", package.seeall)

function index()
    entry({"admin", "valibox"}, firstchild(), _("Valibox"), 80)
    entry({"admin", "valibox", "settings" }, cbi("valibox/valibox"), _("Settings"), 1)
    entry({"admin", "valibox", "update_check" }, cbi("valibox/update_check"), _("Check for updates"), 2)
end
