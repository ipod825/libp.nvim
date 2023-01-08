--- Module: **libp.ui.TitleWindow**
--
-- TitleWindow class. A specialized @{Window} that is intentional for showing title in a @{Grid}. Note that multi-line buffer passed in is modified into a single title line with original lines as far as each other, i.e., aligned. The following example defines a @{TitleWindow} and two @{DiffWindow} windows below it.
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
-- @classmod TitleWindow
local M = require("libp.ui.Window"):EXTEND()
local vimfn = require("libp.utils.vimfn")

--- Constructor.
-- @tparam Buffer buffer
-- @tparam table opts see @{Window:init}. The following arguments have default values:
-- @tparam[opt] table opts.wo
function M:init(buffer, opts)
    opts = opts or {}
    opts.wo = vim.tbl_extend("force", opts.wo or {}, {
        winhighlight = "Normal:LibpTitleWindow",
    })

    buffer:set_content_and_reload({
        require("libp.ui").center_align_text(vimfn.buf_get_lines({ buffer = buffer.id }), vim.o.columns),
    })
    self:SUPER():init(buffer, opts)
end

return M
