local M = require("libp.datatype.Class"):EXTEND()
local DoubleLinkList = require("libp.datatype.DoubleLinkList")

function M:init(capacity)
    self.capacity = capacity or 100
    self.lst = DoubleLinkList()
    self.val_to_node = {}
    self.size = 0
end

function M:remove(target)
    local new_lru = M(self.capacity)
    for _, val in ipairs(self.lst:to_reverse_list()) do
        if val ~= target then
            new_lru:add(val)
        end
    end
    self.lst = new_lru.lst
    self.val_to_node = new_lru.val_to_node
    self.size = new_lru.size
end

function M:add(val)
    if not val then
        return
    end
    local node = self.val_to_node[val]
    if node then
        self.lst:splice(self.lst.head, self.lst, node)
    else
        self.val_to_node[val] = self.lst:push_front(val)
        self.size = self.size + 1
    end

    if self.size > self.capacity then
        self.val_to_node[self.lst:pop_back().val] = nil
        self.size = self.size - 1
    end
end

function M:unordered_values()
    return vim.tbl_keys(self.val_to_node)
end

function M:values()
    return self.lst:to_list()
end

function M:top()
    return #self.val_to_node > 0 and self.lst.head.val or nil
end

return M
