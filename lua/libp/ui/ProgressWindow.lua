local M = require("libp.ui.Window"):EXTEND()
local styles = require("libp.ui.pbarstyle")
local log = require("libp.log")

function M:init(opts)
	opts = opts or {}
	vim.validate({
		text = { opts.text, "s", true },
		total = { opts.total, "n", true },
		style = { opts.style, "s", true },
	})
	local buffer = require("libp.ui.Buffer")()
	self.buffer = buffer
	self:SUPER():init(buffer, opts)

	self.current = 0
	self.text = opts.text and opts.text or ""
	self.total = opts.total
	self.style = styles[opts.style or "pipe"]
	self:tick(0)
end

function M:tick(step)
	step = step or 1
	self.current = self.current + step
	if self.current == self.total then
		self:close()
		return
	end

	if self.id and vim.api.nvim_win_is_valid(self.id) then
		local content
		if self.total then
			local width = vim.api.nvim_win_get_width(self.id)
			local text = #self.text > 0 and self.text .. ":" or ""
			local pbar_width = math.floor((width - #text) * self.current / self.total)
			content = ("%s%s"):format(text, ("█"):rep(pbar_width))
		else
			local text = #self.text > 0 and self.text or "Loading"
			content = ("%s %s"):format(text, self.style[self.current % #self.style + 1])
		end
		self.buffer:set_content({ content })
	end
end

function M:open(fwin_cfg)
	fwin_cfg = vim.tbl_extend("keep", fwin_cfg or {}, {
		relative = "editor",
		width = vim.o.columns,
		height = 1,
		row = vim.o.lines,
		col = 0,
		zindex = 50,
		focusable = false,
		anchor = "NW",
	})
	self:SUPER():open(fwin_cfg)
end

return M
