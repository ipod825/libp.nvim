local M = {}

function M.get_default(val, default)
    if val == nil then
        return default
    else
        return val
    end
end

function M.get_default_lazy(val, default_fn, ...)
    if val == nil then
        return default_fn(...)
    else
        return val
    end
end

return M
