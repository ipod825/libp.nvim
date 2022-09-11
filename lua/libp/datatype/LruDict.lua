local M = require("libp.datatype.Class"):EXTEND()
local DoubleLinkList = require("libp.datatype.DoubleLinkList")

function M:init(capacity)
    self.capacity = capacity or 100
    self.lst = DoubleLinkList()
    self.key_to_node = {}
    self.size = 0
end

function M:NEW(capacity)
    local mt = {
        capacity = capacity or 100,
        lst = DoubleLinkList(),
        key_to_node = {},
        size = 0,
    }
    mt.__index = function(_, key)
        return mt.key_to_node[key] and mt.key_to_node[key].val
    end
    mt.__newindex = function(_, key, value)
        if value then
            M._set(mt, key, value)
        else
            M._remove(mt, key)
        end
    end
    return setmetatable({}, mt)
end

function M._remove(lru, key)
    local node = lru.key_to_node[key]
    if not node then
        return
    end

    lru.key_to_node[key] = nil
    lru.lst:remove(node)
end

function M._set(lru, key, val)
    if not key then
        return
    end
    local node = lru.key_to_node[key]
    if node then
        lru.lst:splice(lru.lst.head, lru.lst, node)
        lru.key_to_node[key].val = val
    else
        lru.key_to_node[key] = lru.lst:push_front(val)
        lru.size = lru.size + 1
    end

    if lru.size > lru.capacity then
        lru.key_to_node[lru.lst:pop_back().val] = nil
        lru.size = lru.size - 1
    end
end

function M.values(lru)
    return getmetatable(lru).lst:to_list()
end

function M.top(lru)
    local mt = getmetatable(lru)
    return mt.lst.head and mt.lst.head.val
end

return M
