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

function M.weak_reference(obj)
	local mt = getmetatable(obj)
	if not mt then
		return setmetatable(obj, { __mode = "v" })
	else
		mt["__mode"] = "v"
		return obj
	end
end

return M
