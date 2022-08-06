local M = {}

-- Provides subclass the constructor (__call) and ancestor method index
-- (__index).
function M:EXTEND()
	local mt = self
	mt.__call = function(cls, ...)
		return cls:NEW(...)
	end
	mt.__index = mt
	return setmetatable({}, mt)
end

-- Provides instance the ancestor method index (__index) and calls its
-- initializer.
function M:NEW(...)
	local mt = self
	mt.__index = mt
	local obj = setmetatable({}, mt)
	obj:init(...)
	return obj
end

-- Fall back initializer in case the subclass does not define it.
function M:init() end

-- Retuns a function that calls the member method with bound instance and first
-- several args.
function M:BIND(fn, ...)
	return require("libp.functional").bind(fn, self, ...)
end

-- Retuns an instance whose metatable is the parent class of the current class.
-- Thus, methods index start from the parent class.
function M:SUPER()
	local ori_self = self
	local parent_cls = getmetatable(getmetatable(ori_self))
	return setmetatable({}, {
		__index = function(_, key)
			if type(parent_cls[key]) == "function" then
				-- Return a member-function-like function that binds to the
				-- original self. Can't use self here as it refers to the
				-- instance returned by setmetatable.
				return function(_, ...)
					return parent_cls[key](ori_self, ...)
				end
			else
				return ori_self[key]
			end
		end,
	})
end

-- Returns whether the instance is an instantion of the class.
function M:IS(class)
	local mt = getmetatable(self)
	while mt do
		if mt == class then
			return true
		end
		mt = getmetatable(mt)
	end
	return false
end

return M
