--- Module: **libp.ui.Buffer**
--
-- Buffer class. Wrapping vim buffer to display lines and output from jobs.
--
-- Inherits: @{Class}
-- @classmod Buffer
local M = require("libp.datatype.Class"):EXTEND()
local global = require("libp.global")("libp")
local a = require("plenary.async")
local Job = require("libp.Job")
local functional = require("libp.functional")
local ProgressWindow = require("libp.ui.ProgressWindow")
local iter = require("libp.iter")
local iter = require("libp.iter")
local args = require("libp.args")
local values = require("libp.iter").values

global.buffers = global.buffers or {}

--- Returns the Buffer corresponding to the current vim buffer, might be nil if no
--wrapping buffer exists.
-- @treturn Buffer The Buffer object.
-- @usage assert.are.same(Buffer.get_current_buffer().id, vim.api.nvim_get_current_buf())
function M.get_current_buffer()
    return global.buffers[vim.api.nvim_get_current_buf()]
end

--- Returns a new Buffer or an existing one.
-- Note that although this is defined as a member function, the caller should be
-- the Buffer class or classes inheriting buffer. The return type is the caller
-- class. The main difference between this function and @{open_or_new} is
-- that it does not open the Buffer in any window. The caller can then decide
-- how to open the Buffer later (even in a floating window).
-- @tparam table opts
-- @tparam string opts.filename The file name of the corresponding vim buffer.
-- @treturn Buffer The Buffer object.
-- @see Buffer:open_or_new
-- @usage
-- local InheritedBuffer = require("libp.ui.Buffer"):EXTEND()
-- local existing_or_new = InheritedBuffer:get_or_new({ filename = "filename" })
-- assert(existing_or_new:IS(InheritedBuffer))
function M:get_or_new(opts)
    opts = opts or {}
    vim.validate({
        filename = { opts.filename, "s" },
    })

    local id = vim.fn.bufnr(opts.filename)
    local new = id == -1
    -- self is the Buffer class. This is useful for creating inherited Buffer
    -- class.
    return (new and self(opts) or global.buffers[id]), new
end

--- Returns a new Buffer or an existing one and opens the buffer using `opts.open_cmd`
-- Note that although this is defined as a member function, the caller should be
-- the Buffer class or classes inheriting buffer. The return type is the caller
-- class.
-- @tparam table opts
-- @tparam string opts.filename The file name of the corresponding vim buffer.
-- @tparam string opts.open_cmd A valid vim command that opens a file.
-- @treturn Buffer The Buffer object.
-- @see Buffer:get_or_new
-- @usage
-- local InheritedBuffer = require("libp.ui.Buffer"):EXTEND()
-- local existing_or_new = InheritedBuffer:open_or_new({ open_cmd = "tabedit", filename = "filename" })
-- assert(existing_or_new:IS(InheritedBuffer))
function M:open_or_new(opts)
    opts = opts or {}
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

---
-- @field id The id of the vim buffer.

---
-- @field ctx A table for storing arbitrary variables per buffer.

---
-- @field content_ns_id The highlight name space used by @{reload}
-- @{set_hl} and @{clear_hl}

---
-- @field is_reloading Whether @{reload} is running

