local M = require("libp.datatype.Class"):EXTEND()
local a = require("plenary.async")
local uv = require("libp.fs.uv")

function M:init(filename, opts)
    vim.validate({ filename = { filename, "s" }, opts = { opts, "t", true } })
    opts = opts or {}
    opts.read_bytes = opts.read_bytes or 50000
    opts.listed = opts.listed or true
    opts.scratch = opts.scratch or false

    if vim.fn.bufexists(filename) > 0 then
        self.id = vim.fn.bufadd(filename)
        return self.id
    end

    self.id = vim.api.nvim_create_buf(true, false)

    vim.api.nvim_buf_set_option(self.id, "modifiable", false)
    vim.api.nvim_buf_set_option(self.id, "undolevels", -1)
    vim.api.nvim_buf_set_option(self.id, "undofile", false)

    local fd, stat, err
    fd, err = uv.fs_open(filename, "r", 448)
    assert(not err, err)
    stat, err = uv.fs_fstat(fd)
    assert(not err, err)

    -- Remove last newline by reading one less byte.
    local remain_size = stat.size - 1

    local last_line = ""
    local offset = 0
    local num_lines = 0
    while remain_size > 0 do
        local content, _ = uv.fs_read(fd, math.min(remain_size, opts.read_bytes), offset)
        offset = offset + opts.read_bytes
        remain_size = remain_size - opts.read_bytes
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

    vim.api.nvim_buf_set_name(self.id, filename)
    vim.api.nvim_buf_set_option(self.id, "undolevels", vim.api.nvim_get_option("undolevels"))
    vim.api.nvim_buf_set_option(self.id, "modified", false)
    vim.api.nvim_buf_set_option(self.id, "modifiable", true)

    -- nvim_buf_set_name only associates the buffer with the filename. On
    -- first write, E13 (file exists) happens. The workaround here just
    -- force wrintg the file (or do it on next bufer enter). This can be
    -- improved when there's an API for writing a buffer to a file that
    -- takes a buf id.
    local associate_file = function()
        vim.api.nvim_command("silent! w!")
        vim.api.nvim_buf_set_option(self.id, "undofile", vim.o.undofile)
    end
    if vim.api.nvim_get_current_buf() == self.id then
        associate_file()
    else
        vim.api.nvim_create_autocmd("BufEnter", {
            buffer = self.id,
            once = true,
            callback = associate_file,
        })
    end
end

function M:on_wipeout() end

return M
