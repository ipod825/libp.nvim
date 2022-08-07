local M = require("libp.ui.Menu"):EXTEND()

function M:init(opts)
    vim.validate({
        title = { opts.title, "s", true },
        content = { opts.content, { "t", "s" } },
        fwin_cfg = { opts.fwin_cfg, "t", true },
        wo = { opts.wo, "t", true },
    })

    opts.title = opts.title or "!"
    if type(opts.content) == "string" then
        opts.content = { opts.content }
    end

    self:SUPER():init(opts)

    self.fwin_cfg.row = math.floor((vim.o.lines - self.fwin_cfg.height) / 2) - 8
    self.fwin_cfg.col = math.floor((vim.o.columns - self.fwin_cfg.width) / 2)
end

return M
