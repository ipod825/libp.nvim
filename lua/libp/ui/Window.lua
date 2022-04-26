local M = require("libp.datatype.Class"):EXTEND()
local log = require("libp.log")

function M:init(buffer, opts)
	opts = opts or {}
	vim.validate({
		buffer = { buffer, "t" },
		buf_id = { buffer.id, "n" },
		wo = { opts.wo, "t", true },
		focus_on_open = { opts.focus_on_open, "b", true },
	})

	self.focus_on_open = opts.focus_on_open
	self.buffer = buffer
	self.wo = opts.wo or {}
end

function M:open(fwin_cfg)
	vim.validate({ fwin_cfg = { fwin_cfg, "t" } })
	self.id = vim.api.nvim_open_win(self.buffer.id, self.focus_on_open, fwin_cfg)
	for k, v in pairs(self.wo) do
		vim.api.nvim_win_set_option(self.id, k, v)
	end
	return self.id
end

function M:close()
	if vim.api.nvim_win_is_valid(self.id) then
		vim.api.nvim_win_close(self.id, false)
		if not vim.api.nvim_buf_is_valid(self.buffer.id) then
			-- autocmd doesn't nest. Invoke BufWipeout by ourselves.
			self.buffer:on_wipeout()
		end
	end
end

return M
