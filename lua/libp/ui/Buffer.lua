local M = require("libp.datatype.Class"):EXTEND()
local global = require("libp.global")("libp")
local functional = require("libp.functional")
local a = require("plenary.async")
local Job = require("libp.Job")
local log = require("libp.log")

global.buffers = global.buffers or {}

function M.get_current_buffer()
	return global.buffers[vim.api.nvim_get_current_buf()]
end

function M.get_or_new(opts)
	vim.validate({
		filename = { opts.filename, "string" },
	})

	local id = vim.fn.bufnr(opts.filename)
	return id == -1 and M(opts) or global.buffers[id]
end

function M.open_or_new(opts)
	vim.validate({
		open_cmd = { opts.open_cmd, "string" },
		filename = { opts.filename, "string" },
	})

	vim.cmd(("%s %s"):format(opts.open_cmd, opts.filename))
	opts.id = vim.api.nvim_get_current_buf()
	return global.buffers[opts.id] or M(opts)
end

function M:init(opts)
	vim.validate({
		filename = { opts.filename, "string", true },
		content = { opts.content, { "function", "table" } },
		buf_enter_reload = { opts.buf_enter_reload, "boolean", true },
		mappings = { opts.mappings, "table", true },
		b = { opts.b, "table", true },
		bo = { opts.bo, "table", true },
	})

	if opts.id then
		assert(global.buffers[opts.id] == nil, "Each vim buffer can only maps to one Buffer instance")
		self.id = opts.id
	else
		self.id = vim.api.nvim_create_buf(false, true)
		if opts.filename then
			vim.api.nvim_buf_set_name(self.id, opts.filename)
		end
	end

	global.buffers[self.id] = self
	self.content = opts.content or functional.nop
	self.mappings = opts.mappings

	self:mapfn(opts.mappings)

	-- For client to store arbitrary lua object.
	local ctx = {}
	self.ctx = setmetatable({}, { __index = ctx, __newindex = ctx })

	self.namespace = vim.api.nvim_create_namespace("")

	for k, v in pairs(opts.b or {}) do
		vim.api.nvim_buf_set_var(self.id, k, v)
	end

	local bo = vim.tbl_extend("force", {
		modifiable = false,
		bufhidden = "wipe",
		buftype = "nofile",
		undolevels = -1,
		swapfile = false,
	}, opts.bo or {})
	for k, v in pairs(bo) do
		vim.api.nvim_buf_set_option(self.id, k, v)
	end
	self.bo = bo

	-- The following autocmds might not be triggered due to nested autocmds. The
	-- handlers are invoked manually in other places when necessary.

	-- free memory on BufUnload
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = self.id,
		once = true,
		callback = self:BIND(self.on_wipeout),
	})

	-- reload on :edit
	vim.api.nvim_create_autocmd("BufReadCmd", {
		buffer = self.id,
		callback = a.void(function()
			self:reload()
		end),
	})

	-- reload on BufEnter
	if opts.buf_enter_reload then
		vim.api.nvim_create_autocmd("BufEnter", {
			buffer = self.id,
			callback = a.void(function()
				self:reload()
			end),
		})
	end

	self:reload()
end

function M:on_wipeout()
	global.buffers[self.id] = nil
end

function M:mapfn(mappings)
	if not mappings then
		return
	end
	self.mapping_handles = self.mapping_handles or {}
	for mode, mode_mappings in pairs(mappings) do
		vim.validate({
			mode = { mode, "string" },
			mode_mappings = { mode_mappings, "table" },
		})
		self.mapping_handles[mode] = self.mapping_handles[mode] or {}
		for key, fn in pairs(mode_mappings) do
			self:add_key_map(mode, key, fn)
		end
	end
end

