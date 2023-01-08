--- Module: **libp.ui.Window**
--
-- Window class. Wrapping vim floating window to display @{Buffer}.
--
-- Inherits: @{Class}
-- @classmod Window
local M = require("libp.datatype.Class"):EXTEND()
local args = require("libp.args")

---
-- @field id The id of the vim window. Note that this is only set after @{open}
-- is called once.

--- Constructor.
-- @tparam Buffer buffer
-- @tparam table opts
-- @tparam[w={}] table opts.w window variables to be set. See `:help vim.w`.
-- @tparam[wo={}] table opts.wo window options to be set. See `:help vim.wo`.
-- @tparam[wo={}] boolean opts.focus_on_open Whether to focus the window when
-- it's opened the first time.
function M:init(buffer, opts)
    opts = opts or {}

    vim.validate({
        w = { opts.w, "t", true },
        wo = { opts.wo, "t", true },
        focus_on_open = { opts.focus_on_open, "b", true },
    })

    self.focus_on_open = opts.focus_on_open
    self.buffer = buffer
    self.w = opts.w or {}
    self.wo = vim.tbl_extend("keep", opts.wo or {}, { number = false, relativenumber = false })
end

--- Opens the Window with floating window configurations.
-- @tparam table fwin_cfg Passed to the third argument of `vim.api.nvim_open_win()`.
function M:open(fwin_cfg)
    vim.validate({ fwin_cfg = { fwin_cfg, "t" } })
    self.id = vim.api.nvim_open_win(self.buffer.id, self.focus_on_open, fwin_cfg)
    if vim.bo[self.buffer.id].filetype == "" then
        vim.bo[self.buffer.id].filetype = "libpwindow"
    end

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

--- Closes the Window.
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
