local functional = require("libp.functional")
local M = {}

-- Returns a function that invokes `fn` at most `rate_limit`/sec. The return
-- value of the function indicates whether `fn` was invoked or not. If invoked,
-- the return values of `fn` are appended as varargs.
function M.max_per_second(rate_limit, fn)
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

return M
