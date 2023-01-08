--- Module: **libp.ui.DiffWindow**
--
-- DiffWindow class. A specialized @{Window} that is intentional for showing diff. The following example defines a @{TitleWindow} and two @{DiffWindow} windows below it.
--
--     local ui = require("libp.ui")
--     local grid = ui.Grid()
--     grid:add_row({ height = 1 }):fill_window(ui.TitleWindow(ui.Buffer({
--         content = { "Left Align", "Center", "Right Align" },
--     })))
--     grid:add_row({ focusable = true }):vfill_windows({
--         ui.DiffWindow(ui.FilePreviewBuffer('file1')),
--         ui.DiffWindow(ui.FilePreviewBuffer('file2'), { focus_on_open = true }),
--     })
--     grid:show()
--
-- Inherits: @{Window}
-- @classmod DiffWindow
local M = require("libp.ui.Window"):EXTEND()

--- Constructor.
-- @tparam Buffer buffer
-- @tparam table opts see @{Window:init}. The following arguments have default values:
-- @tparam[opt] table opts.wo
function M:init(buffer, opts)
    opts = opts or {}
    opts.wo = vim.tbl_extend("force", opts.wo or {}, {
        winhighlight = "Normal:Normal",
    })
    self:SUPER():init(buffer, opts)
end

--- Opens the Window with floating window configurations. Overriding @{Window:open}.
-- @tparam table fwin_cfg Passed to the third argument of `vim.api.nvim_open_win()`.
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
