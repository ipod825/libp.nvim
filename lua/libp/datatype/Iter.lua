--- Module: **libp.datatype.Iter**
--
-- Iterator interface for **kv iterable**: key/value containers (array and
-- table) or generator functions that returns key/value pairs.
--
-- The iterator class enables user to create operation chains on **kv iterable**:
--    assert.are.same(
--        { 4, 8 },
--        VIter({ 1, 2, 3, 4 }):filter(function(v)
--            return v % 2 == 0
--        end):map(function(v)
--            return 2 * v
--        end):collect()
--    )
-- It also makes iterating values over container cleaner:
-- Instead of writing
--    for _, v in ipairs({ 1, 2, 3 }) do
--    end
-- One could write:
--    -- itertools.values is equivalent to VIter
--    for v in itertools.values({ 1, 2, 3 }) do
--    end
--
-- In practice, use the two derived class @{VIter} and @{KVIter} as @{Iter} itself
-- is not for-loop compatible. Both @{VIter} and @{KVIter} works with **kv
-- iterable**. The difference is their return types for @{Iter:next} and
-- @{Iter.collect}. @{VIter} returns
-- the value types of the iterable and @{KVIter} returns the key/value pairs.
--
-- @{Iter} can also be constructed from a generator function whose return values
-- should be key/value pairs. @{libp.datatype.itertools.range} is a good example for this.
--
-- Inherits: @{Class}
-- @classmod Iter
local M = require("libp.datatype.Class"):EXTEND({
    --- Calls @{Iter:next}.
    -- The `__call` metamethod makes `Iter`'s children classes compatible with
    -- for-loop.
    -- @function __call
    -- @treturn any
    __call = function(this, ...)
        return this:next(...)
    end,
})

--- Constructor.
-- @tparam array|table|nil invariant The underlying key/value container. If nil,
-- `next_fn` must be non nil.
-- @tparam[opt=nil] function(invariant,control)->next_control,value next_fn The
-- underlying generator function. If not provided, lua's built-in next function
-- is used to iterate over `invariant`. The signature of `next_fn` is:
--
-- * invariant: The container to iterate over. Can be nil in generator function case.
-- * control: The current iterator position. nil represents the pre-begin position.
-- * next_control: The next iterator position. nil represents the post-end position.
-- * value: The value at the current position (control).
--
-- @tparam[opt=nil] any control The beginning iterator position.
-- @treturn @{Iter}
function M:init(invariant, next_fn, control)
    vim.validate({
        next_fn = { next_fn, "f", true },
        invariant = { invariant, "t", true },
    })

    assert(next_fn or invariant, "next_fn and invariant can not both be nil")

    self.invariant = invariant
    self.next_fn = next_fn or next
    self.control = control
end

--- Returns the current result and moves the iterator to the next position. It
-- is not implemented in @{Iter}, the derived classes must implement this
-- function and decide the return types. For e.g., @{VIter:next} returns a
-- single value and @{KVIter:next} returns two values. This function is
-- triggered by the `__call` operator and is thus for-loop compatible. However,
-- users can also calls it explicitly to get just the next result.
-- @treturn any
-- @usage
-- for i, v in KIter({ 1, 2, 3 }) do
--     assert(i == v)
-- end
-- @usage
-- local iter = VIter({ 1, 2 })
-- assert(iter:next() == 1)
-- assert(iter:next() == 2)
-- assert(iter:next() == nil)
function M:next()
    assert(false, "Must be implemented by child")
end

--- Returns a container hosting the results of @{next} calls (until it returns
-- nil). The return type is decided by the derived iterator class. For e.g.,
-- @{VIter} returns an array and @{KVIter} returns a table.
-- @treturn array|table
-- @usage
-- assert.are.same({ 1, 2, 3 }, VIter({ 1, 2, 3 }):collect())
function M:collect()
    assert(false, "Must be implemented by child")
end

--- Returns the generic for (next function, invariant, control) tuple.
-- This function is probably only of interest to derived class of @{Iter}.
-- @treturn function,table|nil,any
function M:pairs()
    return self.next_fn, self.invariant, self.control
end

