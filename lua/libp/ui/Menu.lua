local M = require("libp.datatype.Class"):EXTEND()
local Buffer = require("libp.ui.Buffer")
local BorderedWindow = require("libp.ui.BorderedWindow")
local functional = require("libp.functional")
local a = require("plenary.async")
local values = require("libp.itertools").values
local vimfn = require("libp.utils.vimfn")
local KVIter = require("libp.datatype.KVIter")
local bind = require("libp.functional").bind

function M:init(opts)
    vim.validate({
        title = { opts.title, { "s" }, true },
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
    self.fwin_cfg = vim.tbl_extend("keep", opts.fwin_cfg or {}, {
        relative = "win",
        row = cursor_pos[1] + cursor_offset[1],
        col = cursor_pos[2] + cursor_offset[2],
        width = 0,
        height = 0,
        zindex = 1,
        anchor = "NW",
        border = "none",
    })

    self.select_map = opts.select_map
    self.short_key_map = opts.short_key_map
    self.border_opts = opts.border_opts or {}
    self.border_opts.title = self.border_opts.title or opts.title
    self.on_select = opts.on_select or functional.nop
    self.wo = opts.wo or {}

    local content = opts.content or {}
    local mappings = {
        ["<cr>"] = self:BIND(self.confirm),
        ["<esc>"] = bind(vim.api.nvim_win_close, 0, true),
        ["q"] = bind(vim.api.nvim_win_close, 0, true),
    }
    if opts.short_key_map then
        assert(#content == #opts.short_key_map)
        for i, key in KVIter(opts.short_key_map) do
            content[i] = ("%s. %s"):format(opts.short_key_map[i], opts.content[i])
            mappings[key] = self:BIND(self.confirm, i)
        end
    end

    self.fwin_cfg.height = #content
    for c in values(content) do
        if #c > self.fwin_cfg.width then
            self.fwin_cfg.width = #c
        end
    end

    -- +2 for two padding white space around the title. +2 for at least one
    -- border character on both side of the title.
    if self.border_opts.title and #self.border_opts.title + 4 > self.fwin_cfg.width then
        self.fwin_cfg.width = #self.border_opts.title + 4
    end

    -- +2 for the border character.
    self.fwin_cfg.height = self.fwin_cfg.height + 2
    self.fwin_cfg.width = self.fwin_cfg.width + 2

    self.buffer = Buffer({
        content = content,
        mappings = {
            n = mappings,
        },
    })
end

function M:confirm(row)
    if row then
        vimfn.setrow(row)
    end

    local res
    if self.select_map then
        res = self.select_map[vimfn.getrow()]
    else
        res = vim.fn.getline(".")
        if self.short_key_map then
            res = res:gsub("^.-%. ", "")
        end
    end

    vim.api.nvim_win_close(0, true)
    self.on_select(res)
end

function M:get_border_window()
    return self.window:get_border_window()
end

function M:get_inner_window()
    return self.window:get_inner_window()
end

function M:show()
    self.window = BorderedWindow(self.buffer, { focus_on_open = true, wo = self.wo }, self.border_opts)
    self.window:open(self.fwin_cfg)
    vim.api.nvim_win_set_var(self.window:get_inner_window().id, "_is_libp_menu", true)
end

M.select = a.wrap(function(self, callback)
    self.on_select = callback
    self:show()
end, 2)

function M.will_select_from_menu(run_before_selection)
    -- This functoin is mainly for testing purpose. When testing an async
    -- function that invokes Menu():select(), do the following:
    -- ```lua
    --   Menu.will_select_from_menu(function()
    --       -- The window is open now. Move the cursor to the item you want to
    --       -- test and it will be selected.
    --   end)
    --   function_that_open_a_menu()
    -- ```
    local timer = vim.loop.new_timer()
    local select_from_menu
    run_before_selection = run_before_selection or functional.nop

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
            run_before_selection()
            -- Not sure why nvim_input('<cr>') doesn't work here.
            for m in values(vim.api.nvim_buf_get_keymap(0, "n")) do
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
