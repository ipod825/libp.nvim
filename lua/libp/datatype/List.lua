--- List class for object-oriented programming and functional programming paradigm.
--
-- Inherits: @{Class}
-- @classmod List
local M = require("libp.datatype.Class"):EXTEND()

--- Constructor.
-- @tparam[opt={}] table lst initialization list.
-- @treturn List A new List
function M:NEW(lst)
    lst = lst or {}
    local obj = setmetatable(lst, self)
    self.__index = self
    return obj
end

--- Concatenation operator.
-- @within metamethods
-- @tparam List that Another List
-- @treturn List A new list consisting of the list with the elements of the new list appended
-- @usage assert.are.same({ 1, 2, 3 }, List({ 1, 2 }) + List({ 3 }))
function M:__add(that)
    local res = vim.deepcopy(self)
    vim.list_extend(res, that)
    return res
end

--- Appends an element to the List
-- @tparam any ele The element to be appended
-- @treturn List The list.
-- @usage assert.are.same({ 1, 2, 3 }, List({ 1, 2 }):append(3))
function M:append(ele)
    self[#self + 1] = ele
    return self
end

--- Extends the List with another List
-- @tparam table|List that The list to be appended.
-- @treturn List The list
-- @usage assert.are.same({ 1, 2, 3 }, List({ 1, 2 }):extend({ 3 }))
function M:extend(that)
    vim.list_extend(self, that)
    return self
end

--- Sorts the List in place.
-- @tparam any ... Forward to table.sort.
-- @treturn List The list
-- @usage
-- assert.are.same(
--     { 4, 3, 2, 1 },
--     List({ 1, 3, 2, 4 }):sort(function(a, b)
--         return b < a
--     end)
-- )
function M:sort(...)
    table.sort(self, ...)
    return self
end

--- Returns coroutine iterator over the elements.
-- @treturn function The iterator function
-- @usage
-- local i = 1
-- for v in List({ 1, 2 }):values() do
--     assert(i == v)
--     i = i + 1
-- end
function M:values()
    return coroutine.wrap(function()
        for _, e in ipairs(self) do
            coroutine.yield(e)
        end
    end)
end

--- Returns the generic for (index,value) tuple.
-- @return Generic for (index,value) tuple
-- @usage
-- for i, v in List({ 1, 2 }):enumerate() do
--     assert(i == v)
-- end
function M:enumerate()
    return next, self, nil
end

--- Returns @{IterList} of the list.
-- @treturn @{IterList} An IterList of the list
-- @usage
-- local IterList = require("libp.datatype.IterList")
-- assert(List:to_iter():IS(IterList))
function M:to_iter()
    return require("libp.datatype.IterList")({ next_fn = next, invariant = self })
end

--- Creates a list of all elements which match a function.
-- @tparam function(any)->boolean fn The filtering function
-- @treturn List A new filtered list
-- @usage
-- assert.are.same(
--     { 2, 4 },
--     List({ 1, 2, 3, 4 }):filter(function(e)
--         return e % 2 == 0
--     end)
-- )
function M:filter(fn)
    return self:to_iter():filter(fn):collect()
end

--- Creates a list that transforms elements with a function.
-- @tparam function(any)->any fn The mapping function
-- @treturn List A new transformed List
-- @usage
-- assert.are.same(
--     { 2, 4, 6, 8 },
--     List({ 1, 2, 3, 4 }):map(function(e)
--         return e * 2
--     end)
-- )
function M:map(fn)
    return self:to_iter():map(fn):collect()
end

--- Executes a function on each element of the list.
-- @tparam function(any)->nil fn The function to be executed
-- @treturn nil
-- @usage
-- local sum = 0
-- local indices = {}
-- List({ 1, 2, 3, 4 }):for_each(function(e, i)
--     sum = sum + e
--     table.insert(indices, i)
-- end)
-- assert.are.same(10, sum)
-- assert.are.same({ 1, 2, 3, 4 }, indices)
function M:for_each(fn)
    for i, e in ipairs(self) do
        fn(e, i)
    end
end

--- Returns the single element if the list contains only one element.
-- @treturn List|any The single element if the list contains a single element,
-- otherwise the list.
-- @usage assert.are.same("a", List({ "a" }):unbox_if_one())
function M:unbox_if_one()
    if #self == 1 then
        return self[1]
    end
    return self
end
return M
