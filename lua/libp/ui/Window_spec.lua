local ui = require("libp.ui")
local spy = require("luassert.spy")
local log = require("libp.log")

local win_config = {
	relative = "editor",
	width = 10,
	height = 10,
	row = 0,
	col = 0,
	zindex = 50,
	focusable = false,
	anchor = "NW",
}

describe("open", function()
	local b
	local w
	before_each(function()
		b = ui.Buffer({ content = {} })
	end)
	after_each(function()
		w:close()
	end)

	it("Defaults focus_on_open to false", function()
		w = ui.Window(b)
		local ori_win = vim.api.nvim_get_current_win()
		w:open(win_config)
		assert.are.same(ori_win, vim.api.nvim_get_current_win())
	end)

	it("Respects focus_on_open", function()
		w = ui.Window(b, { focus_on_open = true })
		w:open(win_config)
		assert.are.same(w.id, vim.api.nvim_get_current_win())
	end)

	it("Sets passed in window option", function()
		local wo = { wrap = false, cursorline = true, scrolloff = 3 }
		w = ui.Window(b, { wo = wo })
		w:open(win_config)
		for k, v in pairs(wo) do
			assert.are.same(v, vim.api.nvim_win_get_option(w.id, k))
		end
	end)

	it("Adds WinClosed autocmd calling close", function()
		w = ui.Window(b, { focus_on_open = true })
		w:open(win_config)
		local close = spy.on(w, "close")
		vim.api.nvim_win_close(w.id, false)
		assert.spy(close).was_called()
	end)
end)

describe("close", function()
	it("Calls buffer's on_wipeout if the buffer is invalid", function()
		local b = ui.Buffer({ content = {}, bo = { bufhidden = "wipe" } })
		local on_wipeout = spy.on(b, "on_wipeout")
		local w = ui.Window(b)
		w:open(win_config)
		w:close()
		assert.spy(on_wipeout).was_called()
		on_wipeout:clear()
	end)

	it("Does not calls buffer's on_wipeout if the buffer is still valid", function()
		local b = ui.Buffer({ content = {}, bo = { bufhidden = "hide" } })
		local on_wipeout = spy.on(b, "on_wipeout")
		local w = ui.Window(b)
		w:open(win_config)
		w:close()
		assert.spy(on_wipeout).was_not_called()
		on_wipeout:clear()
		vim.api.nvim_buf_delete(b.id, {})
		b:on_wipeout()
	end)
end)
