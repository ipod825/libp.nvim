local M = require("libp.ui.Window"):EXTEND()
local styles = require("libp.ui.progressbar_style")

function M:init(opts)
    opts = opts or {}
    vim.validate({
        desc = { opts.desc, "s", true },
        total = { opts.total, "n", true },
        style = { opts.style, "s", true },
    })
    local buffer = require("libp.ui.Buffer")()
    self.buffer = buffer
    self:SUPER():init(buffer, opts)

    self.current = 0
    self.desc = opts.desc and opts.desc or ""
    self.total = opts.total
    self.style = styles[opts.style or "pipe"]
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
            local pbar_width = math.floor((width - #self.desc) * self.current / self.total)
            content = ("%s%s"):format(self.desc, ("█"):rep(pbar_width))
        else
            content = ("%s%s"):format(self.desc, self.style[self.current % #self.style + 1])
        end
        self.buffer:set_content_and_reload({ content })
    end
end

function M:open(fwin_cfg)
    fwin_cfg = vim.tbl_extend("keep", fwin_cfg or {}, {
        relative = "editor",
        width = vim.o.columns,
        height = 1,
        row = vim.o.lines,
        col = 0,
        zindex = 1,
        focusable = false,
        anchor = "NW",
    })
    return self:SUPER():open(fwin_cfg)
end

return M
