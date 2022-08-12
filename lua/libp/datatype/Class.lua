--- Module: **libp.datatype.Class**
--
-- Mother of all classes.
--
-- Each type inheriting from Class (via @{Class:EXTEND}) by default has:
--
-- * Constructor. The __call metamethod, which just invokes
-- `NEW` creating an instance of the current class and forwards its
-- arguments to `init` to initialize the instance.
-- * Inherit function `EXTEND`, which can be used for defining derived
-- types. All member methods and metamethods (with some exception, see
-- `EXTEND`) of the parent class will be inherited.
-- * `SUPER` for accessing parent member function.
-- * Other util member functions (see below).
--
-- Theoritically speaking, all the member functions provided by @{Class} can be
-- overrided (by simply redefining them for the derived class). However, we only
-- recommend overriding `init` and `NEW`. `init` is for
-- initializing an instance, so unless you want to reuse the parent class's
-- `init` function, you would always want to override it. As for the constructor
-- `NEW`, the rule of thumb is that if the constructor arguments are
-- member variables initializer, then overriding `NEW` is unnecessary.
-- Check @{List:NEW}'s implementation on when one might want to override
-- `NEW`.
--
-- @classmod Class
local M = {}
M.__index = M

local global = require("libp.global")("libp")
global.class_metamethods = {}

--- Inheriting function.
-- @tparam[opt=nil] table metamethods The metamethods to be defined in the
-- resulting class and its derived classes. The metamethod behavior will
-- automatically be inherited in child classes with two exception: First,
-- `__index` behavior will not be inherited. Second, `__call`'s behavior, though
-- will be inherited, but the behavior will not persist on the parent class once
-- the parent class calls EXTEND to create a new child class. That is, one can
-- only override `__call` for a **leaf class**. See the comment in the
-- implementation for detail explanation.
-- @usage
-- local Child = Class:EXTEND()
-- local GrandChild = Child:EXTEND()
-- function Child:fn(arg)
--     return "Child" .. arg
-- end
-- assert.are.same("Childarg", Child():fn("arg"))
-- assert.are.same("Childarg", GrandChild():fn("arg"))
function M:EXTEND(metamethods)
    -- New class's metatable will be the current class (self).
    local mt = self
    -- New class's __call operator will invoke the constructor NEW.
    mt.__call = function(cls, ...)
        return cls:NEW(...)
    end

    -- Creates the new class. Sets its __index as itself so that a instance of
    -- the new_class can lookup member methods when having new_class as its
    -- metatable. Note that Class.__index is set at the beginning of this file.
    local new_class = setmetatable({}, mt)
    new_class.__index = new_class

    -- Inherits metamethods from parent class (mt).
    local inherited_meta_methods = global.class_metamethods[mt]
    if metamethods and inherited_meta_methods then
        metamethods = vim.tbl_extend("keep", metamethods, inherited_meta_methods)
    elseif inherited_meta_methods then
        metamethods = vim.deepcopy(inherited_meta_methods)
    end

    if metamethods then
        for name, metamethod in pairs(metamethods) do
            new_class[name] = metamethod
        end
        metamethods.__index = nil
    end
    -- Stores the metamethod for children class to inherit.
    global.class_metamethods[new_class] = metamethods
    -- Note that __index and __call are special metamethods that the Class uses.
    -- So there are some limitation on inheriting their behavior. For __index,
    -- we completely disallow inheriting its behavior as that would make the
    -- instance of a child class lookup its member method from a parent class.
    -- For __call, only the classes in the bottom level of the inheritance
    -- hierarchy can keep the overrides behavior. This is better explained by
    -- the following example
    --
    -- 1.  local Child = require("libp.datatype.Class"):EXTEND({
    -- 2.      __call = function()
    -- 3.          return "fn1"
    -- 4.      end,
    -- 5.  })
    -- 6.  local child = Child()
    -- 7.  assert(child()=="fn1")
    -- 8.  local GrandChild = Child:EXTEND()
    -- 9.  assert(child() ~= "fn1")
    -- 10. local grandchild = GrandChild()
    -- 11. assert(grandchild() == "fn1")
    --
    -- At line 7, the __call operator of Child's metatable (Class) allows it to
    -- create instance. On the other hand, Child's __call allows Child's
    -- instance child to get "fn1" from its __call operator. Things changed at
    -- line 8 where we call Child:EXTEND(). At the beginning of EXTEND, we
    -- modify Child.__call back to the constructor stuff (which is why we can
    -- instantiate GrandChild in line 10). That is why in line 9, child() no
    -- longer returns "fn1". However, in the call of Child:EXTEND(), the new
    -- class (i.e., GrandChild) still sets its __call to the "fn1" function.
    -- That is why line 11 holds. By the same reasoning, if we try to have
    -- another class inheriting GrandChild by calling GrandChild:EXTEND(),
    -- GrandChild's __call will be reset. The take away is that there's a
    -- limitation on inheriting the behavior of the __call metamethods. That is,
    -- the class that really needs the __call behavior can't be extended
    -- anymore, they should be the "final" level of the inheritance hierarchy.

    return new_class
end

--- Constructor.
-- @tparam any ... Parameter to be passed to the initializer @{Class:init}
function M:NEW(...)
    local obj = setmetatable({}, self)
    obj:init(...)
    return obj
end

--- Initializer.
-- @tparam any ... Parameter passed from the constructor @{Class:NEW}
-- @usage
-- local Child = Class:EXTEND()
-- function Child:init(a, b)
--     self.a = a
--     self.b = b
-- end
-- local c = Child(1, 2)
-- assert(c.a == 1)
-- assert(c.b == 2)
function M:init(...) end

--- Returns a function that calls the member method with bound instance and arguments.
-- @tparam function fn The member function to be bound.
-- @tparam any ... The arguments to be bound.
-- @usage
-- local Child = Class:EXTEND()
-- function Child:add(a)
--     return a + 1
-- end
-- local c = Child()
-- assert.are.same(3, c:BIND(c.add, 2)())
function M:BIND(fn, ...)
    return require("libp.functional").bind(fn, self, ...)
end

--- Gets accesses of parents' member functions.
-- Returns an instance whose member function indexing starts by checking the
--parent class and ancestors before checking the direct class of the instance.
--Note that the default behavior is to check the direct class -> parent class ->
--ancestor classes).
-- @usage
-- local Child = Class:EXTEND()
-- local GrandChild = Child:EXTEND()
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
-- @usage
-- local Child = Class:EXTEND()
-- local c = Child()
-- assert(c:IS(Child))
-- assert(c:IS(Class))
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

--- Returns the direct class of the instance.
-- If the instance itself is a class then the result is coincidently the parent
-- class. This is useful to instantiate a derived class instance in a parent
-- class member function.
-- @return any
-- @see Class:IS
-- @usage
-- local Child = Class:EXTEND()
-- local GrandChild = Child:EXTEND()
-- function Child:Clone()
--     return self:CLASS()()
-- end
-- assert(Child():Clone():IS(Child))
-- assert(GrandChild():Clone():IS(GrandChild))
function M:CLASS()
    return getmetatable(self)
end

return M
