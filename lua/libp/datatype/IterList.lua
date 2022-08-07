--- List iterator class supporting functional programming operations.
--
-- A @{List} can be transformed to @{IterList} by @{List.to_iter}. While @{List}
-- already provides some functional programming style functions such as
-- @{List.filter} and @{List.map}, @{IterList} makes it more general such that
-- the filter and map operations can be chained. In fact, the @{List} APIs were
-- provided to reduce verbosity in simple cases. Those APIs simply call
-- @{IterList} APIs.
--
-- Inherits: @{Class}
-- @classmod IterList
local M = require("libp.datatype.Class"):EXTEND()
local List = require("libp.datatype.List")

--- Constructor.
-- @tparam table opts
-- @tparam function opts.next_fn The next function
-- @tparam[opt] table opts.invariant The invariant
-- @tparam[opt] number opts.control The control
-- @treturn IterList A new IterList
-- @see ipairs
-- @see pairs
-- @see next
function M:init(opts)
    vim.validate({
        next_fn = { opts.next_fn, "f" },
        invariant = { opts.invariant, "t", true },
        control = { opts.controle, "n", true },
    })

    self.next_fn = opts.next_fn
    self.invariant = opts.invariant
    self.control = opts.control
end

--- Returns the generic for (index,value) tuple.
-- @return Generic for (index,value) tuple
-- @usage
-- for i, v in IterList.from_range(1, 4):enumerate() do
--     assert(i == v)
-- end
function M:enumerate()
    return self.next_fn, self.invariant, self.control
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
        for _, e in self:enumerate() do
            coroutine.yield(e)
        end
    end)
end

--- Returns the next value of the iterator and updates the internal.
-- @treturn any next value of the iterator.
-- @usage
-- local iter = IterList.from_range(1, 2)
-- assert.are.same(1, iter:next())
-- assert.are.same(2, iter:next())
-- assert.are.same(nil, iter:next())
function M:next()
    local res
    self.control, res = self.next_fn(self.invariant, self.control)
    return res
end

--- Returns the List containing all the values.
-- @treturn List.
-- @usage
-- assert.are.same({ 1, 2, 3 }, IterList.from_range(1, 3):collect())
function M:collect()
    local res = {}
    local i = 1
    for _, v in self:enumerate() do
        res[i] = v
        i = i + 1
    end
    return List(res)
end

--- Executes a function on each element of the list.
-- @tparam function(any)->nil fn The function to be executed
-- @treturn nil
-- @usage
-- local sum = 0
-- local indices = {}
-- IterList.from_range(1, 4):for_each(function(e, i)
--     sum = sum + e
--     table.insert(indices, i)
-- end)
-- assert.are.same(10, sum)
-- assert.are.same({ 1, 2, 3, 4 }, indices)
function M:for_each(fn)
    vim.validate({ fn = { fn, "function" } })
    for _, v in self:enumerate() do
        fn(v)
    end
end

--- Creates an IterList with an extra transforming step via the function.
-- @tparam function(any)->any fn The mapping function
-- @treturn IterList The IterList with an extra transforming step
-- @usage
-- assert.are.same(
--     { 2, 4, 6, 8 },
--     IterList.from_range(1, 4)
--         :map(function(e)
--             return e * 2
--         end)
--         :collect()
-- )
function M:map(map_fn)
    vim.validate({ map_fn = { map_fn, "function" } })
    return M({
        next_fn = function(invariant, control)
            local v
            control, v = self.next_fn(invariant, control)
            if control then
                return control, map_fn(v)
            end
        end,
        invariant = self.invariant,
        control = self.control,
    })
end

--- Creates an IterList with an extra filtering step via the function.
-- @tparam function(any)->any fn The filtering function
-- @treturn IterList The IterList with an extra filtering step
-- @usage
-- assert.are.same(
--     { 2, 4 },
--     IterList.from_range(1, 4)
--         :filter(function(e)
--             return e % 2 == 0
--         end)
--         :collect()
-- )
function M:filter(filter_fn)
    vim.validate({ filter_fn = { filter_fn, "function" } })
    return M({
        next_fn = function(invariant, control)
            repeat
                local v
                control, v = self.next_fn(invariant, control)
                if control and filter_fn(v) then
                    return control, v
                end
            until not control
        end,
        invariant = self.invariant,
        control = self.control,
    })
end

--- Creates an IterList from a range.
-- @static
-- @tparam number beg The start of the range (included). If ends is not provided, beg specifies the ends and beg is implicitly set to 1.
-- @tparam[opt] number ends The end of the range (included)
-- @tparam[opt=1] number step The step for each iteration. Can be negative
-- @treturn IterList The IterList representing the range.
-- @usage
-- assert.are.same({ 1, 2, 3, 4 }, IterList.from_range(4))
-- assert.are.same({ 1, 3, 5 }, IterList.from_range(1, 6, 2))
function M.from_range(beg, ends, step)
    vim.validate({ beg = { beg, "n" }, ends = { ends, "n" }, step = { step, "n", true } })
    if not ends then
        ends = beg
        beg = 1
    end
    step = step or 1

    assert(step ~= 0, "step can not be zero")

    return M({
        next_fn = function(_, control)
            control = control or 0
            local res = beg + control * step
            if step > 0 then
                if res <= ends then
                    return control + 1, res
                end
            else
                if res >= ends then
                    return control + 1, res
                end
            end
        end,
    })
end

return M
