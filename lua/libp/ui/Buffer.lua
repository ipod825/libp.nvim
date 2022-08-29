local M = require("libp.datatype.Class"):EXTEND()
local global = require("libp.global")("libp")
local a = require("plenary.async")
local Job = require("libp.Job")
local functional = require("libp.functional")
local ProgressWindow = require("libp.ui.ProgressWindow")
local VIter = require("libp.datatype.VIter")
local KVIter = require("libp.datatype.KVIter")
local args = require("libp.utils.args")
local values = require("libp.datatype.itertools").values

global.buffers = global.buffers or {}

function M.get_current_buffer()
    return global.buffers[vim.api.nvim_get_current_buf()]
end

function M:get_or_new(opts)
    vim.validate({
        filename = { opts.filename, "s" },
    })

    local id = vim.fn.bufnr(opts.filename)
    local new = id == -1
    -- self is the Buffer class. This is useful for creating inherited Buffer
    -- class.
    return (new and self(opts) or global.buffers[id]), new
end

function M:open_or_new(opts)
    vim.validate({
        open_cmd = { opts.open_cmd, "s" },
        filename = { opts.filename, "s" },
    })

    vim.cmd(("%s %s"):format(opts.open_cmd, opts.filename))
    opts.id = vim.api.nvim_get_current_buf()
    local new = global.buffers[opts.id] == nil
    -- self is the Buffer class. This is useful for creating inherited Buffer
    -- class.
    return (new and self(opts) or global.buffers[opts.id]), new
end

function M:init(opts)
    opts = opts or {}
    vim.validate({
        filename = { opts.filename, "s", true },
        content = { opts.content, { "f", "t", "b" }, true },
        buf_enter_reload = { opts.buf_enter_reload, "b", true },
        mappings = { opts.mappings, "t", true },
        b = { opts.b, "table", true },
        bo = { opts.bo, "table", true },
    })

    if opts.id then
        assert(global.buffers[opts.id] == nil, "Each vim buffer can only maps to one Buffer instance")
        self.id = opts.id
    else
        self.id = vim.api.nvim_create_buf(false, true)
        if opts.filename then
            vim.api.nvim_buf_set_name(self.id, opts.filename)
        end
    end

    global.buffers[self.id] = self
    self.content = args.get_default(opts.content, {})
    self.mappings = opts.mappings

    self:_mapfn(opts.mappings)

    -- For client to store arbitrary lua object.
    local ctx = {}
    self.ctx = setmetatable({}, { __index = ctx, __newindex = ctx })

    self.namespace = vim.api.nvim_create_namespace("")

    for k, v in pairs(opts.b or {}) do
        vim.api.nvim_buf_set_var(self.id, k, v)
    end

    local bo = vim.tbl_extend("force", {
        modifiable = false,
        bufhidden = "wipe",
        buftype = "nofile",
        undolevels = -1,
        swapfile = false,
    }, opts.bo or {})
    for k, v in pairs(bo) do
        vim.api.nvim_buf_set_option(self.id, k, v)
    end
    self.bo = bo

    -- The following autocmds might not be triggered due to nested autocmds. The
    -- handlers are invoked manually in other places when necessary.

    -- free memory on BufUnload
    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = self.id,
        once = true,
        callback = function()
            self:on_wipeout()
        end,
    })

    -- reload on :edit
    vim.api.nvim_create_autocmd("BufReadCmd", {
        buffer = self.id,
        callback = a.void(function()
            self:reload()
        end),
    })

    -- reload on BufEnter
    if opts.buf_enter_reload then
        vim.api.nvim_create_autocmd("BufEnter", {
            buffer = self.id,
            callback = a.void(function()
                self:reload()
            end),
        })
    end

    self.reload_done = a.control.Condvar.new()
    if self.content then
        self:reload()
    end
end

function M:on_wipeout()
    global.buffers[self.id] = nil
end

function M:set_mappings(mappings)
    self:_unmapfn(self.mappings)
    self.mappings = mappings
    self:_mapfn(self.mappings)
end

function M:_mapfn(mappings)
    if not mappings then
        return
    end
    for mode, mode_mappings in pairs(mappings) do
        vim.validate({
            mode = { mode, "s" },
            mode_mappings = { mode_mappings, "t" },
        })
        for key, fn in pairs(mode_mappings) do
            self:_add_key_map(mode, key, fn)
        end
    end
end

M.MultiReloadStrategy = {
    -- Wait for any existing reload to finish. The caller might be blocked and
    -- is free to do anything after unblock. This is the default behavior and
    -- should be good in most cases. Only if the Buffer contains more than 10k
    -- lines should we try to reduce user waiting time with the following
    -- options.
    WAIT = 1,
    -- Cancel any existing reload. The caller will never be blocked but is
    -- expected to trigger another reload so that the buffer content will still
    -- be up-to-date.
    CANCEL = 2,
    -- Ignore any existing reload. The caller will never be blocked and is
    -- expected to not trigger any reload.
    IGNORE = 3,
}

