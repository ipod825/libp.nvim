local M = require("libp.datatype.Iter"):EXTEND()

function M:next()
    local val
    self.control, val = self.next_fn(self.invariant, self.control)
    return self.control, val
end

function M:collect()
    local res = {}
    for k, v in self:pairs() do
        res[k] = v
    end
    return res
end

function M:for_each(fn)
    vim.validate({ fn = { fn, "function" } })
    for k, v in self:pairs() do
        fn(k, v)
    end
end

return M
