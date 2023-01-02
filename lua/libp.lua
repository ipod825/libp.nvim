local M = {}
local default_config = require("libp.default_config")

function M.setup(opts)
    opts = vim.tbl_deep_extend("force", default_config, opts or {})
    require("libp.integration.web_devicon").setup(opts.integration.web_devicon)
    require("libp.utils.term").setup(opts.utils.term)
    M.define_highlights(opts)
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("libp_define_highlight", {}),
        callback = function()
            M.define_highlights(opts)
        end,
    })
end

function M.define_highlights(opts)
    for group, color in pairs(opts.highlights) do
        vim.api.nvim_set_hl(0, group, color)
    end
end

function M.check_setup(numargs, ...)
    local args = { ... }
    assert(#args == numargs, "Internal error: arg number mismatch " .. debug.traceback())

    for i = 1, #args do
        if args[i] == nil then
            assert(false, "libp was not setup properly. Forget to add require'libp'.setup() in your config?")
        end
    end
end

return M
