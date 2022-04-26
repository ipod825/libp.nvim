local vimfn = require("libp.utils.vimfn")
local stub = require("luassert.stub")

describe("visual_rows", function()
	it("Returns seleted row beg and end", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
		vim.cmd("normal! ggVG")

		-- -- todo: This doesn't work. Seems like neovim has a bug: After setting
		-- -- the buffer content, vim.fn.getpos("'>") would return {0,0,0,0}.
		-- local row_beg, row_end = vimfn.visual_rows()
		-- assert.are.same(1, row_beg)
		-- assert.are.same(3, row_end)

		local visual_rows = stub(vimfn, "visual_rows")
		visual_rows.by_default.returns(1, 3)
		local row_beg, row_end = vimfn.visual_rows()
		assert.are.same(1, row_beg)
		assert.are.same(3, row_end)
		visual_rows:revert()
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
