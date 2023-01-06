--- Module: **libp.ui.AnsiColorBuffer**
--
-- AnsiColorBuffer class. A specialized @{Buffer} that implements default highlighting function for ansi color in command outputs.
--
-- Inherits: @{Buffer}
-- @classmod AnsiColorBuffer
local M = require("libp.ui.Buffer"):EXTEND()
local term = require("libp.utils.term")
local List = require("libp.datatype.List")

--- Constructor.
-- @tparam table opts see @{Buffer:init}. The following arguments have default values:
-- @tparam[opt=500] number opts.job_on_stdout_buffer_size
-- @tparam[opt] function(buffer,beg,ends,lines,context)->table opts.content_highlight_fn
-- @tparam[opt] function({string})->string opts.content_map_fn
function M:init(opts)
    opts = vim.tbl_extend("keep", opts or {}, {
        -- For very long outputs, frequent calls to nvim_buf_add_highlight makes
        -- UI less responsible. Hence, we use a smaller batch size here.
        job_on_stdout_buffer_size = 500,
        content_highlight_fn = function(_, beg, _, lines, ctx)
            if beg == 0 then
                ctx.highlight_attributes = nil
            end
            local marks
            marks, ctx.highlight_attributes = term.get_ansi_code_highlight(lines, ctx.highlight_attributes, beg)
            return marks
        end,
        content_map_fn = function(lines)
            return List(lines):map(function(line)
                return line:gsub("%c+%[[%d;]*m", "")
            end)
        end,
    })
    self:SUPER():init(opts)
end

return M
