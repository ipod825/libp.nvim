local M = require("libp.datatype.Class"):EXTEND()
local Buffer = require("libp.ui.Buffer")
local Window = require("libp.ui.Window")
local functional = require("libp.functional")
local a = require("plenary.async")

function M:init(opts)
	vim.validate({
		title = { opts.title, { "s", "t" }, true },
		content = { opts.content, "t" },
		fwin_cfg = { opts.fwin_cfg, "t", true },
		cursor_offset = { opts.cursor_offset, "t", true },
		wo = { opts.wo, "table", true },
		on_select = { opts.on_select, "function", true },
	})

	local cursor_offset = opts.cursor_offset or { 0, 0 }
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	self.fwin_cfg = vim.tbl_extend("keep", opts.fwin_cfg or {}, {
		relative = "win",
		row = cursor_pos[1] + cursor_offset[1],
		col = cursor_pos[2] + cursor_offset[2],
		width = 0,
		height = 0,
		zindex = 50,
		anchor = "NW",
		border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	})

	if type(opts.title) == "string" then
		opts.title = { ("[%s]"):format(opts.title) }
	else
		opts.title = opts.title or {}
	end

	self.title = opts.title
	self.on_select = opts.on_select or functional.nop
	self.wo = opts.wo or {}

	local content = vim.deepcopy(opts.title)
	vim.list_extend(content, opts.content or {})

	self.fwin_cfg.height = #content
	for _, c in ipairs(content) do
		if #c > self.fwin_cfg.width then
			self.fwin_cfg.width = #c
		end
	end

	-- Centralize the first line
	if self.fwin_cfg.width > #content[1] then
		local diff = self.fwin_cfg.width - #content[1]
		local left_pad = math.floor(diff / 2)
		local right_pad = diff - left_pad
		content[1] = string.rep(" ", left_pad) .. content[1] .. string.rep(" ", right_pad)
	end
	self.buffer = Buffer({
		content = content,
		mappings = {
			n = {
				["<cr>"] = function()
					local text = vim.fn.getline(".")
					vim.api.nvim_win_close(0, true)
					self.on_select(text)
				end,
			},
		},
	})
end

function M:show()
	local w = Window(self.buffer, { focus_on_open = true, wo = self.wo })
	local w_id = w:open(self.fwin_cfg)
	vim.w._is_libp_menu = true
	vim.api.nvim_win_set_cursor(w_id, { #self.title + 1, 0 })
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = self.buffer.id,
		callback = function()
			if vim.fn.line(".") == #self.title then
				vim.api.nvim_win_set_cursor(w_id, { #self.title + 1, 0 })
			end
		end,
	})
end

M.select = a.wrap(function(self, callback)
	self.on_select = callback
	self:show()
end, 2)

function M.will_select_from_menu(run_before_selection)
	-- This functoin is mainly for testing purpose. When testing an async
	-- function that invokes Menu():select(), do the following:
	-- ```lua
	--   Menu.will_select_from_menu(function()
	--       -- The window is open now. Move the cursor to the item you want to
	--       -- test and it will be selected.
	--   end)
	--   function_that_open_a_menu()
	-- ```
	local timer = vim.loop.new_timer()
	local select_from_menu
	run_before_selection = run_before_selection or functional.nop

	select_from_menu = function()
		if not vim.w._is_libp_menu then
			timer:start(
				10,
				0,
				vim.schedule_wrap(function()
					select_from_menu()
				end)
			)
		else
			timer:stop()
			timer:close()
			run_before_selection()
			-- Not sure why nvim_input('<cr>') doesn't work here.
			for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do
				if m.lhs == "<CR>" then
					m.callback()
					break
				end
			end
		end
	end
	select_from_menu()
end

return M
