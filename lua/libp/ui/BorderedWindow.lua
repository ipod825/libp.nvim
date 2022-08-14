local M = require("libp.ui.Window"):EXTEND()
local BorderWindow = require("libp.ui.BorderWindow")

function M:init(buffer, opts, border_opts)
    vim.validate({
        buffer = { buffer, "t" },
        opts = { opts, "t", true },
        border_opts = { border_opts, "t", true },
    })

    opts = opts or {}
    opts.wo = vim.tbl_extend("keep", opts.wo or {}, {
        winhighlight = "Normal:Normal",
    })

    self:SUPER():init(buffer, opts)
    self.box_border = BorderWindow(border_opts)
end

function M:get_border_window()
    return self.box_border
end

function M:get_inner_window()
    return self
end

function M:open(fwin_cfg)
    self.box_border:open(fwin_cfg)
    local inner_fwin_cfg = vim.deepcopy(fwin_cfg)

    inner_fwin_cfg.row = inner_fwin_cfg.row + self.box_border.top_offset
    inner_fwin_cfg.col = inner_fwin_cfg.col + self.box_border.left_offset
    inner_fwin_cfg.height = inner_fwin_cfg.height - self.box_border.top_offset - self.box_border.bottom_offset
    inner_fwin_cfg.width = inner_fwin_cfg.width - self.box_border.left_offset - self.box_border.right_offset
    inner_fwin_cfg.zindex = inner_fwin_cfg.zindex + 1

    return self:SUPER():open(inner_fwin_cfg)
end

function M:close()
    self.box_border:close()
    self:SUPER():close()
end

return M
