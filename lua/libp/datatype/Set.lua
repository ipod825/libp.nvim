--- Module: **libp.datatype.Set**
--
-- Set class (kind of).
--
-- Note that unlike other datatype. Set defines no member function. The reason
-- is that there is no way for lua to distinguish between fields and functions
-- in a table. Therefore, there is always chance that a user put some string
-- into a Set that conflicts with a member function name. However, some
-- metamethods are provided as they are indexed differently than fields and
-- functions.
-- @classmod Set
local M = {}
local iter = require("libp.iter")
local values = require("libp.iter").values

local size_key = {}

local function is_set(e)
    return e[size_key] ~= nil
end

local SetMt = {}

--- Compares if two set have same elements.
-- @function Set:__eq
-- @tparam Set that Another set
-- @treturn boolean
-- @usage
-- assert(Set({ 1 }) == Set({ 1 }))
-- assert(Set({ 1 }) ~= Set({ 2 }))
function SetMt:__eq(that)
    vim.validate({
        that = {
            that,
            is_set,
        },
    })
    if #self ~= #that then
        return false
    end
    for k in pairs(self) do
        if not that[k] then
            return false
        end
    end
    return true
end

--- Creates a new set by removing (if present) elements in that set from the set.
-- @function Set:__sub
-- @tparam Set that Another set
-- @treturn Set A new set
-- @usage
-- local s1 = Set({ "a", "b", "c" })
-- local s2 = Set({ "b", "c", "d" })
-- assert.are.same(Set({ "a" }), s1 - s2)
-- assert.are.same(Set({ "d" }), s2 - s1)
function SetMt:__sub(that)
    vim.validate({
        that = {
            that,
            is_set,
        },
    })
    local res = M()
    for k in pairs(self) do
        if not M.has(that, k) then
            M.add(res, k)
        end
    end
    return res
end

--- Constructor.
-- Creates a new set containing the provided elements.
-- @function Set:__call
-- @tparam[opt={}] array elements
-- @treturn Set A new set
-- @usage
-- local s1 = Set({ "a", "b", "c" })
setmetatable(M, {
    __call = function(_, table)
        table = table or {}
        local obj = setmetatable({ [size_key] = 0 }, SetMt)
        for v in values(table) do
            M.add(obj, v)
        end
        return obj
    end,
})

--- Returns the size of the set.
-- @static
-- @tparam Set set The set
-- @treturn number
-- @usage
-- assert.are.same(3, Set.size(Set({ "a", "b", "c" })))
function M.size(set)
    vim.validate({
        set = {
            set,
            is_set,
        },
    })
    return set[size_key]
end

--- Returns if the set is empty.
-- @static
-- @tparam Set set The set
-- @treturn boolean
-- @usage
-- assert.are.same(true, Set.empty(Set()))
-- assert.are.same(false, Set.empty(Set({ 1 })))
function M.empty(set)
    vim.validate({
        set = {
            set,
            is_set,
        },
    })
    return M.size(set) == 0
end

function M._inc(set, s)
    set[size_key] = set[size_key] + s
end

function M._dec(set, s)
    set[size_key] = set[size_key] - s
end

--- Returns @{V} over the elements.
-- @static
-- @tparam Set set the set
-- @treturn V
-- @usage
-- local sum = 0
-- for v in Set.values(Set({ 1, 2 })) do
--     sum = sum + v
-- end
-- assert.are.same(3, sum)
function M.values(set)
    vim.validate({
        set = {
            set,
            is_set,
        },
    })
    return iter.KV(set):filter(function(k, _)
        return k ~= size_key
    end)
end

--- Returns if the set contains the element.
-- @static
-- @tparam Set set The set
-- @tparam any e The element
-- @treturn boolean
-- @usage
-- assert(Set.has(Set({ 1 }, 1)))
-- assert(not Set.has(Set({ 1 }, 2)))
function M.has(set, e)
    vim.validate({
        set = {
            set,
            is_set,
        },
    })
    return set[e] ~= nil
end

--- Adds the element to the set.
-- @static
-- @tparam Set set The set
-- @tparam any k The element to be added
-- @tparam[opt=true] any v Optional value for the key k. Default to true. Note
-- that v can not be nil. However, any other value (such as false) would add k
-- into the set.
-- @usage
-- local set = Set()
-- Set.add(set, 1)
-- assert(Set.has(1))
function M.add(set, k, v)
    vim.validate({
        set = {
            set,
            is_set,
        },
    })
    v = v or true
    assert(v ~= nil)
    if set[k] == nil then
        set[k] = v
        M._inc(set, 1)
    end
end

--- Remove the element from the set (if present).
-- @static
-- @tparam Set set The set
-- @tparam any k The element to be removed
-- @usage
-- local set = Set({1})
-- Set.remove(set, 1)
-- assert(Set.empty())
function M.remove(set, k)
    vim.validate({
        set = {
            set,
            is_set,
        },
    })
    if set[k] ~= nil then
        set[k] = nil
        M._dec(set, 1)
    end
end

--- Creates a new set that is the interaction of the input sets.
-- @static
-- @tparam Set first The set
-- @tparam Set second The set
-- @treturn Set The intersection set.
-- @usage
-- assert.are.same(Set({2}), Set.interaction(Set({1,2}), Set({2,3})))
function M.intersection(first, second)
    vim.validate({
        first = {
            first,
            is_set,
        },
        second = {
            second,
            is_set,
        },
    })
    local smaller = (#first < #second) and first or second
    local larger = (#first < #second) and second or first

    local res = {}
    for k in pairs(smaller) do
        if M.has(larger, k) then
            res[#res + 1] = k
        end
    end
    return M(res)
end

return M
