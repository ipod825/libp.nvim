local ui = require("libp.ui")
local spy = require("luassert.spy")

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

describe("init", function()
    it("Defaults with Normal highlight", function()
        local b = ui.Buffer()
        local bw = ui.BorderedWindow(b)
        bw:open(win_config)
        assert.are.same("Normal:Normal", vim.api.nvim_win_get_option(bw.id, "winhighlight"))
    end)

    it("Passes arguments to inner window", function()
        local b = ui.Buffer()
        local bw = ui.BorderedWindow(b, { wo = { winhighlight = "Normal:InSearch" } })
        bw:open(win_config)
        assert.are.same("Normal:InSearch", vim.api.nvim_win_get_option(bw.id, "winhighlight"))
    end)

    it("Passes arguments to border window", function()
        local b = ui.Buffer()
        local bw = ui.BorderedWindow(b, {}, { title = "Title" })
        local box_border = bw:get_border_window()
        assert.is_true(box_border:IS(ui.BorderWindow))
        assert.are.same("Title", box_border.title)
    end)
end)

describe("open", function()
    it("Calls border window's open", function()
        local b = ui.Buffer()
        local bw = ui.BorderedWindow(b)
        local box_border = bw:get_border_window()

        local border_open = spy.on(box_border, "open")
        bw:open(win_config)
        assert.spy(border_open).was_called()
    end)
end)

describe("close", function()
    it("Closes border window", function()
        local b = ui.Buffer()
        local bw = ui.BorderedWindow(b)

        bw:open(win_config)
        vim.api.nvim_win_close(bw.id, false)

        assert.is_false(vim.api.nvim_win_is_valid(bw.id))
        assert.is_false(vim.api.nvim_win_is_valid(bw:get_border_window().id))
    end)
end)
