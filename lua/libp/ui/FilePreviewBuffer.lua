--- Module: **libp.ui.FilePreviewBuffer**
--
-- FilePreviewBuffer class. Loading read-only file content to vim buffer
-- asynchronously. There's also @{FileBuffer} that creates modifiable buffer.
-- Both @{FilePreviewBuffer} and @{FileBuffer} exists for loading file content into
-- a floating @{Window} asynchronously:
--
--     local ui = require("libp.ui")
--     require("plenary.async").void(function()
--         local buf = ui.FilePreviewBuffer("file_to_load")
--         local win = ui.Window(buf)
--         win:open()
--     end)()
--
-- Inherits: @{Class}
-- @classmod FilePreviewBuffer
local M = require("libp.datatype.Class"):EXTEND()
local uv = require("libp.fs.uv")
local vimfn = require("libp.utils.vimfn")

--- Constructor.
-- @tparam string filename The file name to load content from.
-- @tparam table opts
-- @tparam[opt=false] boolean opts.listed Whether the vim buffer is listed (see
-- `:help nvim_create_buf`).
-- @tparam[opt=true] boolean opts.scratch Whether the vim buffer is scratch.
-- (see `:help nvim_create_buf`).
-- @tparam[opt=5000] number opts.read_buffer_size number of bytes to read in
-- batch. This is used for performance tuning.
-- @tparam[opt={}] table opts.bo buffer options to be set. See `:help vim.bo`.
function M:init(filename, opts)
    vim.validate({
        filename = { filename, "s" },
        listed = { opts.listed, "b", true },
        scratch = { opts.scratch, "b", true },
        read_buffer_size = { opts.read_buffer_size, "n", true },
        bo = { opts.bo, "t", true },
    })
    opts = vim.tbl_extend("keep", opts or {}, { listed = false, scratch = true })
    opts.read_buffer_size = opts.read_buffer_size or 50000

    local fd, stat, err
    fd, err = uv.fs_open(filename, "r", 448)
    if err then
        vimfn.error(err)
        return
    end
    stat, err = uv.fs_fstat(fd)
    if err then
        vimfn.error(err)
        uv.fs_close(fd)
        return
    end

    self.id = vim.api.nvim_create_buf(opts.listed, opts.scratch)

    local bo = vim.tbl_extend("force", {
        modifiable = false,
        bufhidden = "wipe",
    }, opts.bo or {})
    for k, v in pairs(bo) do
        vim.bo[self.id][k] = v
    end
    self.bo = bo

    vim.bo[self.id].modifiable = false
    vim.bo[self.id].undolevels = -1
    vim.bo[self.id].undofile = false

    -- Remove last newline by reading one less byte.
    local remain_size = stat.size - 1

    local last_line = ""
    local offset = 0
    local num_lines = 0
    while remain_size > 0 do
        local content, _ = uv.fs_read(fd, math.min(remain_size, opts.read_buffer_size), offset)
        offset = offset + opts.read_buffer_size
        remain_size = remain_size - opts.read_buffer_size
        if not vim.api.nvim_buf_is_valid(self.id) then
            uv.fs_close(fd)
            return
        end

        -- Though we fill the last line in lines below, we always assume it's
        -- partial (content did not end with a newline) and overwrite in the
        -- next loop (note the -1 when we update num_lines). Note that even if
        -- the content ends with a newline, this still work as in such case, the
        -- last line in lines is the empty string.
        local lines = vim.split(content, "\n")
        lines[1] = last_line .. lines[1]

        vim.bo[self.id].modifiable = true
        vim.api.nvim_buf_set_lines(self.id, num_lines, -1, false, lines)
        vim.bo[self.id].modifiable = false

        num_lines = num_lines + #lines - 1
        last_line = lines[#lines]
    end

    vim.bo[self.id].undolevels = self.bo.undolevels or vim.go.undolevels
    vim.bo[self.id].modified = false
    vim.bo[self.id].modifiable = self.bo.modifiable
end

function M:on_wipeout() end

return M
