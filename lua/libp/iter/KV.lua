--- Module: **libp.iter.KV**
--
-- Value type iterator.
--
-- An implementation of the @{Iter} interface iterating over the key/value
-- pair(s) of the underlying container or generator function.
--
-- Inherits: @{Iter}
-- @classmod KV
local M = require("libp.iter.Iter"):EXTEND()

function M:_key_value_to_entry(k, v)
    return k, v
end

function M:_key_value_to_packed_entry(k, v)
    return { k, v }
end

function M:_entry_to_packed_entry(k, v)
    return { k, v }
end

function M:_packed_entry_to_key_value(entry)
    return entry[1], entry[2]
end

function M:_entry_to_next_fn_output(k, v)
    return k, v
end

function M:_packed_entry_to_next_fn_output(kv)
    return kv[1], kv[2]
end

function M:_make_entry_from_pairs(k, v)
    return { k, v }
end

--- Returns a table hosting the results of @{next} calls (until it returns nil).
-- @treturn table
-- @usage
-- assert.are.same({ a = 1, b = 2 }, KV({ a = 1, b = 2 }):collect())
function M:collect()
    local res = {}
    for k, v in self:pairs() do
        res[k] = v
    end
    return res
end

return M
