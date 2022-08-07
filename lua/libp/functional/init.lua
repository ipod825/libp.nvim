local M = {}

function M.nop(...) end

function M.identity(e)
    return e
end

local bind_tbl = require("libp.functional.bind_tbl")
function M.bind(fn, ...)
    local argc = select("#", ...)
    assert(argc > 0 and argc < #bind_tbl, "bind supports args between 1 and " .. #bind_tbl)
    return bind_tbl[argc](fn, ...)
end

function M.oneshot(f, at_counter)
    local counter = 1
    at_counter = at_counter or 1
    return function()
        if counter == at_counter then
            counter = counter + 1
            return f()
        end
        counter = counter + 1
    end
end

function M.head_tail(arr)
    assert(vim.tbl_islist(arr))
    if #arr == 0 then
        return nil, nil
    elseif #arr == 1 then
        return arr[1], nil
    else
        return arr[1], vim.list_slice(arr, 2)
    end
end

return M
