--- Module: **libp.ui.BorderWindow**
--
-- BorderWindow class. A ui bounding other @{Window}s for decoration purpose.
--
-- Inherits: @{Window}
-- @classmod BorderWindow
local M = require("libp.ui.Window"):EXTEND()
local vimfn = require("libp.utils.vimfn")

--- Constructor
function M:init(opts)
    opts = opts or {}
    vim.validate({
        title = { opts.title, "s", true },
        highlight = { opts.highlight, "s", true },
        title_highlight = { opts.title_highlight, "s", true },
        border = { opts.border, { "s", "t" }, true },
    })
    opts.highlight = opts.highlight or "NonText"
    opts.wo = vim.tbl_extend("keep", opts.wo or { number = false, wrap = false }, {
        winhighlight = "Normal:" .. opts.highlight,
    })

    local buffer = require("libp.ui.Buffer")()
    self.buffer = buffer
    self:SUPER():init(buffer, opts)

    self.title = opts.title or ""
    self.title_highlight = opts.title_highlight or "Normal"
    self.border = opts.border or { "┌", "─", "┐", "│", "┘", "─", "└", "│" }
    self.left_offset = (self.border[1] or self.border[7] or self.border[8]) and 1 or 0
    self.top_offset = (self.border[1] or self.border[2] or self.border[3]) and 1 or 0
    self.right_offset = (self.border[3] or self.border[4] or self.border[5]) and 1 or 0
    self.bottom_offset = (self.border[5] or self.border[6] or self.border[7]) and 1 or 0
end

function M:_get_title_line(width)
    local title = #self.title > 0 and (" %s "):format(self.title) or ""
    local pad = width - #title - self.left_offset - self.right_offset
    local left_pad = math.floor(pad / 2)
    local right_pad = pad - left_pad
    return ("%s%s%s%s%s"):format(
        self.border[1] or "",
        self.border[2]:rep(left_pad),
        title,
        self.border[2]:rep(right_pad),
        self.border[3] or ""
    )
end

function M:_fill_buffer_content(width, height)
    assert(height >= 3)
    local contents = {}
    if self.top_offset ~= 0 then
        table.insert(contents, self:_get_title_line(width))
    end
    local middle_line = ("%s%s%s"):format(
        self.border[8] or "",
        (" "):rep(width - self.left_offset - self.right_offset),
        self.border[4] or ""
    )
    for _ = self.top_offset + 1, height - self.bottom_offset do
        table.insert(contents, middle_line)
    end
    if self.bottom_offset ~= 0 then
        table.insert(
            contents,
            ("%s%s%s"):format(
                self.border[7] or "",
                (self.border[6]):rep(width - self.left_offset - self.right_offset),
                self.border[5] or ""
            )
        )
    end
    self.buffer:set_content_and_reload(contents)
    if self.top_offset ~= 0 and #self.title > 0 then
        local title_beg, title_end = vimfn.buf_get_line(0, self.buffer.id):find(self.title)
        self.buffer:set_hl({
            hl_group = self.title_highlight,
            line = 0,
            col_start = title_beg - 1,
            col_end = title_end - 1,
        })
    end
end

function M:open(fwin_cfg)
    vim.validate({ fwin_cfg = { fwin_cfg, "t" } })

    fwin_cfg = vim.tbl_extend("keep", {
        focusable = false,
        border = "none",
    }, fwin_cfg)

    self:_fill_buffer_content(fwin_cfg.width, fwin_cfg.height)
    return self:SUPER():open(fwin_cfg)
end

return M
