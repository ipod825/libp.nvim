--- Module: **libp.datatype.OrderedDict**
--
-- Dict class that keeps the key order as they were inserted.
--
-- Inherits: @{Class}
-- @classmod OrderedDict
local M = require("libp.datatype.Class"):EXTEND()

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
                for _, ori_key in ipairs(mt.key_arr) do
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

--- Returns iterator (key, value) over the elements.
-- @treturn function
-- @usage
-- local d = OrderedDict()
-- d.b = 1
-- d.a = 2
-- local next = OrderedDict.enumerate(d)
-- assert.are.same({ "b", 1 }, { next() })
-- assert.are.same({ "a", 2 }, { next() })
function M.enumerate(d)
    local mt = getmetatable(d)
    assert(mt.key_arr)

    local next_key
    return function()
        local data_key
        next_key, data_key = next(mt.key_arr, next_key)
        return data_key, mt.data[data_key]
    end
end

function M.keys(d)
    local mt = getmetatable(d)
    assert(mt.key_arr)

    local next_key = nil
    return function()
        local data_key
        next_key, data_key = next(mt.key_arr, next_key)
        return data_key
    end
end

function M.values(d)
    local mt = getmetatable(d)
    assert(mt.key_arr)

    local next_key = nil
    return function()
        local data_key
        next_key, data_key = next(mt.key_arr, next_key)
        return mt.data[data_key]
    end
end

function M.data(d)
    local mt = getmetatable(d)
    assert(mt.data)
    return mt.data
end

return M
