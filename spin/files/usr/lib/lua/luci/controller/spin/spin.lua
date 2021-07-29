module("luci.controller.spin.spin", package.seeall)

function index()
    entry({"admin", "spin"}, cbi("spin/spin"), _("SPIN"), 80)
end
