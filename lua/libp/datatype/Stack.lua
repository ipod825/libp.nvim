local M = require("libp.datatype.Class"):EXTEND()

function M:NEW(lst)
	lst = lst or {}
	local obj = setmetatable(lst, self)
	self.__index = self
	return obj
end

function M:push(ele)
	self[#self + 1] = ele
end

function M:pop()
	local res = self[#self]
	self[#self] = nil
	return res
end

function M:top()
	return self[#self]
end

function M:size()
	return #self
end

function M:empty()
	return #self == 0
end

return M
