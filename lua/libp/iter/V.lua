--- Module: **libp.iter.V**
--
-- Value type iterator.
--
-- An implementation of @{Iter} interface. The @{next} and @{collect} function
-- returns the value(s) type of the underlying container or generator function.
--
-- Inherits: @{Iter}
-- @classmod V
local M = require("libp.iter.Iter"):EXTEND()

--- Returns the value type of the **kv iterable** (see @{Iter}) and moves the iterator to the next position.
-- This function is triggered by the `__call` operator and is thus for-loop
-- compatible. However, users can also calls it explicitly to get just the next
-- result.
-- @treturn any
-- @usage
-- local sum = 0
-- for v in V({ 1, 2, 3 }) do
--     sum = sum + v
-- end
-- assert(sum == 6)
-- @usage
-- local iter = V({ a = 1, b = 2 })
-- assert(iter:next() == 1)
-- assert(iter:next() == 2)
-- assert(iter:next() == nil)
function M:_select_entry(_, v)
    return v
end

function M:_map_res_to_next_fn_output(v, _)
    return self.control, v
end

function M:_pack_entry(v, _)
    return v
end

--- Returns an array hosting the results of @{next} calls (until it returns
-- nil).
-- @treturn array
-- @usage
-- assert.are.same({ 1, 2 }, V({ a = 1, b = 2 }):collect())
function M:collect()
    local res = {}
    for _, v in self:pairs() do
        res[#res + 1] = v
    end
    return require("libp.datatype.List")(res)
end

return M
