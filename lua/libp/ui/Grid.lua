--- Module: **libp.ui.Grid**
--
-- Grid class. Container class for laying out @{Window}s. It provides APIs for
-- users to add windows in a virtual grid from top-left to bottom-right. The
-- good thing is that users only need to specify the desired with/height (can
-- even be skipped if full width/height or equal split are good enough) and Grid
-- would calculate the row/column automatically. The following example defines a
-- @{TitleWindow} and two @{DiffWindow} windows below it.
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
-- Note that we didn't need to specify the widht/height for the two diff windows
-- as we want them to take full height in the rest of the Grid and split equally
-- horizontally.
--
-- Inherits: @{Class}
-- @classmod Grid
local M = require("libp.datatype.Class"):EXTEND()
local values = require("libp.iter").values

--- Constructor. All the options in `opts` that also appears in `nvim_open_win`
--sets the default value of the Grid "virtual" window and all the windows inside
--it. Position arguments: width/height/row/col are recalculated for inner
--windows automatically. So these parameters only decides the position of the
--virtual "Grid" window.
-- @tparam table opts
-- @tparam[opt=nil] string opts.relative See `nvim_open_win`.
-- @tparam[opt=nil] number opts.width See `nvim_open_win`.
-- @tparam[opt=nil] number opts.height See `nvim_open_win`.
-- @tparam[opt=nil] number opts.row See `nvim_open_win`.
-- @tparam[opt=nil] number opts.col See `nvim_open_win`.
-- @tparam[opt=nil] number opts.zindex See `nvim_open_win`.
-- @tparam[opt=nil] boolean opts.focusable
-- @tparam[opt=nil] nil|Grid root Implementation detail. Normal user should pass nil.
function M:init(opts, root)
    opts = opts or {}
    vim.validate({
        relative = { opts.relative, "s", true },
        width = { opts.width, "n", true },
        height = { opts.height, "n", true },
        row = { opts.row, "n", true },
        col = { opts.col, "number", true },
        zindex = { opts.zindex, "number", true },
        focusable = { opts.focusable, "boolean", true },
    })

    self.fwin_cfg = {
        relative = opts.relative or "editor",
        width = opts.width or vim.o.columns,
        height = opts.height or vim.o.lines - 2,
        row = opts.row or 0,
        col = opts.col or 0,
        zindex = opts.zindex or 1,
        focusable = opts.focusable or false,
        anchor = "NW",
        noautocmd = false,
    }

    self._root = root or self
    self._window = nil
    self._children = {}
end

--- Adds a single row, which is another @{Grid}, to the current grid.
-- @tparam table opts
-- @tparam number opts.height The height of the new row
-- @tparam boolean opts.focusable Whether the windows inside the new row are
-- focusable. See `nvim_open_win`.
-- @treturn Grid The added row.
function M:add_row(opts)
    opts = opts or {}
    vim.validate({
        height = { opts.height, "n", true },
        focusable = { opts.focusable, "b", true },
    })

    local height = opts.height
    if height and height < 0 then
        height = self.fwin_cfg.height + height
    end
    height = height or self.fwin_cfg.height
    height = math.min(height, self.fwin_cfg.height)
    assert(height > 0, ("Can't add more rows %d %d"):format(height, self.fwin_cfg.height))

    local fwin_cfg = vim.tbl_extend("force", self.fwin_cfg, { height = height, focusable = opts.focusable })
    local row = M(fwin_cfg, self._root)
    table.insert(self._children, row)
    self.fwin_cfg.row = self.fwin_cfg.row + height
    self.fwin_cfg.height = self.fwin_cfg.height - height
    return row
end

--- Adds a single column, which is another @{Grid}, to the current grid.
-- @tparam table opts
-- @tparam number opts.width The width of the new column
-- @tparam boolean opts.focusable Whether the windows inside the new row are
-- focusable. See `nvim_open_win`.
-- @treturn Grid The added column.
function M:add_column(opts)
    opts = opts or {}
    vim.validate({
        width = { opts.width, "n", true },
        focusable = { opts.focusable, "b", true },
    })

    local width = opts.width
    width = width or self.fwin_cfg.width
    width = math.min(width, self.fwin_cfg.width)
    assert(width > 0, "Can't add more columns")

    local fwin_cfg = vim.tbl_extend("force", self.fwin_cfg, { width = width, focusable = opts.focusable })
    local column = M(fwin_cfg, self._root)
    table.insert(self._children, column)
    self.fwin_cfg.col = self.fwin_cfg.col + width
    self.fwin_cfg.width = self.fwin_cfg.width - width
    return column
end

--- Fills the entire grid with the window.
-- @tparam Window window the window to be filled.
-- @treturn Window The window filled.
function M:fill_window(window)
    self._window = window
    return window
end

--- Fills the entire grid with the windows vertically. Each window will have
--(roughly) the same width.
-- @tparam {Window} windows The windows to be filled.
function M:vfill_windows(windows)
    local width = math.floor(self.fwin_cfg.width / #windows)
    local last_width = self.fwin_cfg.width - width * (#windows - 1)
    for i, window in ipairs(windows) do
        local column = self:add_column({
            width = (i == #windows and last_width or width),
            focusable = self.fwin_cfg.focusable,
        })
        column:fill_window(window)
    end
end

--- Closes the grid "virtual" window and all windows in it.
function M:close()
    if self._window then
        self._window:close()
    else
        for child in values(self._children) do
            child:close()
        end
    end
end

--- Shows the grid "virtual" window and all windows in it.
function M:show()
    if self._window then
        local win_id = self._window:open(self.fwin_cfg)
        vim.api.nvim_create_autocmd("WinClosed", {
            pattern = tostring(win_id),
            once = true,
            callback = function()
                self._root:close()
                -- autocmd doesn't nest. Invoke BufEnter by ourselves.
                vim.api.nvim_exec_autocmds("BufEnter", { pattern = "*" })
            end,
        })
    else
        for child in values(self._children) do
            child:show()
        end
    end
end

return M
