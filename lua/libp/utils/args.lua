local M = {}

function M.get_default(val, default)
    if val == nil then
        return default
    else
        return val
    end
end

return M
