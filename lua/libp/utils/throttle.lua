local functional = require("libp.functional")
local M = {}

-- Returns a function that invokes `fn` at most `rate_limit`/sec. The return
-- value of the function indicates whether `fn` was invoked or not. If invoked,
-- the return values of `fn` are appended as varargs.
function M.max_per_second(rate_limit, fn)
    vim.validate({ rate_limit = { rate_limit, "n", true }, fn = { fn, "f", true } })
    rate_limit = rate_limit or 1
    fn = fn or functional.nop
    local current_tokens = rate_limit
    local last_check = os.time()

    return function(...)
        local current_time = os.time()
        local time_elapsed = current_time - last_check
        last_check = current_time

        -- Increase the current number of tokens by the amount of time that has passed since the last check
        current_tokens = math.min(rate_limit, current_tokens + time_elapsed)

        -- Check if there are enough tokens to allow the action to be performed
        if current_tokens > 0 then
            current_tokens = current_tokens - 1
            return true, fn(...)
        else
            return false
        end
    end
end

function M.delay_call_last(wait_ms, fn)
    vim.validate({ wait_ms = { wait_ms, "n" }, fn = { fn, "f" } })
    local counter = 0

    return function(...)
        counter = counter + 1
        local call_index = counter
        local args = { ... }
        vim.defer_fn(function()
            if call_index == counter then
                counter = 0
                fn(unpack(args))
            end
        end, wait_ms)
    end
end

return M
