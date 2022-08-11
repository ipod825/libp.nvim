--- Module: **libp.datatype.KVIter**
--
-- Value type iterator.
--
-- An implementation of the @{Iter} interface iterating over the key/value
-- pair(s) of the underlying container or generator function.
--
-- Inherits: @{Iter}
-- @classmod KVIter
local M = require("libp.datatype.Iter"):EXTEND()

--- Returns the key/value pair of the **kv iterable** (see @{Iter}) and moves
-- the iterator to the next position. This function is triggered by the `__call`
-- operator and is thus for-loop compatible. However, users can also calls it
-- explicitly to get just the next result.
-- @usage
-- for i, v in KVIter({ 1, 2, 3 }) do
--     assert(i == v)
-- end
-- @usage
-- local iter = KVIter({ a = 1, b = 2 })
-- assert.are.same({ "a", 1 }, { iter:next() })
-- assert.are.same({ "b", 2 }, { iter:next() })
-- assert(iter:next() == nil)
function M:next()
    local val
    self.control, val = self.next_fn(self.invariant, self.control)
    return self.control, val
end

--- Returns a table hosting the results of @{next} calls (until it returns nil).
-- @treturn table
-- @usage
-- assert.are.same({ a = 1, b = 2 }, KVIter({ a = 1, b = 2 }):collect())
function M:collect()
    local res = {}
    for k, v in self:pairs() do
        res[k] = v
    end
    return res
end

return M
