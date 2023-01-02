local ui = require("libp.ui")

local win_config = {
    relative = "editor",
    width = 10,
    height = 10,
    row = 0,
    col = 0,
    zindex = 1,
    focusable = false,
    anchor = "NW",
}

describe("TitleWindow", function()
    it("Defaults with title highlight", function()
        local b = ui.Buffer()
        local t = ui.TitleWindow(b)
        t:open(win_config)
        assert.are.same("Normal:LibpTitleWindow", vim.api.nvim_win_get_option(t.id, "winhighlight"))
    end)
end)
