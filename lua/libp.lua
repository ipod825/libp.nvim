local M = {}

function M.setup(opts)
    opts = vim.tbl_extend("keep", opts or {}, { integration = {  }, utils = { } })
    require("libp.integration.web_devicon").setup(opts.integration.web_devicon)
    -- require("libp.utils.term").setup(opts.utils.term)
end

return M