function M:_add_key_map(mode, key, fn)
    vim.validate({
        mode = { mode, "s" },
        key = { key, "s" },
        fn = { fn, { "f", "t" } },
    })

    local multi_reload = M.MultiReloadStrategy.WAIT
    if type(fn) == "table" then
        multi_reload = fn.multi_reload_strategy
        fn = fn.callback
    end

    vim.keymap.set(
        mode,
        key,
        a.void(function()
            if self.is_reloading then
                if multi_reload == M.MultiReloadStrategy.WAIT then
                    self:wait_reload()
                elseif multi_reload == M.MultiReloadStrategy.CANCEL then
                    self.cancel_reload = true
                end
            end
            fn()
        end),
        { buffer = self.id }
    )
end

function M:mark(data, max_num_data)
    vim.validate({
        max_num_data = {
            max_num_data,
            function(e)
                return e > 0
            end,
            true,
        },
    })

    -- ctx.mark gets cleared on full. _mark_linenrs is a shadow buffer
    -- containing the line numbers for highlight usage.
    self.ctx.mark = self.ctx.mark or {}
    max_num_data = max_num_data or #self.ctx.mark + 1

    self._mark_linenrs = self._mark_linenrs or {}

    if #self.ctx.mark == max_num_data then
        self.ctx.mark = {}
        -- Clears all previous mark highlight
        for line in values(self._mark_linenrs) do
            self:clear_hl(line)
        end
        self._mark_linenrs = {}
    end

    local index = (#self.ctx.mark % max_num_data) + 1
    self.ctx.mark[index] = data
    self._mark_linenrs[index] = vim.fn.line(".")

    for i, linenr in ipairs(self._mark_linenrs) do
        self:set_hl("LibpBufferMark" .. i, linenr)
    end
end

function M:_save_edit()
    self.ctx.edit.update(self.ctx.edit.ori_items, self.ctx.edit.get_items())
    self.ctx.edit = nil
    vim.bo.buftype = self.bo.buftype
    vim.bo.modifiable = self.bo.modifiable
    vim.bo.undolevels = self.bo.undolevels
    self:_mapfn(self.mappings)
    self:reload()
end

function M:edit(opts)
    vim.validate({
        get_items = { opts.get_items, "f" },
        update = { opts.update, "f" },
        fill_lines = { opts.fill_lines, "f", true },
    })
    self.ctx.edit = vim.tbl_extend("error", opts, { ori_items = opts.get_items() })
    vim.bo.buftype = "acwrite"
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = self.id,
        once = true,
        callback = a.void(function()
            global.buffers[self.id]:_save_edit()
        end),
    })
    self:_unmapfn(self.mappings)
    vim.bo.undolevels = -1
    vim.bo.modifiable = true
    if opts.fill_lines then
        opts.fill_lines()
    end
    -- buffer's undolevels equals -123456 when global undolevels is to be used.
    vim.bo.undolevels = (self.bo.undolevels > 0) and self.bo.undolevels or vim.go.undolevels
end

function M:_unmapfn(mappings)
    if not mappings then
        return
    end
    for mode, mode_mappings in pairs(mappings) do
        vim.validate({
            mode = { mode, "s" },
            mode_mappings = { mode_mappings, "t" },
        })
        for key, _ in pairs(mode_mappings) do
            vim.keymap.del(mode, key, { buffer = self.id })
        end
    end
end

function M:get_lines(beg, ends, strict_indexing)
    vim.validate({
        beg = { beg, "n", true },
        ends = { ends, "n", true },
        strict_indexing = { strict_indexing, "b", true },
    })
    beg = beg and beg - 1 or 0
    ends = ends and ends - 1 or -1
    strict_indexing = args.get_default(strict_indexing, true)
    return vim.api.nvim_buf_get_lines(self.id, beg, ends, strict_indexing)
end

function M:get_line(ind)
    vim.validate({ ind = { ind, "n" } })
    return self:get_lines(ind, ind + 1)[1]
end

function M:set_hl(hl, row, col_start, col_end)
    col_start = col_start or 1
    col_end = col_end or -1
    vim.api.nvim_buf_add_highlight(self.id, self.namespace, hl, row - 1, col_start - 1, col_end)
end

function M:clear_hl(row_start, row_end)
    vim.validate({ row_start = { row_start, "n" } })
    row_end = row_end or row_start + 1
    vim.api.nvim_buf_clear_namespace(self.id, self.namespace, row_start - 1, row_end - 1)
end

function M:get_attached_wins()
    return VIter(vim.api.nvim_list_wins()):filter(function(w)
        return vim.api.nvim_win_get_buf(w) == self.id
    end):collect()
end

function M:get_focused_win()
    local cur_win = vim.api.nvim_get_current_win()
    return vim.api.nvim_win_get_buf(cur_win) == self.id and cur_win or nil
