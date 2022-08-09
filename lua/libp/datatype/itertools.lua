local M = {}
local VIter = require("libp.datatype.VIter")

function M.range(beg, ends, step)
    vim.validate({ beg = { beg, "n" }, ends = { ends, "n" }, step = { step, "n", true } })
    if not ends then
        ends = beg
        beg = 1
    end
    step = step or 1

    assert(step ~= 0, "step can not be zero")

    return VIter(nil, function(_, control)
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
    end)
end

function M.values(invariant)
    return VIter(invariant)
end

function M.keys(invariant)
    return VIter(invariant):mapkv(function(k, _)
        return k
    end)
end

return M
