local M = setmetatable({}, {
    __index = function(_, key)
        if coroutine.running() then
            return require("libp.fs.uv_async")[key]
        else
            return vim.loop[key]
        end
    end,
})

return M
