local M = require("libp.ui.Buffer"):EXTEND()
local term = require("libp.utils.term")
local List = require("libp.datatype.List")

function M:init(opts)
    opts = vim.tbl_extend("force", opts or {}, {
        content_highlight_fn = function(beg, _, lines, ctx)
            if beg == 0 then
                ctx.highlight_attributes = nil
            end
            return term.get_ansi_code_highlight(lines, ctx.highlight_attributes)
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
