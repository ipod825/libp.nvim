local M = require("libp.datatype.Class"):EXTEND()
local global = require("libp.global")("libp")
local a = require("plenary.async")
local Job = require("libp.Job")
local log = require("libp.log")

global.buffers = global.buffers or {}

function M.get_current_buffer()
	return global.buffers[vim.api.nvim_get_current_buf()]
end

function M.get_or_new(opts)
	vim.validate({
		filename = { opts.filename, "s" },
	})

	local id = vim.fn.bufnr(opts.filename)
	return id == -1 and M(opts) or global.buffers[id]
end

function M.open_or_new(opts)
	vim.validate({
		open_cmd = { opts.open_cmd, "s" },
		filename = { opts.filename, "s" },
	})

	vim.cmd(("%s %s"):format(opts.open_cmd, opts.filename))
	opts.id = vim.api.nvim_get_current_buf()
	return global.buffers[opts.id] or M(opts)
end

function M:init(opts)
	vim.validate({
		filename = { opts.filename, "s", true },
		content = { opts.content, { "f", "t" }, true },
		buf_enter_reload = { opts.buf_enter_reload, "b", true },
		mappings = { opts.mappings, "t", true },
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
	self.content = opts.content or {}
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
		callback = function()
			self:on_wipeout()
		end,
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

	self.reload_done = a.control.Condvar.new()
	self:reload()
end

function M:on_wipeout()
	global.buffers[self.id] = nil
end

function M:mapfn(mappings)
	if not mappings then
		return
	end
	for mode, mode_mappings in pairs(mappings) do
		vim.validate({
			mode = { mode, "s" },
			mode_mappings = { mode_mappings, "t" },
		})
		for key, fn in pairs(mode_mappings) do
			self:add_key_map(mode, key, fn)
		end
	end
end

M.MultiReloadStrategy = {
	-- Wait for any existing reload to finish. The caller might be blocked and
	-- is free to do anything after unblock. This is the default behavior and
	-- should be good in most cases. Only if the Buffer contains more than 10k
	-- lines should we try to reduce user waiting time with the following
	-- options.
	WAIT = 1,
	-- Cancel any existing reload. The caller will never be blocked but is
	-- expected to trigger another reload so that the buffer content will still
	-- be up-to-date.
	CANCEL = 2,
	-- Ignore any existing reload. The caller will never be blocked and is
	-- expected to not trigger any reload.
	IGNORE = 3,
}

function M:add_key_map(mode, key, fn)
	vim.validate({
		mode = { mode, "s" },
		key = { key, "s" },
		fn = { fn, { "f", "t" } },
	})

	local multi_reload = M.MultiReloadStrategy.WAIT
	if type(fn) == "table" then
		multi_reload = fn.multi_reload_strategy
		fn = fn.callback
	end

	vim.keymap.set(
		mode,
		key,
		a.void(function()
			if self.is_reloading then
				if multi_reload == M.MultiReloadStrategy.WAIT then
					self:wait_reload()
				elseif multi_reload == M.MultiReloadStrategy.CANCEL then
					self.cancel_reload = true
				end
			end
			fn()
		end),
		{ buffer = self.id }
	)
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
		get_items = { opts.get_items, "f" },
		update = { opts.update, "f" },
		fill_lines = { opts.fill_lines, "f", true },
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
			mode = { mode, "s" },
			mode_mappings = { mode_mappings, "t" },
		})
		for key, _ in pairs(mode_mappings) do
			vim.keymap.del(mode, key, { buffer = self.id })
		end
	end
end

function M:_clear()
	vim.api.nvim_buf_set_option(self.id, "undolevels", -1)
	vim.api.nvim_buf_set_option(self.id, "modifiable", true)
	vim.api.nvim_buf_set_lines(self.id, 0, -1, false, {})
	vim.api.nvim_buf_set_option(self.id, "modifiable", self.bo.modifiable)
	vim.api.nvim_buf_set_option(self.id, "undolevels", self.bo.undolevels)
end

function M:_append(lines, beg)
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
	vim.validate({ content = { content, { "f", "t" } } })
	self.content = content
	self:reload()
end

function M:wait_reload()
	self.reload_done:wait()
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

	self:_clear()

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

			beg = self:_append(lines, beg)
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

	self.reload_done:notify_all()
end

return M
