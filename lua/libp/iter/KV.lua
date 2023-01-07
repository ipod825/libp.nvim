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

function M:_select_entry(k, v)
    return k, v
end

function M:_map_res_to_next_fn_output(k, v)
    return k, v
end

function M:_pack_entry(k, v)
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
