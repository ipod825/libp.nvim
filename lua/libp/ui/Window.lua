local M = require("libp.datatype.Class"):EXTEND()

function M:init(buffer, opts)
    opts = opts or {}
    vim.validate({
        buffer = { buffer, "t" },
        buf_id = { buffer.id, "n" },
        w = { opts.w, "t", true },
        wo = { opts.wo, "t", true },
        focus_on_open = { opts.focus_on_open, "b", true },
    })

    self.focus_on_open = opts.focus_on_open
    self.buffer = buffer
    self.w = opts.w or {}
    self.wo = opts.wo or {}
end

function M:open(fwin_cfg)
    vim.validate({ fwin_cfg = { fwin_cfg, "t" } })
    self.id = vim.api.nvim_open_win(self.buffer.id, self.focus_on_open, fwin_cfg)
    -- Call self:close in case closed by vim.api.nvim_win_close.
    vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(self.id),
        callback = function()
            self:close()
        end,
    })
    for k, v in pairs(self.w or {}) do
        vim.api.nvim_win_set_var(self.id, k, v)
    end
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
