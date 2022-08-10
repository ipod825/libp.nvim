local M = require("libp.datatype.Class"):EXTEND({
    __call = function(this, ...)
        return this:next(...)
    end,
})

-- function M:EXTEND()
--     -- Repeat the code of CLASS:EXTEND
--     -- Is there a way to avoid this repetition?
--     local mt = self
--     mt.__call = function(cls, ...)
--         return cls:NEW(...)
--     end
--     mt.__index = mt
--     local IterClass = setmetatable({}, mt)
--
--     -- An instance of any child iterator class should be callable. The semantic
--     -- of the call operator is calling the instance's next member function.
--     IterClass.__call = function(this, ...)
--         return this:next(...)
--     end
--
--     return IterClass
-- end

function M:init(invariant, next_fn, control)
    vim.validate({
        next_fn = { next_fn, "f", true },
        invariant = { invariant, "t", true },
        control = { control, "n", true },
    })

    assert(next_fn or invariant, "next_fn and invariant can not both be nil")

    self.invariant = invariant
    self.next_fn = next_fn or next
    self.control = control
end

function M:next(...)
    assert(false, "Must be implemented by child")
end

function M:pairs()
    return self.next_fn, self.invariant, self.control
end

function M:collect()
    assert(false, "Must be implemented by child")
end

function M:mapkv(map_fn)
    vim.validate({ map_fn = { map_fn, "function" } })
    return self:CLASS()(self.invariant, function()
        local v
        self.control, v = self.next_fn(self.invariant, self.control)
        if self.control then
            return map_fn(self.control, v)
        end
    end, self.control)
end

function M:map(map_fn)
    vim.validate({ map_fn = { map_fn, "function" } })
    return self:CLASS()(self.invariant, function()
        local v
        self.control, v = self.next_fn(self.invariant, self.control)
        if self.control then
            return self.control, map_fn(v)
        end
    end, self.control)
end

function M:filterkv(filter_fn)
    vim.validate({ filter_fn = { filter_fn, "function" } })
    return self:CLASS()(self.invariant, function()
        repeat
            local v
            self.control, v = self.next_fn(self.invariant, self.control)
            if self.control and filter_fn(self.control, v) then
                return self.control, v
            end
        until not self.control
    end, self.control)
end

function M:filter(filter_fn)
    vim.validate({ filter_fn = { filter_fn, "function" } })
    return self:CLASS()(self.invariant, function()
        repeat
            local v
            self.control, v = self.next_fn(self.invariant, self.control)
            if self.control and filter_fn(v) then
                return self.control, v
            end
        until not self.control
    end, self.control)
end

return M
