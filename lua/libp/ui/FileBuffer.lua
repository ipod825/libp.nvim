local M = require("libp.ui.FilePreviewBuffer"):EXTEND()
local uv = require("libp.fs.uv")

function M:init(filename, opts)
    if vim.fn.bufexists(filename) > 0 then
        self.id = vim.fn.bufadd(filename)
        return self.id
    end

    -- For file smaller than 10Mb, use bufadd instead of async file loading
    -- implemented in FilePreviewBuffer, which would make the shada location
    -- information lost.
    local stat, err = uv.fs_stat(filename)
    if err then
        return
    elseif stat.size < 10485760 then
        self.id = vim.fn.bufadd(filename)
        return self.id
    end

    opts = opts or {}
    opts.bo = vim.tbl_extend("force", opts.bo or {}, { bufhidden = vim.o.hidden and "hide" or "unload", modifiable = true })
    opts.listed = true
    opts.scratch = false

    self:SUPER():init(filename, opts)

    vim.api.nvim_buf_set_name(self.id, filename)
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

return M