end

function M:is_focused()
    return vim.api.nvim_get_current_buf() == self.id
end

function M:_clear()
    vim.api.nvim_buf_set_option(self.id, "undolevels", -1)
    vim.api.nvim_buf_set_option(self.id, "modifiable", true)
    vim.api.nvim_buf_set_lines(self.id, 0, -1, false, {})
    vim.api.nvim_buf_set_option(self.id, "modifiable", self.bo.modifiable)
    vim.api.nvim_buf_set_option(self.id, "undolevels", self.bo.undolevels)
end

function M:_append(lines, beg)
    vim.api.nvim_buf_set_option(self.id, "undolevels", -1)
    vim.api.nvim_buf_set_option(self.id, "modifiable", true)

    vim.api.nvim_buf_set_lines(self.id, beg, -1, false, lines)

    vim.api.nvim_buf_set_option(self.id, "modifiable", self.bo.modifiable)
    vim.api.nvim_buf_set_option(self.id, "undolevels", self.bo.undolevels)
    return beg + #lines
end

function M:set_content_and_reload(content)
    vim.validate({ content = { content, { "f", "t", "b" } } })
    self.content = content
    self:reload()
end

function M:wait_reload()
    self.reload_done:wait()
end

-- Sets the highlights of the buffer. This is invoked at the end of reload so
-- the subclass can override it to add default highlight behavior after reload.
-- This can also be called manually by passing a VIter of highlights. Each
-- element in the VIter is an array of highlights, each of which is of the form
-- {hl_name, row, col_beg, col_end}. Note that `col_beg` and `col_end` are
-- optional. See `set_hl` for their default values.
function M:reload_highlight(highlights)
    vim.validate({
        highlights = {
            highlights,
            function(e)
                return e == nil or (e.IS and e:IS(VIter))
            end,
            true,
        },
    })

    if highlights then
        self:clear_hl(1, -1)
        for row_highlights in highlights do
            for highlight in VIter(row_highlights) do
                self:set_hl(unpack(highlight))
            end
        end
    end
end

function M:reload()
    if self.is_reloading then
        return
    end
    self.is_reloading = true
    -- Clear the marks so that we don't hit into invisible marks.
    self.ctx.mark = nil
    self.cancel_reload = false

    if self.bo.filetype then
        vim.api.nvim_buf_set_option(self.id, "filetype", self.bo.filetype)
    end

    local self_buffer_focused = vim.api.nvim_get_current_buf() == self.id

    local pbar
    local init_pbar_on_second_stdout = functional.nop
    if self_buffer_focused then
        -- Only show the progress bar if on_stdout is called more than one time.
        init_pbar_on_second_stdout = functional.oneshot(function()
            pbar = ProgressWindow({ desc = "Loading " })
            pbar:open()
        end, 2)
    end

    local focused_win = self_buffer_focused and vim.api.nvim_get_current_win()
    local affected_win_cursors = KVIter(self:get_attached_wins()):mapkv(function(_, w)
        return w, vim.api.nvim_win_get_cursor(w)
    end):collect()

    local restore_count = 0
    local restore_cursor = function()
        local line_count = vim.api.nvim_buf_line_count(self.id)
        for w, cursor in pairs(affected_win_cursors) do
            if vim.api.nvim_win_is_valid(w) then
                -- We restore all attached window cursor to compensate cursor
                -- move when we set the content of the buffer. In job stdout
                -- case, for the focused window, we only restore the cursor
                -- once. Because for content that can be drawn in one shot,
                -- reload should finish before any new user interaction. For
                -- content that needs to be drawn in multiple run, restoring the
                -- cursor after every nvim_buf_set_lines just annoys the user.
                if w ~= focused_win or restore_count == 0 then
                    vim.api.nvim_win_set_cursor(w, { math.min(line_count, cursor[1]), cursor[2] })
                end
            end
            restore_count = restore_count + 1
        end
    end

    if type(self.content) == "table" then
        vim.api.nvim_buf_set_option(self.id, "modifiable", true)
        vim.api.nvim_buf_set_lines(self.id, 0, -1, false, self.content)
        vim.api.nvim_buf_set_option(self.id, "modifiable", self.bo.modifiable)
        restore_cursor()
    else
        self:_clear()

        local beg = 0
        local job
        job = Job({
            cmd = self.content(),
            on_stdout = function(lines)
                if not vim.api.nvim_buf_is_valid(self.id) or self.cancel_reload then
                    job:kill()
                    return
                end

                beg = self:_append(lines, beg)
                restore_cursor()
                init_pbar_on_second_stdout()
                if pbar then
                    pbar:tick()
                end
            end,
        })

        job:start()
        if pbar then
            pbar:close()
        end
    end

    self.is_reloading = false
    self.reload_done:notify_all()
    self:reload_highlight()
end

return M
