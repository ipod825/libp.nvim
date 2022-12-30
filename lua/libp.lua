local M = {}
local default_config = require("libp.default_config")

function M.setup(opts)
    opts = vim.tbl_deep_extend("force", default_config, opts or {})
    require("libp.integration.web_devicon").setup(opts.integration.web_devicon)
    require("libp.utils.term").setup(opts.utils.term)
end

return M
