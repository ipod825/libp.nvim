local M = require("libp.datatype.Class"):EXTEND()

function M:NEW(lst)
	lst = lst or {}
	local obj = setmetatable(lst, self)
	self.__index = self
	return obj
end

function M:__add(that)
	local res = vim.deepcopy(self)
	vim.list_extend(res, that)
	return res
end

function M:append(ele)
	self[#self + 1] = ele
end

function M:extend(that)
	vim.list_extend(self, that)
	return self
end

function M:sort(...)
	table.sort(self, ...)
	return self
end

function M:values()
	return coroutine.wrap(function()
		for _, e in ipairs(self) do
			coroutine.yield(e)
		end
	end)
end

function M:enumerate()
	return next, self, nil
end

function M:to_iter()
	return require("libp.datatype.IterList")({ next_fn = next, invariant = self })
end

function M:filter(fn)
	return self:to_iter():filter(fn):collect()
end

function M:map(fn)
	return self:to_iter():map(fn):collect()
end

function M:for_each(fn)
	for i, e in ipairs(self) do
		fn(e, i)
	end
end

function M:unbox_if_one()
	if #self == 1 then
		return self[1]
	end
	return self
end
return M
