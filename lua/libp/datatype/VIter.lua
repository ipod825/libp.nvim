--- Module: **libp.datatype.VIter**
--
-- Value type iterator.
--
-- An implementation of @{Iter} interface. The @{next} and @{collect} function
-- returns the value(s) type of the underlying container or generator function.
--
-- Inherits: @{Iter}
-- @classmod VIter
local M = require("libp.datatype.Iter"):EXTEND()
local functional = require("libp.functional")

--- Returns the value type of the **kv iterable** (see @{Iter}) and moves the iterator to the next position.
-- This function is triggered by the `__call` operator and is thus for-loop
-- compatible. However, users can also calls it explicitly to get just the next
-- result.
-- @treturn any
-- @usage
-- local sum = 0
-- for v in VIter({ 1, 2, 3 }) do
--     sum = sum + v
-- end
-- assert(sum == 6)
-- @usage
-- local iter = VIter({ a = 1, b = 2 })
-- assert(iter:next() == 1)
-- assert(iter:next() == 2)
-- assert(iter:next() == nil)
function M:next()
    local val
    self.control, val = self.next_fn(self.invariant, self.control)
    return val
end

--- Returns an array hosting the results of @{next} calls (until it returns
-- nil).
-- @treturn array
-- @usage
-- assert.are.same({ 1, 2 }, VIter({ a = 1, b = 2 }):collect())
function M:collect()
    local res = {}
    for _, v in self:pairs() do
        res[#res + 1] = v
    end
    return require("libp.datatype.List")(res)
end

--- Folds every element into an accumulator by applying an operation, returning
--the final result.
-- @treturn VIter
-- @usage
-- assert.are.same({ 1, 3, 6, 10 }, VIter({ 1, 2, 3, 4 }):fold(0, functional.binary_op.add):collect())
function M:fold(init, op)
    local acc = init
    return self:map(function(v)
        if v then
            acc = op(acc, v)
            return acc
        end
    end)
end

--- Consumes the iterator, returning the last element.
-- @treturn any The last element
-- @usage
-- assert.are.same(4, VIter({ 1, 2, 3, 4 }):last())
function M:last()
    local res
    for v in self:fold(nil, functional.binary_op.second) do
        res = v
    end
    return res
end

return M