--- Constructor.
-- @tparam table opts
-- @tparam[opt=nil] string opts.filename The file name of the corresponding vim buffer.
-- @tparam[opt={}] {string}|function opts.content The content to be filled in
-- the corresponding vim buffer. Could be direct content of type array of string
-- or a function that returns a string, which is passed as `cmd` to @{Job:init}.
-- @tparam[opt=identity] function({string})->string opts.content_map_fn The function that maps
-- each line of the content before it's filled in the vim buffer. Should only be
-- useful when `content` is from @{Job}.
-- @tparam[opt=nop] function(buffer,beg,ends,lines,context)->table opts.content_highlight_fn
-- The function that returns highlight info for the content. The signature of
-- `content_highlight_fn` is:
--
-- * buffer: The buffer under operation.
-- * beg: The start line number, see `:help api-indexing`.
-- * ends: The ending line number, see `:help api-indexing`.
-- * context: Arbitrary table for the callee to store internal states (per Buffer).
-- * return: a table with keys of names as `vim.api.nvim_buf_add_highlight`'s arguments'.
-- @tparam[opt=5000] number opts.job_on_stdout_buffer_size Passed to @{Job:init}'s
-- on_stdout_buffer_size for optimizing buffer loading speed.
-- @tparam[opt=nil] boolean opts.buffe_enter_reload Whether to invoke @{reload} on BufEnter.
-- @tparam[opt=nil] table opts.mappings The table defining mappings in all modes. For e.g.
--
--      mappings = {
--          n = { j = function() end },
--          v = { k = function() end },
--      }
--
-- Note that the functions are invoked inside in `plenary.async.void` such that
-- you could define async action for key mappings. Also note that if a Buffer is
-- also constructed inside a `plenary.async.void` context. The user might
-- trigger the mapping before your Buffer's internal states are fully
-- initialized and hit error. In such case, use @{set_mappings} to set the
-- mappings after initialization is done.
-- @tparam[opt={}] table opts.b buffer variables to be set. See `:help vim.b`.
-- @tparam[opt={}] table opts.bo buffer options to be set. See `:help vim.bo`.
function M:init(opts)
    opts = opts or {}
    vim.validate({
        id = { opts.id, "n", true },
        filename = { opts.filename, "s", true },
        content = { opts.content, { "f", "t", "b" }, true },
        content_map_fn = { opts.content_map_fn, "f", true },
        content_highlight_fn = { opts.content_highlight_fn, "f", true },
        job_on_stdout_buffer_size = { opts.job_on_stdout_buffer_size, "n", true },
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
    self._content = args.get_default(opts.content, {})
    self._content_map_fn = opts.content_map_fn or functional.identity
    self._content_highlight_fn = opts.content_highlight_fn or functional.nop
    self._job_on_stdout_buffer_size = opts.job_on_stdout_buffer_size or 5000
    self._mappings = opts.mappings

    self:_mapfn(opts.mappings)

    -- For client to store arbitrary lua object.
    local ctx = {}
    self.ctx = setmetatable({}, { __index = ctx, __newindex = ctx })

    self._mark_ns_id = vim.api.nvim_create_namespace("libp_buffer_mark")
    self.content_ns_id = vim.api.nvim_create_namespace("libp_buffer_content")

    for k, v in pairs(opts.b or {}) do
        vim.b[self.id][k] = v
    end

    local bo = vim.tbl_extend("force", {
        modifiable = false,
        bufhidden = "wipe",
        buftype = "nofile",
        undolevels = -1,
        swapfile = false,
    }, opts.bo or {})
    for k, v in pairs(bo) do
        vim.bo[self.id][k] = v
    end
    self._bo = bo

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

    self._reload_done = a.control.Condvar.new()
    if self._content then
        self:reload()
    end
end

--- Removes the Buffer from the global buffer list. Usually should be called on
-- BufWipeout autocmd. But in case that doesn't happen. One could invoke this
-- function to do it manually.
function M:on_wipeout()
    global.buffers[self.id] = nil
end

--- Sets the mappings of the buffer. Prefer passing `mappings` to @{init} if possible.
-- @tparam table mappings The mappings.
function M:set_mappings(mappings)
    self:_unmapfn(self._mappings)
    self._mappings = mappings
    self:_mapfn(self._mappings)
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
            if type(fn) ~= "boolean" then
                self:_add_key_map(mode, key, fn)
            end
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

function M:_add_key_map(mode, key, map_config)
    vim.validate({
        mode = { mode, "s" },
        key = { key, "s" },
        map_config = { map_config, { "f", "t" } },
    })

    local is_map_config_callable = vim.is_callable(map_config)
    local callback = is_map_config_callable and map_config or map_config[1]
    assert(vim.is_callable(callback), "Libp buffer rhs must be a callable or array with callable as first element.")

    local multi_reload = M.MultiReloadStrategy.WAIT
    if not is_map_config_callable and map_config.multi_reload_strategy then
        multi_reload = map_config.multi_reload_strategy
    end

    local api_map_config = is_map_config_callable and {}
        or {
            nowait = map_config.nowait,
            silent = map_config.silent,
            unique = map_config.unique,
            desc = map_config.desc,
        }

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
            callback()
        end),
        vim.tbl_extend("keep", { buffer = self.id }, api_map_config)
    )
end

