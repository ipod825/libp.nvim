require("plenary.async").tests.add_to_env()
local Buffer = require("libp.ui.Buffer")
local stub = require("luassert.stub")
local log = require("libp.log")

describe("Buffer", function()
	local b
	before_each(function()
		b = nil
	end)
	after_each(function()
		if b then
			vim.cmd("bwipeout " .. b.id)
		end
	end)

	describe("get_current_buffer", function()
		it("Returns the correct buffer reference", function()
			b = Buffer.get_or_new({ filename = "test_abc" })
			vim.cmd(("%d b"):format(b.id))
			assert.are.equal(b, Buffer.get_current_buffer())
			vim.cmd("new")
			assert.is_falsy(Buffer.get_current_buffer())
		end)
	end)

	describe("get_or_new", function()
		it("Returns the same buffer on second call", function()
			b = Buffer.get_or_new({ filename = "test_abc" })
			assert.are.same(b.id, Buffer.get_or_new({ filename = "test_abc" }).id)
		end)
	end)

	describe("open_or_new", function()
		it("Returns the same buffer on second call", function()
			b = Buffer.open_or_new({ filename = "test_abc", open_cmd = "edit" })
			assert.are.same(b.id, Buffer.open_or_new({ filename = "test_abc", open_cmd = "tabedit" }).id)
		end)
	end)

	describe("init", function()
		describe("buf_enter_reload", function()
			it("Does not reload on BufEnter if set to false", function()
				b = Buffer.open_or_new({
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
			end)

			it("Reloads on BufEnter if set to true", function()
				b = Buffer.open_or_new({
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
			end)
		end)

		describe("mapping", function()
			it("Takes single func", function()
				local var
				b = Buffer.open_or_new({
					filename = "test_abc",
					open_cmd = "edit",
					mappings = {
						n = {
							a = function()
								var = 1
							end,
						},
					},
				})
				assert.is_falsy(var)
				vim.api.nvim_feedkeys("a", "x", false)
				assert.are.same(1, var)
			end)

			it("Takes table with callback key", function()
				local var
				b = Buffer.open_or_new({
					filename = "test_abc",
					open_cmd = "edit",
					mappings = {
						n = {
							a = {
								callback = function()
									var = 1
								end,
							},
						},
					},
				})
				assert.is_falsy(var)
				vim.api.nvim_feedkeys("a", "x", false)
				assert.are.same(1, var)
			end)

			describe("multi_reload_strategy", function()
				it("Defaults to WAIT to wait existing reload to finish", function()
					b = Buffer.open_or_new({
						filename = "test_abc",
						open_cmd = "edit",
						mappings = {
							n = {
								a = {
									callback = function() end,
									multi_reload_strategy = Buffer.MultiReloadStrategy.WAIT,
								},
							},
						},
					})
					assert.is_falsy(b.is_reloading)
					b.is_reloading = true
					local wait_reload = stub(b, "wait_reload")

					vim.api.nvim_feedkeys("a", "x", false)
					assert.is_true(wait_reload:called())

					b.is_reloading = false
					wait_reload:revert()
				end)
				it("CANCEL cancels existing reload", function()
					b = Buffer.open_or_new({
						filename = "test_abc",
						open_cmd = "edit",
						mappings = {
							n = {
								a = {
									callback = function() end,
									multi_reload_strategy = Buffer.MultiReloadStrategy.CANCEL,
								},
							},
						},
					})
					assert.is_falsy(b.is_reloading)
					b.is_reloading = true
					local wait_reload = stub(b, "wait_reload")

					vim.api.nvim_feedkeys("a", "x", false)
					assert.is_false(wait_reload:called())
					assert.is_true(b.cancel_reload)

					b.is_reloading = false
					b.cancel_reload = false
					wait_reload:revert()
				end)

				it("IGNORE ignores existing reload", function()
					b = Buffer.open_or_new({
						filename = "test_abc",
						open_cmd = "edit",
						mappings = {
							n = {
								a = {
									callback = function() end,
									multi_reload_strategy = Buffer.MultiReloadStrategy.IGNORE,
								},
							},
						},
					})
					assert.is_falsy(b.is_reloading)
					b.is_reloading = true
					local wait_reload = stub(b, "wait_reload")

					vim.api.nvim_feedkeys("a", "x", false)
					assert.is_false(wait_reload:called())
					assert.is_falsy(b.cancel_reload)

					b.is_reloading = false
					b.cancel_reload = false
					wait_reload:revert()
				end)
			end)
		end)
	end)
end)