function M:add_key_map(mode, key, fn)
	vim.validate({
		mode = { mode, "string" },
		key = { key, "string" },
		fn = { fn, { "function", "table" } },
	})

	local modify_buffer = true
	if type(fn) == "table" then
		modify_buffer = fn.modify_buffer or true
		fn = fn.callback
	end

	local prefix = (mode == "v") and ":<c-u>" or "<cmd>"
	self.mapping_handles[mode] = self.mapping_handles[mode] or {}
	self.mapping_handles[mode][key] = function()
		if self.is_reloading and modify_buffer then
			-- Cancel reload since we will reload after calling fn.
			self.cancel_reload = true
		end
		fn()
	end
	vim.api.nvim_buf_set_keymap(
		self.id,
		mode,
		key,
		('%slua require("libp.ui.Buffer").execut_mapping("%s", "%s")<cr>'):format(prefix, mode, key:gsub("^<", "<lt>")),
		{}
	)

	-- todo: this does not work for visual mode for getting visual selected rows for now.
	-- vim.keymap.set(
	-- 	mode,
	-- 	key,
	-- 	a.void(function()
	-- 		if self.is_reloading and modify_buffer then
	-- 			-- Cancel reload since we will reload after calling fn.
	-- 			self.cancel_reload = true
	-- 		end
	-- 		fn()
	-- 	end),
	-- 	{ buffer = self.id }
	-- )
end

function M.execut_mapping(mode, key)
	local b = global.buffers[vim.api.nvim_get_current_buf()]
	key = key:gsub("<lt>", "^<")
	a.void(function()
		b.mapping_handles[mode][key]()
	end)()
end

function M:mark(data, max_num_data)
	self.ctx.mark = self.ctx.mark or {}
	if #self.ctx.mark == max_num_data then
		self.ctx.mark = {}
	end
	local index = (#self.ctx.mark % max_num_data) + 1
	self.ctx.mark[index] = vim.tbl_extend("error", data, { linenr = vim.fn.line(".") - 1 })

	vim.api.nvim_buf_clear_namespace(self.id, self.namespace, 1, -1)
	for i, d in ipairs(self.ctx.mark) do
		vim.api.nvim_buf_add_highlight(self.id, self.namespace, "LibpBufferMark" .. i, d.linenr, 1, -1)
	end
end

function M:save_edit()
	self.ctx.edit.update(self.ctx.edit.ori_items, self.ctx.edit.get_items())
	self.ctx.edit = nil
	vim.bo.buftype = "nofile"
	vim.bo.modifiable = self.bo.modifiable
	vim.bo.undolevels = self.bo.undolevels
	self:mapfn(self.mappings)
	self:reload()
end

function M:edit(opts)
	vim.validate({
		get_items = { opts.get_items, "function" },
		update = { opts.update, "function" },
		fill_lines = { opts.fill_lines, "function", true },
	})
	self.ctx.edit = vim.tbl_extend("error", opts, { ori_items = opts.get_items() })
	vim.bo.buftype = "acwrite"
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = self.id,
		once = true,
		callback = a.void(function()
			global.buffers[self.id]:save_edit()
		end),
	})
	self:unmapfn(self.mappings)
	vim.bo.undolevels = -1
	vim.bo.modifiable = true
	if opts.fill_lines then
		opts.fill_lines()
	end
	vim.bo.undolevels = (self.bo.undolevels > 0) and self.bo.undolevels or vim.api.nvim_get_option("undolevels")
end

function M:unmapfn(mappings)
	for mode, mode_mappings in pairs(mappings) do
		vim.validate({
			mode = { mode, "string" },
			mode_mappings = { mode_mappings, "table" },
		})
		for key, _ in pairs(mode_mappings) do
			vim.keymap.del(mode, key, { buffer = self.id })
		end
	end
end

function M:clear()
	vim.api.nvim_buf_set_option(self.id, "undolevels", -1)
	vim.api.nvim_buf_set_option(self.id, "modifiable", true)
	vim.api.nvim_buf_set_lines(self.id, 0, -1, false, {})
	vim.api.nvim_buf_set_option(self.id, "modifiable", self.bo.modifiable)
	vim.api.nvim_buf_set_option(self.id, "undolevels", self.bo.undolevels)