function M:mark(data, max_num_data)
    vim.validate({
        max_num_data = args.null_or.positive(max_num_data),
    })

    -- ctx.mark gets cleared on full. _mark_linenrs is a shadow buffer
    -- containing the line numbers for highlight usage.
    self.ctx.mark = self.ctx.mark or {}
    local max_num_data_not_specified = max_num_data == nil
    max_num_data = max_num_data or #self.ctx.mark + 1

    self._mark_linenrs = self._mark_linenrs or {}

    if #self.ctx.mark == max_num_data then
        self.ctx.mark = {}
        -- Clears all previous mark highlight
        for line in values(self._mark_linenrs) do
            self:clear_hl({ line_start = line, ns_id = self._mark_ns_id })
        end
        self._mark_linenrs = {}
    end

    local index = (#self.ctx.mark % max_num_data) + 1
    self.ctx.mark[index] = data
    self._mark_linenrs[index] = vim.fn.line(".") - 1

    if max_num_data_not_specified then
        for linenr in values(self._mark_linenrs) do
            self:set_hl({ hl_group = "LibpBufferMark1", line = linenr, ns_id = self._mark_ns_id })
        end
    else
        for i, linenr in ipairs(self._mark_linenrs) do
            self:set_hl({ hl_group = "LibpBufferMark" .. i, line = linenr, ns_id = self._mark_ns_id })
        end
    end
end

--- Returns whether the Buffer is in edit mode.
-- @treturn boolean
-- @see edit
function M:is_editing()
    return self._is_editing
end

function M:_save_edit()
    self.ctx.edit.update(self.ctx.edit.ori_items, self.ctx.edit.get_items())
    self.ctx.edit = nil
    self._is_editing = false
    vim.bo.buftype = self._bo.buftype
    vim.bo.modifiable = self._bo.modifiable
    vim.bo.undolevels = self._bo.undolevels
    self:_mapfn(self._mappings)
    self:reload()
end

--- Enters "edit mode" for the Buffer. "Edit mode" is a unified way of doing
--buffer content "renaming". For e.g., a file explorer plugin can use edit
--mode to implement file rename functionality. A git plugin can use edit mode to
--implement branch renaming, etc.
-- @tparam table opts
-- @tparam function opts.get_items A function that returns arbitrary result. This
-- function is called two times: when users enters edit mode and after users
-- save the buffer (`:w`), leaving edit mode. The two results are then passed to
-- the `update` function for the plugin author to implement their own logic.
-- @tparam function(ori_items,new_items) opts.update A function that is called with the two
-- outputs of `get_items` after the users leave edit mode with `:w`.
-- @tparam function opts.fill_lines function A function that is called when users just
-- enter edit mode. Plugin authors could use this function to modify the buffer
-- content to giver users a better editing experience.
function M:edit(opts)
    vim.validate({
        get_items = { opts.get_items, "f" },
        update = { opts.update, "f" },
        fill_lines = { opts.fill_lines, "f", true },
    })
    self._is_editing = true

    self:_unmapfn(self._mappings)
    vim.bo.undolevels = -1
    vim.bo.modifiable = true
    if opts.fill_lines then
        opts.fill_lines()
    end
    -- Set it again in case modifiable is changed.
    vim.bo.modifiable = true

    self.ctx.edit = vim.tbl_extend("error", opts, { ori_items = opts.get_items() })
    vim.bo.buftype = "acwrite"
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = self.id,
        once = true,
        callback = a.void(function()
            global.buffers[self.id]:_save_edit()
        end),
    })
    -- buffer's undolevels equals -123456 when global undolevels is to be used.
    vim.bo.undolevels = (self._bo.undolevels > 0) and self._bo.undolevels or vim.go.undolevels
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
        for key, fn in pairs(mode_mappings) do
            if type(fn) ~= "boolean" then
                vim.keymap.del(mode, key, { buffer = self.id })
            end
        end
    end
end

--- Sets the highlight of the buffer. Prefer passing `content_highlight_fn` to
-- @{init} if highlighting happens only during @{reload}.
-- @tparam table opts
-- @tparam string opts.hl_group The highlight group name.
-- @tparam number opts.line The (starting) line to be highlighted (nvim
-- api-indexing).
-- @tparam[opt=1] number opts.col_start The starting column be highlighted
-- (nvim api-indexing)
-- @tparam[opt=-1] number opts.col_end The starting column be highlighted (nvim
-- api-indexing)
-- @tparam[opt] number opts.ns_id. The highlighting ns_id. Default to
-- `Buffer.content_highlight_fn`.
function M:set_hl(opts)
    vim.validate({
        hl_group = { opts.hl_group, "s" },
        line = { opts.line, "n" },
        col_start = { opts.col_start, "n", true },
        col_end = { opts.col_end, "n", true },
        ns_id = { opts.ns_id, "n", true },
    })
    opts.col_start = opts.col_start or 0
    opts.col_end = opts.col_end or -1
    opts.ns_id = opts.ns_id or self.content_ns_id
    vim.api.nvim_buf_add_highlight(self.id, opts.ns_id, opts.hl_group, opts.line, opts.col_start, opts.col_end)
end

