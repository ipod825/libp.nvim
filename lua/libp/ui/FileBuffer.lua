--- Module: **libp.ui.FileBuffer**
--
-- FileBuffer class. Loading file content to vim buffer asynchronously. There's
-- also @{FilePreviewBuffer} that does not allow modification to buffer content.
-- Both @{FilePreviewBuffer} and @{FileBuffer} exists for loading file content into
-- a floating @{Window} asynchronously:
--
--     local ui = require("libp.ui")
--     require("plenary.async").void(function()
--         local buf = ui.FileBuffer("file_to_load")
--         local win = ui.Window(buf)
--         win:open()
--     end)()
--
-- Inherits: @{FilePreviewBuffer}
-- @classmod FileBuffer
local M = require("libp.ui.FilePreviewBuffer"):EXTEND()
local uv = require("libp.fs.uv")
local args = require("libp.args")

--- Constructor.
-- @tparam string filename The file name to load content from.
-- @tparam table opts see @{FilePreviewBuffer:init} for inherited options. The
-- following arguments have default values.
-- @tparam[opt=true] boolean opts.listed
-- @tparam[opt=false] boolean opts.scratch
function M:init(filename, opts)
    if vim.fn.bufexists(filename) > 0 then
        self.id = vim.fn.bufadd(filename)
        return
    end

    -- For file smaller than 10Mb, use bufadd instead of async file loading
    -- implemented in FilePreviewBuffer, which would make the shada location
    -- information lost.
    local stat, err = uv.fs_stat(filename)
    if err or stat.size < 10485760 then
        self.id = vim.fn.bufadd(filename)
        return
    end

    opts = opts or {}
    opts.bo =
    vim.tbl_extend("force", opts.bo or {}, { bufhidden = vim.o.hidden and "hide" or "unload", modifiable = true })
    opts.listed = args.get_default(opts.listed, true)
    opts.scratch = args.get_default(opts.scratch, false)

    self:SUPER():init(filename, opts)

    vim.api.nvim_buf_set_name(self.id, filename)
    -- nvim_buf_set_name only associates the buffer with the filename. On
    -- first write, E13 (file exists) happens. The workaround here just
    -- force wrintg the file (or do it on next bufer enter). This can be
    -- improved when there's an API for writing a buffer to a file that
    -- takes a buf id.
    local associate_file = function()
        vim.api.nvim_command("silent! w!")
        vim.bo[self.id].undofile = vim.go.undofile
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
