--- Module: **libp.iter.Iter**
--
-- Iterator interface for **kv iterable**: key/value containers (array and
-- table) or generator functions that returns key/value pairs.
--
-- The iterator class enables user to create operation chains on **kv iterable**:
--    assert.are.same(
--        { 4, 8 },
--        V({ 1, 2, 3, 4 }):filter(function(v)
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
--    -- iter.values is equivalent to V
--    for v in iter.values({ 1, 2, 3 }) do
--    end
--
-- In practice, use the two derived class @{V} and @{KV} as @{Iter} itself
-- is not for-loop compatible. Both @{V} and @{KV} works with **kv
-- iterable**. The difference is their return types for @{Iter:next} and
-- @{Iter.collect}. @{V} returns
-- the value types of the iterable and @{KV} returns the key/value pairs.
--
-- @{Iter} can also be constructed from a generator function whose return values
-- should be key/value pairs. @{libp.iter.range} is a good example for this.
--
-- Inherits: @{Class}
-- @classmod Iter
local args = require("libp.args")
local functional = require("libp.functional")

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
-- function and decide the return types. For e.g., @{V:next} returns a
-- single value and @{KV:next} returns two values. This function is
-- triggered by the `__call` operator and is thus for-loop compatible. However,
-- users can also calls it explicitly to get just the next result.
-- @treturn any
-- @usage
-- for i, v in KV({ 1, 2, 3 }) do
--     assert(i == v)
-- end
-- @usage
-- local iter = V({ 1, 2 })
-- assert(iter:next() == 1)
-- assert(iter:next() == 2)
-- assert(iter:next() == nil)
function M:next()
    local val
    self.control, val = self.next_fn(self.invariant, self.control)
    return self:_select_entry(self.control, val)
end

-- Given key, value. Returns one or two values that map & filter takes.
function M:_select_entry(_, _)
    assert(false, "Must be implemented by child")
end

-- Given the map result (k, v). Returns the outputs of next_fn.
function M:_map_res_to_next_fn_output(_, _)
    assert(false, "Must be implemented by child")
end

-- Given key, value. Returns one single table or value representing the entry.
function M:_pack_entry(_, _)
    assert(false, "Must be implemented by child")
end

--- Returns a container hosting the results of @{next} calls (until it returns
-- nil). The return type is decided by the derived iterator class. For e.g.,
-- @{V} returns an array and @{KV} returns a table.
-- @treturn array|table
-- @usage
-- assert.are.same({ 1, 2, 3 }, V({ 1, 2, 3 }):collect())
function M:collect()
    assert(false, "Must be implemented by child")
end

--- Returns the generic for (next function, invariant, control) tuple.
-- This function is probably only of interest to derived class of @{Iter}.
-- @treturn function,table|nil,any
function M:pairs()
    return self.next_fn, self.invariant, self.control
end

-- Returns the number of elements from the iterator.
-- @treturn number
-- @usage
-- assert.are.same(3, V({ 1, 2, 3 }):count())
function M:count()
    local res = 0
    for _ in self:pairs() do
        res = res + 1
    end
    return res
end

--- Returns a new iterator that repeats indefinitely.
-- @treturn Iter
-- @usage
-- local iter = V({ 1 }):cycle()
-- assert.are.same(1, iter:next())
-- assert.are.same(1, iter:next())
function M:cycle()
    return self:CLASS()(nil, function()
        local v
        self.control, v = self.next_fn(self.invariant, self.control)
        if not self.control then
            self.control, v = self.next_fn(self.invariant, self.control)
        end
        return self.control, v
    end)
end

--- Returns a new iterator that takes only the first n elements.
-- @treturn Iter
-- @usage
-- assert.are.same({ 1, 2 }, V({ 1, 2, 3 }):take(2):collect())
function M:take(n)
    vim.validate({
        n = args.positive(n),
    })
    local count = 0
    return self:CLASS()(nil, function()
        if count == n then
            return
        end
        local v
        count = count + 1
        self.control, v = self.next_fn(self.invariant, self.control)
        return self.control, v
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
--     V({ 1, 2 }):map(function(v)
--         return 2 * v
--     end):collect()
-- )
function M:map(map_fn)
    vim.validate({ map_fn = { map_fn, "f" } })
    -- Note that the next_fn of the returned iterator actually doesn't use its
    -- arguments (invariant and control). Therefore, if we have a long chain of
    -- map/filter, only the control of the original iterator (first level) is
    -- really keeping track of the progress even though we update each level's
    -- control below. That is also why we don't pass the invariant and control
    -- argument for the new iterator as they are generator function driven
    -- instead of invariant position driven. Also note that self here refers to
    -- the original iterator, i.e., the previous level of the returned iterator.
    -- We use self:CLASS to have the returned iterator to be of the same class
    -- as the previous iterator.
    return self:CLASS()(nil, function()
        local k, v
        self.control, v = self.next_fn(self.invariant, self.control)
        if self.control then
            k, v = map_fn(self:_select_entry(self.control, v))
            return self:_map_res_to_next_fn_output(k, v)
        end
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
--     V({ 1, 2, 3 }):filter(function(v)
--         return v % 2 ~= 0
--     end):collect()
-- )
function M:filter(filter_fn)
    vim.validate({ filter_fn = { filter_fn, "f" } })
    -- See map for logic explanation.
    return self:CLASS()(nil, function()
        repeat
            local v
            self.control, v = self.next_fn(self.invariant, self.control)
            if self.control and filter_fn(self:_select_entry(self.control, v)) then
                return self.control, v
            end
        until not self.control
    end)
end

--- Consumes the iterator, returning the last element.
-- @treturn any The last element
-- @usage
-- assert.are.same(4, V({ 1, 2, 3, 4 }):last())
-- assert.are.same({ 4, 4 }, KV({ 1, 2, 3, 4 }):last())
function M:last()
    return self:fold(nil, functional.binary_op.second)
end

--- Folds every element into an accumulator by applying an operation, returning
-- the final result.
-- @treturn any
-- @usage
-- assert.are.same(10, V({ 1, 2, 3, 4 }):fold(0, functional.binary_op.add))
-- assert.are.same(
--     { 10, 10 },
--     KV({ 1, 2, 3, 4 }):fold({ 0, 0 }, function(acc, curr)
--         acc[1] = acc[1] + curr[1]
--         acc[2] = acc[2] + curr[2]
--         return acc
--     end)
-- )
function M:fold(init, op)
    local acc = init
    for k, v in self:pairs() do
        local entry = self:_pack_entry(k, v)
        acc = op(acc, entry)
    end
    return acc
end

return M
