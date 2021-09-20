module("luci.controller.valibox.valibox", package.seeall)

function index()
    entry({"admin", "valibox"}, firstchild(), _("Valibox"), 80)
    entry({"admin", "valibox", "settings" }, cbi("valibox/valibox"), _("Settings"), 1)
    entry({"admin", "valibox", "update_check" }, template("valibox/update_check"), _("Check for updates"), 2)
    entry({"admin", "valibox", "update_install" }, template("valibox/update_install"), nil, nil)
    entry({"admin", "valibox", "update_done" }, template("valibox/update_done"), nil, nil)
end
