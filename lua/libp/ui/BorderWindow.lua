local M = require("libp.ui.Window"):EXTEND()

function M:init(opts)
	opts = opts or {}
	vim.validate({ title = { opts.title, "s", true }, border = { opts.border, { "s", "t" }, true } })
	opts.wo = vim.tbl_extend("keep", opts.wo or {}, {
		winhighlight = "Normal:Normal",
	})

	local buffer = require("libp.ui.Buffer")()
	self.buffer = buffer
	self:SUPER():init(buffer, opts)

	self.title = opts.title or ""
	self.border = opts.border or { "┌", "─", "┐", "│", "┘", "─", "└", "│" }
end

function M:_get_title_line(width)
	local title = #self.title > 0 and (" %s "):format(self.title) or ""
	local pad = width - #title - 2
	local left_pad = math.floor(pad / 2)
	local right_pad = pad - left_pad
	return ("%s%s%s%s%s"):format(
		self.border[1],
		self.border[2]:rep(left_pad),
		title,
		self.border[2]:rep(right_pad),
		self.border[3]
	)
end

function M:_fill_buffer_content(width, height)
	assert(height >= 3)
	local contents = {}
	table.insert(contents, self:_get_title_line(width))
	local middle_line = ("%s%s%s"):format(self.border[8], (" "):rep(width - 2), self.border[4])
	for _ = 2, height - 1 do
		table.insert(contents, middle_line)
	end
	table.insert(contents, ("%s%s%s"):format(self.border[7], (self.border[6]):rep(width - 2), self.border[5]))
	self.buffer:set_content(contents)
end

function M:open(fwin_cfg)
	vim.validate({ fwin_cfg = { fwin_cfg, "t" } })

	fwin_cfg = vim.tbl_extend("keep", {
		focusable = false,
		border = "none",
	}, fwin_cfg or {})

	self:_fill_buffer_content(fwin_cfg.width, fwin_cfg.height)
	return self:SUPER():open(fwin_cfg)
end

return M
