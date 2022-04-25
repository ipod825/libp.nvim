local M = require("libp.ui.Window"):EXTEND()
local log = require("libp.log")

function M:open(fwin_cfg)
	local id = self:SUPER():open(fwin_cfg)
	local ori_win = vim.api.nvim_get_current_win()

	if id ~= ori_win then
		local ori_eventignore = vim.o.eventignore
		vim.o.eventignore = "all"
		vim.api.nvim_set_current_win(id)
		vim.cmd("diffthis")
		vim.api.nvim_set_current_win(ori_win)
		vim.o.eventignore = ori_eventignore
	else
		vim.cmd("diffthis")
		vim.cmd("normal! zX")
	end
	return id
end

return M
