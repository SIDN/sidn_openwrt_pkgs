module("luci.controller.valibox.valibox", package.seeall)

function index()
    entry({"admin", "valibox"}, cbi("valibox/valibox"), _("Valibox"), 80)
end
