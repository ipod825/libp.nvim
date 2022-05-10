local Menu = require("libp.ui.Menu")

local fwin_cfg = {
	relative = "cursor",
	row = 10,
	col = 10,
}

describe("init", function()
	describe("width/height", function()
		it("Works with no title", function()
			local m = Menu({ content = { "a" } })
			m:show()
			assert.are.same(1, vim.api.nvim_win_get_width(m:get_inner_window().id))
			assert.are.same(3, vim.api.nvim_win_get_width(m:get_border_window().id))
			assert.are.same(1, vim.api.nvim_win_get_height(m:get_inner_window().id))
			assert.are.same(3, vim.api.nvim_win_get_height(m:get_border_window().id))

			m = Menu({ content = { "ab", "c" } })
			m:show()
			assert.are.same(2, vim.api.nvim_win_get_width(m:get_inner_window().id))
			assert.are.same(4, vim.api.nvim_win_get_width(m:get_border_window().id))
			assert.are.same(2, vim.api.nvim_win_get_height(m:get_inner_window().id))
			assert.are.same(4, vim.api.nvim_win_get_height(m:get_border_window().id))
		end)

		it("Works when title dominates", function()
			local m = Menu({ title = "Ti", content = { "a" } })
			m:show()
			assert.are.same(6, vim.api.nvim_win_get_width(m:get_inner_window().id))
			assert.are.same(8, vim.api.nvim_win_get_width(m:get_border_window().id))
			assert.are.same(1, vim.api.nvim_win_get_height(m:get_inner_window().id))
			assert.are.same(3, vim.api.nvim_win_get_height(m:get_border_window().id))

			local m = Menu({ title = "Title", content = { "a", "bc" } })
			m:show()
			assert.are.same(9, vim.api.nvim_win_get_width(m:get_inner_window().id))
			assert.are.same(11, vim.api.nvim_win_get_width(m:get_border_window().id))
			assert.are.same(2, vim.api.nvim_win_get_height(m:get_inner_window().id))
			assert.are.same(4, vim.api.nvim_win_get_height(m:get_border_window().id))
		end)
	end)

	describe("cursor_offset", function() end)
end)