end

function M:append(lines, beg)
	vim.api.nvim_buf_set_option(self.id, "undolevels", -1)
	vim.api.nvim_buf_set_option(self.id, "modifiable", true)

	vim.api.nvim_buf_set_lines(self.id, beg, -1, false, lines)

	vim.api.nvim_buf_set_option(self.id, "modifiable", self.bo.modifiable)
	vim.api.nvim_buf_set_option(self.id, "undolevels", self.bo.undolevels)
	return beg + #lines
end

function M:delay_reload()
	local job_done = a.control.Condvar.new()
	a.void(function()
		job_done:wait()
		a.util.scheduler()
		self:reload()
	end)()

	return function()
		job_done:notify_one()
	end
end

function M:set_content(content)
	vim.validate({ content = { content, { "function", "table" } } })
	self.content = content
	self:reload()
end

function M:register_reload_notification()
	-- This functoin is mainly for testing purpose. When the reload function is
	-- not invoked by the main testing coroutine (a.void) but by a (autocmd)
	-- callback, the main testing coroutine won't block until reload finishes as
	-- reload is invoked by another coroutine. This function returns a mutex so
	-- that the other coroutine can notify the main testing coroutine when it
	-- completes the reload function.
	self.reload_done = a.control.Condvar.new()
	return self.reload_done
end

function M:reload()
	if self.bo.filetype then
		vim.api.nvim_buf_set_option(self.id, "filetype", self.bo.filetype)
	end
	if type(self.content) == "table" then
		vim.api.nvim_buf_set_option(self.id, "modifiable", true)
		vim.api.nvim_buf_set_lines(self.id, 0, -1, false, self.content)
		vim.api.nvim_buf_set_option(self.id, "modifiable", self.bo.modifiable)
		return
	end

	if self.is_reloading then
		return
	end

	self.is_reloading = true
	-- Clear the marks so that we don't hit into invisible marks.
	self.ctx.mark = nil
	self.cancel_reload = false

	local ori_win, ori_cursor
	local ori_st = vim.o.statusline
	if self.id == vim.api.nvim_get_current_buf() then
		ori_win = vim.api.nvim_get_current_win()
		ori_cursor = vim.api.nvim_win_get_cursor(ori_win)
		ori_st = vim.o.statusline
	end

	self:clear()

	local count = 1
	local beg = 0
	local job
	job = Job({
		cmds = self.content(),
		on_stdout = function(lines)
			if not vim.api.nvim_buf_is_valid(self.id) or self.cancel_reload then
				job:kill()
				return
			end

			beg = self:append(lines, beg)
			-- We only restore cursor once. For content that can be drawn in one
			-- shot, reload should finish before any new user interaction.
			-- Restoring the view thus compensate the cursor move due to clear.
			-- For content that needs to be drawn in multiple run, restoring the
			-- cursor after every append just makes user can't do anything.
			if ori_cursor and vim.api.nvim_win_is_valid(ori_win) then
				vim.api.nvim_win_set_cursor(
					ori_win,
					{ math.min(vim.api.nvim_buf_line_count(self.id), ori_cursor[1]), ori_cursor[2] }
				)
				ori_cursor = nil
			end

			if ori_win == vim.api.nvim_get_current_win() then
				vim.wo.statusline = " Loading " .. ("."):rep(count)
				count = count % 6 + 1
			end
		end,
	})

	job:start()

	self.is_reloading = false
	if ori_win and vim.api.nvim_win_is_valid(ori_win) then
		vim.api.nvim_win_set_option(ori_win, "statusline", ori_st)
	end

	if self.reload_done ~= nil then
		self.reload_done:notify_one()
	end
end

return M
