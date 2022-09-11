local M = {}
local path = require("libp.path")
local fs = require("libp.fs")
local values = require("libp.itertools").values

function M.is_in_path(target)
    for p in values(vim.split(os.getenv("PATH"), ":")) do
        if fs.is_executable(path.join(p, target)) then
            return true
        end
    end
    return false
end

return M
