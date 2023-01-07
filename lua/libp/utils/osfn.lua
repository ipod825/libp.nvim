local M = {}
local pathfn = require("libp.utils.pathfn")
local fs = require("libp.fs")
local values = require("libp.iter").values

function M.is_in_path(target)
    for p in values(vim.split(os.getenv("PATH"), ":")) do
        if fs.is_executable(pathfn.join(p, target)) then
            return true
        end
    end
    return false
end

return M
