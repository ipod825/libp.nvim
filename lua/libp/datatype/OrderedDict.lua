--- Module: **libp.datatype.OrderedDict**
--
-- Dict class that keeps the key order as they were inserted.
--
-- Inherits: @{Class}
-- @classmod OrderedDict
local M = require("libp.datatype.Class"):EXTEND()
local iter = require("libp.iter")
local iter = require("libp.iter")
local values = require("libp.iter").values

--- Constructor.
-- @treturn OrderedDict A new OrderedDict
function M:NEW()
    local mt = { data = {}, key_arr = {} }
    mt.__index = function(_, key)
        return mt.data[key]
    end
    mt.__newindex = function(_, key, value)
        if value then
            if not mt.data[key] then
                table.insert(mt.key_arr, key)
            end
        else
            if mt.data[key] then
                local new_key_arr = {}
                for ori_key in values(mt.key_arr) do
                    if ori_key ~= key then
                        table.insert(new_key_arr, ori_key)
                    end
                end
                mt.key_arr = new_key_arr
            end
        end
        mt.data[key] = value
    end
    local obj = setmetatable({}, mt)
    return obj
end

--- Returns @{KV} over the key/value pairs.
-- @tparam OrderedDict d The OrderedDict instance
-- @treturn KV
-- @usage
-- local d = OrderedDict()
-- d.b = 1
-- d.a = 2
-- local iter = OrderedDict.pairs(d)
-- assert.are.same({ "b", 1 }, { iter:next() })
-- assert.are.same({ "a", 2 }, { iter:next() })
function M.pairs(d)
    local mt = getmetatable(d)
    assert(mt.key_arr)

    return iter.KV(mt.key_arr):map(function(_, v)
        return v, mt.data[v]
    end)
end

--- Returns @{V} over the keys.
-- @tparam OrderedDict d The OrderedDict instance
-- @treturn V
-- @usage
-- local d = OrderedDict()
-- d.b = 1
-- d.a = 2
-- local iter = OrderedDict.keys(d)
-- assert.are.same("b", iter:next())
-- assert.are.same("a", iter:next())
function M.keys(d)
    local mt = getmetatable(d)
    assert(mt.key_arr)

    return iter.V(mt.key_arr)
end

--- Returns @{V} over the keys.
-- @tparam OrderedDict d The OrderedDict instance
-- @treturn V
-- @usage
-- local d = OrderedDict()
-- d.b = 1
-- d.a = 2
-- local iter = OrderedDict.values(d)
-- assert.are.same(1, iter:next())
-- assert.are.same(2, iter:next())
function M.values(d)
    local mt = getmetatable(d)
    assert(mt.key_arr)

    return iter.V(mt.key_arr):map(function(v)
        return mt.data[v]
    end)
end

--- Returns the managed dict.
-- The returned dict does not maintain the key insertion key order. Also,
-- modifying the returned dict could make the maintained order stale. So make a
-- deep copy if that is desired.
-- @tparam OrderedDict d The OrderedDict instance
-- @treturn table
-- @usage
-- local d = OrderedDict()
-- d.b = 1
-- d.a = 2
-- assert.are.same({ a = 2, b = 1 }, OrderedDict.data(d))
function M.data(d)
    local mt = getmetatable(d)
    assert(mt.data)
    return mt.data
end

return M
