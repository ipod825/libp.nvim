require("plenary.async").tests.add_to_env()
local Buffer = require("libp.ui.Buffer")
local stub = require("luassert.stub")
local spy = require("luassert.spy")
local functional = require("libp.functional")
local log = require("libp.log")

describe("Buffer", function()
	local b
	before_each(function()
		b = nil
	end)
	after_each(function()
		if b then
			vim.cmd("bwipeout! " .. b.id)
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
		describe("builtin autocmds", function()
			describe("BufReadCmd", function()
				it("Reloads buffer on BufReadCmd", function()
					b = Buffer.open_or_new({
						filename = "test_abc",
						open_cmd = "edit",
					})
					local reload = spy.on(b, "reload")

					vim.cmd("edit")

					assert.spy(reload).was_called()
					reload:clear()
				end)
			end)

			describe("BufWipeout", function()
				it("Calls on_wipeout handler", function()
					b = Buffer.open_or_new({
						filename = "test_abc",
						open_cmd = "edit",
					})
					local on_wipeout = spy.on(b, "on_wipeout")

					vim.api.nvim_exec_autocmds("BufWipeout", { buffer = b.id })

					assert.spy(on_wipeout).was_called()
					on_wipeout:clear()
				end)
			end)

			describe("BufEnterReload", function()
				it("Does not reload on BufEnter if set to false", function()
					b = Buffer.open_or_new({
						filename = "test_abc",
						open_cmd = "edit",
						buf_enter_reload = false,
					})
					local reload = spy.on(b, "reload")

					vim.api.nvim_exec_autocmds("BufEnter", { buffer = b.id })

					assert.spy(reload).was_not_called()
					reload:clear()
				end)

				it("Reloads on BufEnter if set to true", function()
					b = Buffer.open_or_new({
						filename = "test_abc",
						open_cmd = "edit",
						buf_enter_reload = true,
					})
					local reload = spy.on(b, "reload")

					vim.api.nvim_exec_autocmds("BufEnter", { buffer = b.id })

					assert.spy(reload).was_called()
					reload:clear()
				end)
			end)
		end)

		describe("mappings", function()
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

		describe("buffer options", function()
			it("Defaults to", function()
				b = Buffer.open_or_new({
					filename = "test_abc",
					open_cmd = "edit",
				})
				assert.are.same(false, vim.bo.modifiable)
				assert.are.same("wipe", vim.bo.bufhidden)
				assert.are.same("nofile", vim.bo.buftype)
				assert.are.same(false, vim.bo.swapfile)
			end)

			it("Respects options", function()
				b = Buffer.open_or_new({
					filename = "test_abc",
					open_cmd = "edit",
					bo = { bufhidden = "delete" },
				})
				assert.are.same("delete", vim.bo.bufhidden)
			end)
		end)
	end)

	describe("set_content", function()
		it("Sets array content", function()
			b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
			})
			local content = { "a", "b", "c" }
			assert.are_not.same(content, vim.api.nvim_buf_get_lines(b.id, 0, -1, true))
			b:set_content(content)
			assert.are.same(content, vim.api.nvim_buf_get_lines(b.id, 0, -1, true))
		end)
		a.it("Sets function content", function()
			b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
			})
			b:set_content(function()
				return { "echo", "hello" }
			end)
			assert.are.same({ "hello" }, vim.api.nvim_buf_get_lines(b.id, 0, -1, true))
		end)
	end)

	describe("edit", function()
		it("Deafulats to global undolevels", function()
			b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
			})
			b:edit({ get_items = functional.nop, update = functional.nop })
			assert.are.same(vim.go.undolevels, vim.api.nvim_buf_get_option(b.id, "undolevels"))
			vim.cmd("write")
			assert.are.same(-1, vim.api.nvim_buf_get_option(b.id, "undolevels"))
		end)

		it("Respects undolevels in init", function()
			local ori_undolevel = 3
			b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
				bo = { undolevels = ori_undolevel },
			})
			b:edit({ get_items = functional.nop, update = functional.nop })
			assert.are.same(ori_undolevel, vim.api.nvim_buf_get_option(b.id, "undolevels"))
			vim.cmd("write")
			assert.are.same(ori_undolevel, vim.api.nvim_buf_get_option(b.id, "undolevels"))
		end)

		it("Sets up buftype and modifiable", function()
			b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
			})
			b:edit({ get_items = functional.nop, update = functional.nop })
			assert.are.same("acwrite", vim.api.nvim_buf_get_option(b.id, "buftype"))
			assert.are.same(true, vim.api.nvim_buf_get_option(b.id, "modifiable"))
			vim.cmd("write")
			assert.are.same("nofile", vim.api.nvim_buf_get_option(b.id, "buftype"))
			assert.are.same(false, vim.api.nvim_buf_get_option(b.id, "modifiable"))
		end)

		it("Respects customized filetypes and modifiable", function()
			b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
				bo = { buftype = "nowrite", modifiable = true },
			})
			b:edit({ get_items = functional.nop, update = functional.nop })
			assert.are.same("acwrite", vim.api.nvim_buf_get_option(b.id, "buftype"))
			assert.are.same(true, vim.api.nvim_buf_get_option(b.id, "modifiable"))
			vim.cmd("write")
			assert.are.same("nowrite", vim.api.nvim_buf_get_option(b.id, "buftype"))
			assert.are.same(true, vim.api.nvim_buf_get_option(b.id, "modifiable"))
		end)

		it("Unmaps mappings", function()
			b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
				mappings = { n = { a = functional.nop } },
			})
			b:edit({ get_items = functional.nop, update = functional.nop })
			assert.are.same(0, #vim.api.nvim_buf_get_keymap(b.id, "n"))
			vim.cmd("write")
			assert.are.same(1, #vim.api.nvim_buf_get_keymap(b.id, "n"))
		end)

		it("Optionally modifies buffer content", function()
			b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
			})
			b:edit({
				get_items = functional.nop,
				update = functional.nop,
				fill_lines = function()
					vim.api.nvim_buf_set_lines(b.id, 0, -1, true, { "a", "b" })
				end,
			})
			assert.are.same({ "a", "b" }, vim.api.nvim_buf_get_lines(b.id, 0, -1, true))
		end)

		it("Saves edit on write", function()
			local final_items = {}
			local update = function(o, n)
				final_items = { o[1], n[1] }
			end
			local counter = 1
			local ori_items = { "ori_items" }
			local new_items = { "new_items" }
			local get_items = function()
				if counter == 1 then
					counter = counter + 1
					return ori_items
				else
					return new_items
				end
			end

			b = Buffer.open_or_new({
				filename = "test_abc",
				open_cmd = "edit",
			})
			local reload = spy.on(b, "reload")
			b:edit({
				get_items = get_items,
				update = update,
			})
			vim.cmd("write")
			assert.are.same({ "ori_items", "new_items" }, final_items)
			assert.spy(reload).was_called()
			reload:clear()
		end)
	end)
end)
