local vimfn = require("libp.utils.vimfn")

describe("visual_rows", function()
	it("Returns current row in normal mode", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
		vim.cmd("normal! j")

		local row_beg, row_end = vimfn.visual_rows()
		assert.are.same(2, row_beg)
		assert.are.same(2, row_end)
	end)
	it("Returns seleted row beg and end", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
		vim.cmd("normal! ggVG")

		local row_beg, row_end = vimfn.visual_rows()
		assert.are.same(1, row_beg)
		assert.are.same(3, row_end)
	end)
end)

describe("selected_rows", function()
	it("Selects the specified rows", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })

		vimfn.visual_select_rows(2, 3)
		local row_beg, row_end = vimfn.visual_rows()
		assert.are.same(2, row_beg)
		assert.are.same(3, row_end)

		vimfn.visual_select_rows(1, 3)
		row_beg, row_end = vimfn.visual_rows()

		assert.are.same(1, row_beg)
		assert.are.same(3, row_end)
	end)
end)

describe("setrow", function()
	it("Sets the row", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
		vimfn.setrow(1)
		assert.are.same(1, vim.api.nvim_win_get_cursor(0)[1])
		vimfn.setrow(2)
		assert.are.same(2, vim.api.nvim_win_get_cursor(0)[1])
	end)
end)

describe("first_visible_line", function()
	it("Returns seleted row beg and end", function()
		local content = {}
		for i = 1, 2 * vim.o.lines do
			table.insert(content, tostring(i))
		end
		vim.api.nvim_buf_set_lines(0, 0, -1, false, content)

		assert.are.same(1, vimfn.first_visible_line())
		assert.are.same(vim.o.lines - 2, vimfn.last_visible_line())

		vim.cmd("normal! ")
		assert.are.same(2, vimfn.first_visible_line())
		assert.are.same(vim.o.lines - 1, vimfn.last_visible_line())
	end)
end)

describe("all_rows", function()
	it("Returns 1, line('$')", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })

		local row_beg, row_end = vimfn.all_rows()
		assert.are.same(1, row_beg)
		assert.are.same(3, row_end)
	end)
end)

describe("current_row", function()
	it("Returns the current row", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
		vimfn.setrow(1)
		assert.are.same(1, vimfn.current_row())
		vimfn.setrow(2)
		assert.are.same(2, vimfn.current_row())
		vimfn.setrow(3)
		assert.are.same(3, vimfn.current_row())
	end)
end)

describe("editable_width", function()
	it("Returns width excluding gutter", function()
		vim.o.number = false
		local ori_winwidth = vim.api.nvim_win_get_width(0)
		assert.are.same(ori_winwidth, vimfn.editable_width(0))
		vim.o.number = true
		assert.are.same(ori_winwidth - 4, vimfn.editable_width(0))
		vim.o.number = false
	end)
end)
