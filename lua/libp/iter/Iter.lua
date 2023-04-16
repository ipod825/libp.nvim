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
--    assert.are.same(
--        { [1] = 2, [3] = 6 },
--        KV({ 1, 2, 3 })
--            :map(function(k, v)
--                return k, v * 2
--            end)
--            :filter(function(k, v)
--                return v % 4 ~= 0
--            end)
--            :collect()
--    )
-- It also makes iterating values over container cleaner:
-- Instead of writing
--    for _, v in ipairs({ 1, 2, 3 }) do
--    end
-- One could write:
--    -- iter.values is equivalent to iter.V
--    for v in iter.values({ 1, 2, 3 }) do
--    end
--
-- In practice, use the two derived class @{V} and @{KV}. @{Iter} itself
-- is not complete and relies on child classes to implement certain functions. Both @{V} and @{KV} works with **kv
-- iterable**. The difference is their signatures on @{Iter} APIs. Roughly speaking, @{V} returns
-- the value types of the iterable and @{KV} returns the key/value pairs. See usages below for signatures of each function.
--
-- @{Iter} can also be constructed from a generator function. For e.g., the
-- following is @{libp.iter.keys}' implementation
--
--     function M.keys(invariant)
--         vim.validate({ invariant = { invariant, "t" } })
--         local control = nil
--         return V(nil, function()
--             control = next(invariant, control)
--             return control, control
--         end)
--     end
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
function M:init(invariant, next_fn, control)
    vim.validate({
        next_fn = { next_fn, "f", true },
        invariant = { invariant, "t", true },
    })

    assert(next_fn or invariant, "next_fn and invariant can not both be nil")

    self._invariant = invariant
    self._next_fn = next_fn or next
    self._control = control
end

--- Returns the current entry and moves the iterator to the next position. This function is
-- triggered by the `__call` operator to make @{Iter} for-loop compatible. However,
-- users can also calls it explicitly to get just the next result.
-- @treturn any
-- @usage
-- local sum = 0
-- for v in V({ 1, 2, 3 }) do
--     sum = sum + v
-- end
--
-- assert(sum == 6)
-- for i, v in KV({ 1, 2, 3 }) do
--     assert(i == v)
-- end
-- @usage
-- local viter = V({ 1, 2 })
-- assert(viter:next() == 1)
-- assert(viter:next() == 2)
-- assert(viter:next() == nil)
--
-- local kviter = KV({ "a", "b" })
-- assert.are.same({ 1, "a" }, { kviter:next() })
-- assert.are.same({ 2, "b" }, { kviter:next() })
-- assert.is_nil(iter:next())
function M:next()
    local val
    self._control, val = self._next_fn(self._invariant, self._control)
    return self:_key_value_to_entry(self._control, val)
end

-- Jargon for the following functions:
-- entry: k, v for KV; v for V
-- packed entry: {k, v} for KV; v for V
-- next_fn_output: next control, next value
--
-- Given key, value. Returns entry.
function M:_key_value_to_entry(_, _)
    assert(false, "Must be implemented by child")
end

function M:_key_value_to_packed_entry(_, _)
    assert(false, "Must be implemented by child")
end

function M:_packed_entry_to_key_value()
    assert(false, "Must be implemented by child")
end

function M:_entry_to_next_fn_output(_, _)
    assert(false, "Must be implemented by child")
end

function M:_packed_entry_to_next_fn_output(_, _)
    assert(false, "Must be implemented by child")
end

--- Returns a container hosting the results of @{next} calls (until it returns
-- nil). The return type is decided by the derived iterator class. For e.g.,
-- @{V} returns an array and @{KV} returns a table.
-- @treturn array|table
-- @usage
-- assert.are.same({ 1, 2, 3 }, V({ 1, 2, 3 }):collect())
-- assert.are.same({ a = 1, b = 2, c = 3 }, KV({ a = 1, b = 2, c = 3 }):collect())
function M:collect()
    assert(false, "Must be implemented by child")
end

--- Returns the generic for (next function, invariant, control) tuple.
-- This function is probably only of interest to derived class of @{Iter}.
-- @treturn function,table|nil,any
function M:pairs()
    return self._next_fn, self._invariant, self._control
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
-- local viter = V({ 1 }):cycle()
-- assert.are.same(1, viter:next())
-- assert.are.same(1, viter:next())
--
-- local kviter = KV({ a=1 }):cycle()
-- assert.are.same({a, 1}, {kviter:next()})
-- assert.are.same({a, 1}, {kviter:next()})
function M:cycle()
    return self:CLASS()(nil, function()
        local v
        self._control, v = self._next_fn(self._invariant, self._control)
        if not self._control then
            self._control, v = self._next_fn(self._invariant, self._control)
        end
        return self._control, v
    end)
