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

return M
