local M = {}

function M.reverse(lst)
    vim.validate({ lst = { lst, "t" } })
    local res = {}
    local S = #lst + 1
    for i, val in ipairs(lst) do
        res[S - i] = val
    end
    return res
end

return M
