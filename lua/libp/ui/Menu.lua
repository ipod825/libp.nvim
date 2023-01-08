--- Module: **libp.ui.Menu**
--
-- Menu class. A ui for user to pick entry and execute corresponding actions.
-- One can use Menu in non-async context using callback style `on_select`:
--     local selected = nil
--     local m = Menu({
--         content = { "a", "b", "c" },
--         on_select = function(item)
--             selected = item
--         end,
--     })
--     m:show()
--     -- In real use case, it's user who select the second row.
--     m:confirm(2)
--     assert.are.same("b", selected)
-- Menu also provides APIs for use in plenary async context.
--
--     require("plenary.async").void(function()
--         local item = ui.Menu({
--             content = {
--                 "a",
--                 "b",
--                 "c",
--             },
--         }):select()
--         -- The coroutine blocks here until the user selects or close the window.
--     end)
--
-- Inherits: @{Class}
-- @classmod Menu
local M = require("libp.datatype.Class"):EXTEND()
local Buffer = require("libp.ui.Buffer")
local BorderedWindow = require("libp.ui.BorderedWindow")
local functional = require("libp.functional")
local a = require("plenary.async")
local vimfn = require("libp.utils.vimfn")
local iter = require("libp.iter")
local bind = require("libp.functional").bind

--- Constructor
-- @tparam table opts
-- @tparam {string} opts.content The entries of the menu.
-- @tparam[opt=""] string opts.title The title to be shown on top of the surrounding @{BorderWindow}.
-- @tparam[opt=nop] function(string) opts.on_select The callback function for the
-- Menu. See @{Menu} introduction.
-- @tparam[opt={}] array opts.select_map For mapping selected row number to the return
-- result. This is useful because we might put more lengthy text in `content`
-- while in code we want to use short string for comparison.
-- @tparam[opt={0,0}] {number} opts.cursor_offset A pair of (row_offset, col_offset),
-- which moves the Menu window position. If not set, by default the window shows
-- near the cursor position.
-- @tparam[opt={}] table opts.fwin_cfg Controls the position of the Menu window. In
-- most cases, prefer using `cursor_offset` over this low level parameters for
-- @{Window:init}.
-- @tparam[opt={}] table opts.wo Passed to @{Window:init}. Sets the Menu window options.
-- @tparam[opt={}] table opts.border_opts Passed to @{BorderWindow:init} to
-- configure the border window.
function M:init(opts)
    vim.validate({
        title = { opts.title, "s", true },
        content = { opts.content, "t" },
        select_map = { opts.select_map, "t", true },
        short_key_map = { opts.short_key_map, "t", true },
        fwin_cfg = { opts.fwin_cfg, "t", true },
        cursor_offset = { opts.cursor_offset, "t", true },
        wo = { opts.wo, "t", true },
        border_opts = { opts.border_opts, "t", true },
        on_select = { opts.on_select, "f", true },
    })

    local cursor_offset = opts.cursor_offset or { 0, 0 }
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    self._fwin_cfg = vim.tbl_extend("keep", opts.fwin_cfg or {}, {
        relative = "win",
        row = cursor_pos[1] + cursor_offset[1],
        col = cursor_pos[2] + cursor_offset[2],
        width = 0,
        height = 0,
        zindex = 1,
        anchor = "NW",
        border = "none",
    })

    self._select_map = opts.select_map
    self._short_key_map = opts.short_key_map
    self._border_opts = opts.border_opts or {}
    self._border_opts.title = opts.title or self._border_opts.title
    self._on_select = opts.on_select or functional.nop
    self._wo = opts.wo or {}

    local content = opts.content or {}
    local mappings = {
        ["<cr>"] = self:BIND(self.confirm),
        ["<esc>"] = self:BIND(self.close),
        ["q"] = self:BIND(self.close),
    }
    if opts.short_key_map then
        assert(#content == #opts.short_key_map)
        for i, key in iter.KV(opts.short_key_map) do
            content[i] = ("%s. %s"):format(opts.short_key_map[i], opts.content[i])
            mappings[key] = self:BIND(self.confirm, i)
        end
    end

    self._fwin_cfg.height = #content
    for c in iter.values(content) do
        if #c > self._fwin_cfg.width then
            self._fwin_cfg.width = #c
        end
    end

    -- +2 for two padding white space around the title. +2 for at least one
    -- border character on both side of the title.
    if self._border_opts.title and #self._border_opts.title + 4 > self._fwin_cfg.width then
        self._fwin_cfg.width = #self._border_opts.title + 4
    end

    -- +2 for the border character.
    self._fwin_cfg.height = self._fwin_cfg.height + 2
    self._fwin_cfg.width = self._fwin_cfg.width + 2

    self._buffer = Buffer({
        content = content,
        mappings = {
            n = mappings,
        },
    })
end

--- Calls `on_select`. Only calls this function in a test as the Menu defines
--key mapping to trigger this function automatically.
-- @tparam[opt=nil] number row If non-nil, selects the row. Otherwise, the
-- current row would be used.
function M:confirm(row)
    vim.validate({ row = { row, "n", true } })
    if row then
        vimfn.setrow(row)
    end

    local res
    if self._select_map then
        res = self._select_map[vimfn.getrow()]
    else
        res = vim.fn.getline(".")
        if self._short_key_map then
            res = res:gsub("^.-%. ", "")
        end
    end

    vim.api.nvim_win_close(0, true)
    self._on_select(res)
end

-- Gets the border window.
function M:get_border_window()
    return self._window:get_border_window()
end

-- Gets the inner window.
function M:get_inner_window()
    return self._window:get_inner_window()
end

--- Shows the Menu window.
function M:show()
    self._window = BorderedWindow(self._buffer, { focus_on_open = true, wo = self._wo }, self._border_opts)
    self._window:open(self._fwin_cfg)
    vim.api.nvim_win_set_var(self._window:get_inner_window().id, "_is_libp_menu", true)
end

--- Closes the menus window. Only calls this function in a test as the Menu defines
-- key mapping to trigger this function automatically.
function M:close()
    vim.api.nvim_win_close(self._window.id, true)
    self._on_select()
end

--- Selects item from the menu in plenary async context. See @{Menu} introduction.
-- @function M:select
M.select = a.wrap(function(self, callback)
    self._on_select = callback
    self:show()
end, 2)

--- Testing purpose function. When testing an async
-- function that invokes `Menu():select()`, do the following:
-- @usage
-- a.it("Demo will_select_from_menu", function()
--     Menu.will_select_from_menu(function()
--         -- The window is open now. You can do test inside this function.
--         -- You must return the row number (1-based) to be selected.
--         -- Otherwise, no row would be selected. -- test and it will be
--         -- selected.
--     end)
--     function_that_open_a_menu()
-- end)
function M.will_select_from_menu(get_selected_row)
    local timer = vim.loop.new_timer()
    local select_from_menu
    get_selected_row = get_selected_row or functional.nop

    select_from_menu = function()
        if not vim.w._is_libp_menu then
            timer:start(
                10,
                0,
                vim.schedule_wrap(function()
                    select_from_menu()
                end)
            )
        else
            timer:stop()
            timer:close()
            local row = get_selected_row()
            if not row then
                vim.fn.feedkeys("q", "x")
                return
            end
            vimfn.setrow(row)

            -- Not sure why vim.fn.feedkeys("\\<cr>", "x") doesn't work here.
            for m in iter.values(vim.api.nvim_buf_get_keymap(0, "n")) do
                if m.lhs == "<CR>" then
                    m.callback()
                    break
                end
            end
        end
    end
    select_from_menu()
end

return M
