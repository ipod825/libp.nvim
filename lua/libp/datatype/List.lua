--- Module: **libp.datatype.List**
--
-- List class. Supports slicing/append/map/filter, etc.
--
-- Inherits: @{Class}
-- @classmod List
local M
M = require("libp.datatype.Class"):EXTEND({
    --- Returns a slice of the original list.
    -- @function __index
    -- @tparam array indices The indices of the slice, both inclusive. The first
    -- element is the begin of the slice and the second is the end of the slice. If
    -- first is nil, then it defaults to 1. If the second is nil, then it defaults
    -- to the length of the array.
    -- @treturn List A new List
    -- @usage
    -- local lst = List({ 1, 2, 3, 4 })
    -- assert.are.same(2, lst[2])
    -- assert.are.same({ 2, 3, 4 }, lst[{ 2 }])
    -- assert.are.same({ 2, 3 }, lst[{ 2, 3 }])
    -- assert.are.same({ 1, 2, 3 }, lst[{ nil, 3 }])
    __index = function(this, key)
        return type(key) == "table" and M(vim.list_slice(this, key[1], key[2])) or rawget(this, key) or M[key]
    end,
})
local iter = require("libp.iter")

--- Constructor.
-- @tparam[opt={}] array lst Initialization list.
-- @treturn List A new List
function M:NEW(lst)
    local obj = setmetatable(lst or {}, self)
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

--- Appends an element to the List.
-- @tparam any ele The element to be appended
-- @treturn List The list.
-- @usage assert.are.same({ 1, 2, 3 }, List({ 1, 2 }):append(3))
function M:append(ele)
    self[#self + 1] = ele
    return self
end

--- Extends the List with another List.
-- @tparam array|List that The list to be appended.
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

--- Creates a new list of all elements which match a function. Note that
--this is a short cut of `V(lst):filter(fn):collect()`. If chaining is
--necessary, better do that explicitly for performance concern.
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
    return iter.V(self):filter(fn):collect()
end

--- Creates a new list by transforming the elements with a function. Note that
--this is a short cut of `V(lst):map(fn):collect()`. If chaining is necessary,
--better do that explicitly for performance concern.
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
    return iter.V(self):map(fn):collect()
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
