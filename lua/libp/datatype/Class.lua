--- Module: **libp.datatype.Class**
--
-- Mother of all classes.
--
-- Each type inheriting from Class (via @{Class.EXTEND}) by default has:
--
-- * Default constructor @{Class.NEW} that forwards arguments to @{Class.init}.
-- * Default initializer @{Class.init}.
-- * Inherit function @{Class.EXTEND}, which can be used for defining derived types.
-- * @{Class.SUPER} for accessing parent member function.
-- * Other util member functions (see below).
--
-- The () operator of a derived class calls it's constructor: the NEW function.
-- If the constructor of the derived class involves only initializing member
-- variables, there's no need to override @{Class.NEW}. Implementing
-- (overriding) @(Class.init) is enough. However, if the constructor involves
-- manipulating the metatable of the constructor arguments. @{Class.NEW} can be
-- override to achieve that. The other functions provided by Class is not
-- recommended to be overrided.
--
-- @classmod Class
local M = {}

--- Inheriting function.
-- @usage
-- Child = Class:EXTEND()
-- GrandChild = Child:EXTEND()
-- function Child:fn(arg)
--     return "Child" .. arg
-- end
-- assert.are.same("Childarg", Child():fn("arg"))
-- assert.are.same("Childarg", GrandChild():fn("arg"))
function M:EXTEND()
    local mt = self
    mt.__call = function(cls, ...)
        return cls:NEW(...)
    end
    mt.__index = mt
    return setmetatable({}, mt)
end

--- Constructor.
-- @tparam any ... Parameter to be passed to the initializer @{Class.init}
function M:NEW(...)
    local mt = self
    mt.__index = mt
    local obj = setmetatable({}, mt)
    obj:init(...)
    return obj
end

--- Initializer.
-- @tparam any ... Parameter passed from the constructor @{Class.init}
function M:init(...) end

--- Returns a function that calls the member method with bound instance and arguments.
-- @tparam function The member function to be bound.
-- @tparam any ... The arguments to be bound.
-- @usage
-- Child = Class:EXTEND()
-- function Child:add(a)
--     return a + 1
-- end
-- local c = Child()
-- assert.are.same(2, c:BIND(c.add, 1)())
function M:BIND(fn, ...)
    return require("libp.functional").bind(fn, self, ...)
end

--- Gets accesses of parents' member functions.
-- Returns an instance whose member function indexing starts by checking the
--parent class and ancestors before checking the direct class of the instance.
--Note that the default behavior is to check the direct class -> parent class ->
--ancestor classes).
-- @return
-- @usage
-- Child = Class:EXTEND()
-- GrandChild = Child:EXTEND()
-- function Child:fn()
--     return "Child"
-- end
-- function GrandChild:fn()
--     return "GrandChild"
-- end
-- assert.are.same("GrandChild", GrandChild():fn())
-- assert.are.same("Child", GrandChild():SUPER():fn())
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

--- Returns whether the instance belongs to the class.
-- @param class a class type
-- @return boolean whether the instance belongs to the class
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