--- Returns a new iterator that transforms the key/value with a map function.
-- For example, if the original iterator returns `(k1, v1), (k2, v2)` ...
-- The mapped iterator will return `map_fn(k1, v1), map_fn(k2, v2)` ...
-- @tparam function(any,any)->any,any map_fn The map function.
-- @treturn Iter
-- @usage
-- -- { "a", "b" } is equivalent to { [1] = "a", [2] = "b" },
-- assert.are.same(
--     { a = 1, b = 2 },
--     KVIter({ "a", "b" }):mapkv(function(k, v)
--         return v, k
--     end):collect()
-- )
function M:mapkv(map_fn)
    vim.validate({ map_fn = { map_fn, "function" } })
    -- Note that the next_fn of the returned iterator actually doesn't use its
    -- arguments (invariant and control). Therefore, if we have a long chain of
    -- map/filter, only the control of the original iterator (first level) is
    -- really keeping track of the progress even though we update each level's
    -- control below. That is also why we don't pass the invariant and control
    -- argument for the new iterator as they are generator function driven
    -- instead of invariant position driven. Also note that self here refers to
    -- the original iterator, i.e., the previous level of the returned iterator.
    -- We use self:CLASS to have the returned iterator to be of the same class
    -- as the previous iterator. This ensures that next/collect behaves the same
    -- after iterator transformation.
    return self:CLASS()(nil, function()
        local v
        self.control, v = self.next_fn(self.invariant, self.control)
        if self.control then
            return map_fn(self.control, v)
        end
    end)
end

--- Returns a new iterator that transforms the value type with a map function.
-- For example, if the original iterator returns `(k1, v1), (k2, v2)` ...
-- The mapped iterator will return `(k1, map_fn(v1)), (k2, map_fn(v2))` ...
-- @tparam function(any)->any map_fn The map function.
-- @treturn Iter
-- @usage
-- assert.are.same(
--     { 2, 4 },
--     VIter({ 1, 2 }):map(function(v)
--         return 2 * v
--     end):collect()
-- )
function M:map(map_fn)
    vim.validate({ map_fn = { map_fn, "function" } })
    -- See comments in mapkv.
    return self:CLASS()(nil, function()
        local v
        self.control, v = self.next_fn(self.invariant, self.control)
        if self.control then
            return self.control, map_fn(v)
        end
    end)
end

--- Returns a new iterator that filters the key/value with a filter function.
-- For example, if the original iterator returns `(k1, v1), (k2, v2)` ...
-- The mapped iterator will return `(k2, v2)` ..., assuming that
-- `filter_fn(k1, v1)=false` and `filter_fn(k1, v1)=true`.
-- @tparam function(any,any)->boolean filter_fn The filter function.
-- @treturn Iter
-- @usage
-- assert.are.same(
--     { a = 1, c = 3 },
--     KVIter({ a = 1, b = 2, c = 3 }):filterkv(function(k, v)
--         return k == "a" or v == 3
--     end):collect()
-- )
function M:filterkv(filter_fn)
    vim.validate({ filter_fn = { filter_fn, "function" } })
    -- See comments in mapkv.
    return self:CLASS()(nil, function()
        repeat
            local v
            self.control, v = self.next_fn(self.invariant, self.control)
            if self.control and filter_fn(self.control, v) then
                return self.control, v
            end
        until not self.control
    end)
end

--- Returns a new iterator that filters the value type with a filter function.
-- For example, if the original iterator returns `(k1, v1), (k2, v2)` ...
-- The mapped iterator will return `(k2, v2)` ..., assuming that
-- `filter_fn(v1)=false` and `filter_fn(v1)=true`.
-- @tparam function(any)->boolean filter_fn The filter function.
-- @treturn Iter
-- @usage
-- assert.are.same(
--     { 1, 3 },
--     VIter({ 1, 2, 3 }):filter(function(v)
--         return v % 2 ~= 0
--     end):collect()
-- )
function M:filter(filter_fn)
    vim.validate({ filter_fn = { filter_fn, "function" } })
    -- See comments in mapkv.
    return self:CLASS()(nil, function()
        repeat
            local v
            self.control, v = self.next_fn(self.invariant, self.control)
            if self.control and filter_fn(v) then
                return self.control, v
            end
        until not self.control
    end)
end

return M
