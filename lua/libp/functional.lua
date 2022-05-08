local M = {}

function M.nop() end

function M.identity(e)
	return e
end

function M.oneshot(f)
	local counter = 0
	return function()
		if counter == 0 then
			counter = counter + 1
			return f()
		end
	end
end

function M.head_tail(arr)
	assert(vim.tbl_islist(arr))
	if #arr == 0 then
		return nil, nil
	elseif #arr == 1 then
		return arr[1], nil
	else
		return arr[1], vim.list_slice(arr, 2)
	end
end

return M
