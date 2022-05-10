local BoxBorder = require("libp.ui.BoxBorder")
local log = require("libp.log")

describe("open", function()
	it("Sets the border content", function()
		local b = BoxBorder({ title = "Title", border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" } })

		local height = 5
		local width = 40
		b:open({
			relative = "editor",
			width = width,
			height = height,
			row = 10,
			col = 20,
			zindex = 50,
			anchor = "NW",
		})
		local contents = vim.api.nvim_buf_get_lines(b.buffer.id, 0, -1, true)
		-- lua pattern does not work with unicode.
		assert.is_true(vim.startswith(contents[1], "┌─"))
		assert.is_true(vim.endswith(contents[1], "─┐"))
		assert.is_truthy(contents[1]:match(" Title "))

		local middle_line = ("│%s│"):format((" "):rep(width - 2))
		for i = 2, height - 1 do
			assert.are.same(contents[i], middle_line)
		end

		assert.is_true(vim.startswith(contents[height], "└─"))
		assert.is_true(vim.endswith(contents[height], "─┘"))
		assert.is_falsy(contents[height]:match(" "))
	end)
end)
