local M = {}
local args = require("libp.args")

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

function M.debounce(opts)
    vim.validate({
        body = { opts.body, "f" },
        wait_ms = args.positive(opts.wait_ms),
        first_wait_ms = args.null_or.positive(opts.first_wait_ms),
    })

    opts = vim.tbl_extend("keep", opts or {}, { first_wait_ms = 0 })

    local handle
    handle = function()
        if opts.body() then
            vim.defer_fn(handle, opts.wait_ms)
        end
    end
    vim.defer_fn(handle, opts.first_wait_ms)
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

function M.oneshot_if(f, check)
    vim.validate({ f = { f, "f" }, check = { check, "f" } })
    local counter = 1
    return function()
        if counter == 1 and check() then
            counter = counter + 1
            return f()
        end
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

M.binary_op = {
    add = function(a, b)
        return a + b
    end,
    sub = function(a, b)
        return a - b
    end,
    mult = function(a, b)
        return a * b
    end,
    div = function(a, b)
        return a / b
    end,
    first = function(a, _)
        return a
    end,
    second = function(_, b)
        return b
    end,
}

return M
