local M = {}

function M.setup(opts)
    require("libp.integration.web_devicon").setup(opts.web_devicons)
end

return M
