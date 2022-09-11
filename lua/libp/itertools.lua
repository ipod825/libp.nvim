--- Useful functions related to @{Iter}
-- @module libp.datatype.itertools
local M = {}
local VIter = require("libp.datatype.VIter")

--- Returns a @{VIter} iterating through a range with some step.
-- @tparam number beg The begin of the range. If `ends` is omitted, begin becomes 1
-- and `ends` is set to the value of `beg`
-- @tparam[opt=beg] number ends The end of the range
-- @tparam[opt=1] number step The incremental on each iteration
-- @treturn @{VIter}
-- @usage
-- assert.are.same({ 1, 2, 3 }, itertools.range(3):collect())
-- assert.are.same({ 3, 2, 1 }, itertools.range(3, 1, -1):collect())
function M.range(beg, ends, step)
    vim.validate({ beg = { beg, "n" }, ends = { ends, "n", true }, step = { step, "n", true } })
    if not ends then
        ends = beg
        beg = 1
    end
    step = step or 1

    assert(step ~= 0, "step can not be zero")

    return VIter(nil, function(_, control)
        control = control or 0
        local res = beg + control * step
        if step > 0 then
            if res <= ends then
                return control + 1, res
            end
        else
            if res >= ends then
                return control + 1, res
            end
        end
    end)
end

--- Returns a @{VIter} iterating over the container values.
-- @tparam array|table invariant The container
-- @treturn @{VIter}
-- @usage
-- assert.are.same({ 1, 2 }, itertools.values({ a = 1, b = 2 }):collect())
function M.values(invariant)
    vim.validate({ invariant = { invariant, "t" } })
    return VIter(invariant)
end

--- Returns a @{VIter} iterating over the container keys.
-- @tparam array|table invariant The container
-- @treturn @{VIter}
-- @usage
-- assert.are.same({ 'a', 'b' }, itertools.keys({ a = 1, b = 2 }):collect())
function M.keys(invariant)
    vim.validate({ invariant = { invariant, "t" } })
    return VIter(invariant):mapkv(function(k, v)
        return v, k
    end)
end

return M
