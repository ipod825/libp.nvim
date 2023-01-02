local M = {
    get_ansi_code_highlight = require("libp.utils.term.highlight").get_ansi_code_highlight,
}

function M.setup(opts)
    require("libp.utils.term.highlight").setup(opts)
end

function M.remove_ansi_escape(str)
    return str:gsub("%c+%[[%d;]*m", "")
end

return M
