local M = require("libp.datatype.Class"):EXTEND()
local uv = require("libp.fs.uv")
local vimfn = require("libp.utils.vimfn")

function M:init(filename, opts)
    vim.validate({ filename = { filename, "s" }, opts = { opts, "t", true } })
    opts = opts or {}
    opts.read_buffer_size = opts.read_buffer_size or 50000
    opts.listed = opts.listed or false
    opts.scratch = opts.scratch or true

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
        vim.api.nvim_buf_set_option(self.id, k, v)
    end
    self.bo = bo

    vim.api.nvim_buf_set_option(self.id, "modifiable", false)
    vim.api.nvim_buf_set_option(self.id, "undolevels", -1)
    vim.api.nvim_buf_set_option(self.id, "undofile", false)

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

        vim.api.nvim_buf_set_option(self.id, "modifiable", true)
        vim.api.nvim_buf_set_lines(self.id, num_lines, -1, false, lines)
        vim.api.nvim_buf_set_option(self.id, "modifiable", false)

        num_lines = num_lines + #lines - 1
        last_line = lines[#lines]
    end

    vim.api.nvim_buf_set_option(self.id, "undolevels", self.bo.undolevels or vim.go.undolevels)
    vim.api.nvim_buf_set_option(self.id, "modified", false)
    vim.api.nvim_buf_set_option(self.id, "modifiable", self.bo.modifiable)
end

function M:on_wipeout() end

return M
