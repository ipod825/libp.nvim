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

function M.non_nil(e)
    return {
        e,
        function()
            return e ~= nil
        end,
        "non-nil",
    }
end

function M.positive(e)
    return {
        e,
        function()
            return type(e) == "number" and e > 0
        end,
        "positive number",
    }
end

function M.is_class(e, Cls, cls_name)
    return {
        e,
        function()
            return e.IS and e:IS(Cls)
        end,
        cls_name,
    }
end

function M.is_callable(e)
    return {
        e,
        function()
            return vim.is_callable(e)
        end,
        "callable",
    }
end

M.null_or = {}
local function add_null_or_fn(name, fn)
    M.null_or[name] = function(e)
        local ori_result = fn(e)
        local ori_check = ori_result[2]
        ori_result[2] = function()
            return not e or ori_check(e)
        end
        return ori_result
    end
end

add_null_or_fn("positive", M.positive)
add_null_or_fn("is_callable", M.is_callable)

return M
