--- Module: **libp.datatype.Stack**
--
-- Stack class.
--
-- Inherits: @{Class}
-- @classmod Stack
local M = require("libp.datatype.Class"):EXTEND()

--- Constructor.
-- @tparam[opt={}] table lst Initialization list.
-- @treturn Stack A new Stack
function M:NEW(lst)
    lst = lst or {}
    local obj = setmetatable(lst, self)
    self.__index = self
    return obj
end

--- Pushes an element to the top.
-- @tparam any ele The element to be pushed
-- @usage assert.are.same({ 1, 2, 3 }, Stack({ 1, 2 }):push(3))
function M:push(ele)
    self[#self + 1] = ele
end

--- Pops an element from the top.
-- @treturn any|nil The element on top or nil if empty
-- @usage assert.are.same(1, Stack({ 1 }):pop())
function M:pop()
    local res = self[#self]
    self[#self] = nil
    return res
end

--- Returns the top element.
-- @treturn any|nil The element on top or nil if empty
-- @usage assert.are.same(1, Stack({ 1 }):top())
function M:top()
    return self[#self]
end

--- Returns the size of the stack.
-- @treturn number
-- @usage assert.are.same(1, Stack({ 'a' }):size())
function M:size()
    return #self
end

--- Returns if the stack is empty.
-- @treturn boolean
-- @usage
-- assert.are.same(true, Stack():empty())
-- assert.are.same(false, Stack({ 1 }):empty())
function M:empty()
    return #self == 0
end

return M