end

--- Returns a new iterator that takes only the first n elements.
-- @treturn Iter
-- @usage
-- assert.are.same({ 1, 2 }, V({ 1, 2, 3 }):take(2):collect())
-- assert.are.same({ "a", "b" }, KV({ "a", "b", "c", "d" }):collect())
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
        self._control, v = self._next_fn(self._invariant, self._control)
        return self._control, v
    end)
end

--- Returns a new iterator that transforms the entries with a map function.
-- @tparam function(...)->... map_fn The map function.
-- @treturn Iter The new iterator.
-- @usage
-- assert.are.same(
--     { 2, 4 },
--     V({ 1, 2 }):map(function(v)
--         return 2 * v
--     end):collect()
-- )
-- assert.are.same(
--     { [2] = 2, [4] = 4, [6] = 6 },
--     KV({ 1, 2, 3 }):map(function(k, v)
--         return k * 2, v * 2
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
        self._control, v = self._next_fn(self._invariant, self._control)
        if self._control then
            k, v = map_fn(self:_key_value_to_entry(self._control, v))
            return self:_entry_to_next_fn_output(k, v)
        end
    end)
end

--- Returns a new iterator that filters the enteires with a filter function.
-- @tparam function(any)->boolean filter_fn The filter function.
-- @treturn Iter
-- @usage
-- assert.are.same(
--     { 1, 3 },
--     V({ 1, 2, 3 }):filter(function(v)
--         return v % 2 ~= 0
--     end):collect()
-- )
--
-- assert.are.same(
--     { 1, [3] = 3 },
--     KV({ 1, 2, 3 }):filter(function(v)
--         return v % 2 ~= 0
--     end):collect()
-- )
function M:filter(filter_fn)
    vim.validate({ filter_fn = { filter_fn, "f" } })
    -- See map for logic explanation.
    return self:CLASS()(nil, function()
        repeat
            local v
            self._control, v = self._next_fn(self._invariant, self._control)
            if self._control and filter_fn(self:_key_value_to_entry(self._control, v)) then
                return self._control, v
            end
        until not self._control
    end)
end

--- Consumes the iterator, returning the last element.
-- @treturn any The last entry
-- @usage
-- assert.are.same(4, V({ 1, 2, 3, 4 }):last())
-- assert.are.same({ 4, 4 }, KV({ 1, 2, 3, 4 }):last())
function M:last()
    return self:fold(nil, functional.binary_op.second)
end

--- Folds every element into an accumulator by applying an operation, returning
-- the final result.
-- @tparam any init The initial value of the accumulator
-- @tparam function(acc,curr)->acc op The accumulating function that returns
-- accumulated value of the accumulator and the current entry.
-- @treturn any
-- @usage
-- assert.are.same(10, V({ 1, 2, 3, 4 }):fold(0, require("libp.functional").binary_op.add))
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
        local entry = self:_key_value_to_packed_entry(k, v)
        acc = op(acc, entry)
    end
    return acc
end

--- Accumulates elements by applying an operation, producing all intermediate results as an iterator.
-- @tparam any init The initial value of the accumulator
-- @tparam function(acc,curr)->acc op The accumulating function that returns
-- accumulated value of the accumulator and the current entry.
-- @treturn any
-- @usage
-- assert.are.same({1, 3, 6, 10}, V({ 1, 2, 3, 4 }):fold(0, require("libp.functional").binary_op.add))
-- assert.are.same(
--     { [1] = 1, [3] = 3, [6] = 6, [10] = 10 },
--     KV({ 1, 2, 3, 4 }):scan({ 0, 0 }, function(acc, curr)
--         acc[1] = acc[1] + curr[1]
--         acc[2] = acc[2] + curr[2]
--         return acc
--     end):collect()
-- )
function M:scan(init, op)
    vim.validate({ op = { op, "f" } })
    local acc = init
    return self:CLASS()(nil, function()
        local v
        self._control, v = self._next_fn(self._invariant, self._control)
        if self._control then
            acc = op(acc, self:_key_value_to_packed_entry(self._control, v))
            return self:_packed_entry_to_next_fn_output(acc)
        end
    end)
end

return M
