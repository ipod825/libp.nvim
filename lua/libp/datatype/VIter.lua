local M = require("libp.datatype.Iter"):EXTEND()

function M:next()
    local val
    self.control, val = self.next_fn(self.invariant, self.control)
    return val
end

function M:collect()
    local res = {}
    for _, v in self:enumerate() do
        res[#res + 1] = v
    end
    return require("libp.datatype.List")(res)
end

function M:for_each(fn)
    vim.validate({ fn = { fn, "function" } })
    for _, v in self:enumerate() do
        fn(v)
    end
end

return M