--- Clears the highlight of the buffer. Prefer passing `content_highlight_fn` to
-- @{init} if highlighting happens only during @{reload}.
-- @tparam table opts
-- @tparam number opts.line_start The starting line to clear the highlight (nvim
-- api-indexing).
-- @tparam number opts.line_end The starting line to clear the highlight (nvim
-- api-indexing).
-- @tparam[opt] number opts.ns_id. The highlighting namespace. Default to
-- `Buffer.content_highlight_fn`.
function M:clear_hl(opts)
    vim.validate({
        line_start = { opts.line_start, "n" },
        line_end = { opts.line_end, "n", true },
        ns_id = { opts.ns_id, "n", true },
    })
    opts.line_start = opts.line_start or 0
    opts.line_end = opts.line_end or -1
    opts.ns_id = opts.ns_id or self.content_ns_id
    vim.api.nvim_buf_clear_namespace(self.id, opts.ns_id, opts.line_start, opts.line_end)
end

--- Returns an array of windows where the Buffer is visible.
-- @treturn {number} The window ids.
function M:get_attached_wins()
    return iter.V(vim.api.nvim_list_wins())
        :filter(function(w)
            return vim.api.nvim_win_get_buf(w) == self.id
        end)
        :collect()
end

--- Returns the focus window id of the Buffer or nil if no such window exists
--(or focused).
-- @treturn nil|number The window id.
function M:get_focused_win()
    local cur_win = vim.api.nvim_get_current_win()
    return vim.api.nvim_win_get_buf(cur_win) == self.id and cur_win or nil
end

--- Returns whether the Buffer is focused now.
-- @treturn boolean
function M:is_focused()
    return vim.api.nvim_get_current_buf() == self.id
end

-- Clear the buffer.
function M:_clear()
    vim.bo[self.id].undolevels = -1
    vim.bo[self.id].modifiable = true
    vim.api.nvim_buf_set_lines(self.id, 0, -1, false, {})
    vim.bo[self.id].modifiable = self._bo.modifiable
    vim.bo[self.id].undolevels = self._bo.undolevels
end

-- Sets the lines and applies highlight.
function M:_set_lines(beg, ends, lines)
    local marks = self._content_highlight_fn(self, beg, ends, lines, self.ctx) or {}

    if not vim.api.nvim_buf_is_valid(self.id) then
        return
    end

    vim.api.nvim_buf_set_lines(self.id, beg, ends, false, self._content_map_fn(lines))

    for _, mark in ipairs(marks) do
        if not vim.api.nvim_buf_is_valid(self.id) then
            return
        end
        vim.api.nvim_buf_add_highlight(
            self.id,
            self.content_ns_id,
            mark.hl_group,
            mark.line,
            mark.col_start or 0,
            mark.col_end or -1
        )
    end
end

-- Append lines to the buffer from row beg (0-based, inclusive)
function M:_append(lines, beg)
    vim.bo[self.id].undolevels = -1
    vim.bo[self.id].modifiable = true

    self:_set_lines(beg, -1, lines)

    vim.bo[self.id].modifiable = self._bo.modifiable
    vim.bo[self.id].undolevels = self._bo.undolevels
    return beg + #lines
end

--- Sets the content to `content` and invokes @{reload}.
-- @tparam {string}|function content @see @{init}
-- @tparam table opts
-- @tparam function opts.content_highlight_fn Resets the `content_highlight_fn`. @see @{init}
function M:set_content_and_reload(content, opts)
    opts = opts or {}
    vim.validate({
        content = { content, { "f", "t", "b" } },
        content_highlight_fn = { opts.content_highlight_fn, "f", true },
    })
    self._content = content
    self._content_highlight_fn = opts.content_highlight_fn or self._content_highlight_fn
    self:reload()
end

--- Waits existing @{reload} calls to finish. Note that if there's no existing
-- @{reload} call, it waits forever. Better check `Buffer.is_reloading` before
-- calling this function.
-- @treturn boolean
function M:wait_reload()
    self._reload_done:wait()
end

--- Reloads the buffer by filling the contents (invoking content generating Job)
-- and apply the highlight function.
function M:reload()
    if self.is_reloading then
        return
    end
    self.is_reloading = true
    -- Clear the marks so that we don't hit into invisible marks.
    self.ctx.mark = nil
    self.cancel_reload = false

    if self._bo.filetype then
        vim.bo[self.id].filetype = self._bo.filetype
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
    local affected_win_cursors = iter.KV(self:get_attached_wins())
        :map(function(_, w)
            return w, vim.api.nvim_win_get_cursor(w)
        end)
        :collect()

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

    vim.api.nvim_buf_clear_namespace(self.id, self.content_ns_id, 0, -1)

    if type(self._content) == "table" then
        vim.bo[self.id].modifiable = true
        self:_set_lines(0, -1, self._content)
        vim.bo[self.id].modifiable = self._bo.modifiable
        restore_cursor()
    else
        self:_clear()

        local beg = 0
        local job
        job = Job({
            cmd = self._content(),
            on_stdout_buffer_size = self._job_on_stdout_buffer_size,
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
    self._reload_done:notify_all()
end

return M
