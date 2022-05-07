require("plenary.async").tests.add_to_env()
local Buffer = require("libp.ui.Buffer")
local log = require("libp.log")

describe("get_current_buffer", function()
	it("Returns the correct buffer reference", function()
		local b = Buffer.get_or_new({ filename = "test_abc" })
		vim.cmd(("%d b"):format(b.id))
		assert.are.equal(b, Buffer.get_current_buffer())
		vim.cmd("new")
		assert.is_falsy(Buffer.get_current_buffer())
		vim.cmd("bwipeout " .. b.id)
	end)
end)

describe("get_or_new", function()
	it("Returns the same buffer on second call", function()
		local b = Buffer.get_or_new({ filename = "test_abc" })
		assert.are.same(b.id, Buffer.get_or_new({ filename = "test_abc" }).id)
		vim.cmd("bwipeout " .. b.id)
	end)
end)

describe("open_or_new", function()
	it("Returns the same buffer on second call", function()
		local b = Buffer.open_or_new({ filename = "test_abc", open_cmd = "edit" })
		assert.are.same(b.id, Buffer.open_or_new({ filename = "test_abc", open_cmd = "tabedit" }).id)
		vim.cmd("bwipeout " .. b.id)
	end)
end)

describe("init", function()
	describe("buf_enter_reload", function()
		it("Does not reload on BufEnter if set to false", function()
			local b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
				buf_enter_reload = false,
				bo = { modifiable = true },
				content = { "line 1" },
			})
			b.content = { "line 1", "line 2" }
			assert.are.same({ "line 1" }, vim.api.nvim_buf_get_lines(b.id, 0, -1, true))
			vim.api.nvim_exec_autocmds("BufEnter", { buffer = b.id })
			assert.are.same({ "line 1" }, vim.api.nvim_buf_get_lines(b.id, 0, -1, true))
			vim.cmd("bwipeout " .. b.id)
		end)

		it("Reloads on BufEnter if set to true", function()
			local b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
				buf_enter_reload = true,
				bo = { modifiable = true },
				content = { "line 1" },
			})
			b.content = { "line 1", "line 2" }
			assert.are.same({ "line 1" }, vim.api.nvim_buf_get_lines(b.id, 0, -1, true))
			vim.api.nvim_exec_autocmds("BufEnter", { buffer = b.id })
			assert.are.same({ "line 1", "line 2" }, vim.api.nvim_buf_get_lines(b.id, 0, -1, true))
			vim.cmd("bwipeout " .. b.id)
		end)
	end)
end)
