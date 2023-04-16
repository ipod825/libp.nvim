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

function M:_key_value_to_entry(_, v)
    return v
end

function M:_key_value_to_packed_entry(_, v)
    return v
end

function M:_entry_to_packed_entry(v)
    return v
end

function M:_entry_to_next_fn_output(v, _)
    return self._control, v
end

function M:_packed_entry_to_next_fn_output(v)
    return self._control, v
end

function M:_make_entry_from_pairs(v, _)
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
