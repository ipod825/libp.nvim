local M = {}
local path = require("libp.path")
local fs = require("libp.fs")

function M.is_in_path(target)
    for _, p in ipairs(vim.split(os.getenv("PATH"), ":")) do
        if fs.is_executable(path.join(p, target)) then
            return true
        end
    end
    return false
end

return M
