local Class = require("libp.datatype.Class")

local Child
local GrandChild

describe("Class", function()
    before_each(function()
        Child = Class:EXTEND()
        GrandChild = Child:EXTEND()
    end)
    describe("EXTEND", function()
        it("Adds call and index to metatable", function()
            ChildMt = getmetatable(Child)
            assert.is_truthy(ChildMt.__call)
            assert.is_truthy(ChildMt.__index, ChildMt)

            GrandChildMt = getmetatable(GrandChild)
            assert.is_truthy(ChildMt.__call)
            assert.is_truthy(GrandChildMt.__index, GrandChildMt)
        end)

        it("Supports inheritance", function()
            function Child:fn(arg)
                return "Child" .. arg
            end
            assert.are.same("Childarg", Child():fn("arg"))
            assert.are.same("Childarg", GrandChild():fn("arg"))
        end)

        it("Supports metamethod inheritance", function()
            local ChildWithMetaMethod = Class:EXTEND({
                __add = function(this, that)
                    return this.num + that.num
                end,
            })
            function ChildWithMetaMethod:init()
                self.num = 1
            end

            local GrandChildWithMetaMethod = ChildWithMetaMethod:EXTEND()

            local c1, c2 = ChildWithMetaMethod(), ChildWithMetaMethod()
            local gc1, gc2 = GrandChildWithMetaMethod(), GrandChildWithMetaMethod()

            assert.are.same(2, c1 + c2)
            assert.are.same(2, gc1 + gc2)
        end)

        it("Supports __index override", function()
            local ChildWithOverriddenIndex
            ChildWithOverriddenIndex = Class:EXTEND({
                __index = function(_, key)
                    if key == "a" then
                        return "aa"
                    elseif key == "b" then
                        return "b"
                    else
                        return rawget(ChildWithOverriddenIndex, key) or rawget(Class, key)
                    end
                    return key
                end,
            })
            local GrandChildWithOverriddenIndex = ChildWithOverriddenIndex:EXTEND()

            local c = ChildWithOverriddenIndex()
            local gc = GrandChildWithOverriddenIndex()
            gc.a = "a"

            assert.are.same("aa", c.a)
            assert.are.same("b", c.b)
            -- a is found, did not look up parent index
            assert.are.same("a", gc.a)
            -- b is not found, look up in parent index
            assert.are.same("b", gc.b)
        end)

        it("Supports __call override", function()
            local ChildWithOverriddenCall = require("libp.datatype.Class"):EXTEND({
                __call = function()
                    return "fn1"
                end,
            })
            local child = ChildWithOverriddenCall()
            assert.are.same("fn1", child())
            local GrandChildWithOverriddenCall = ChildWithOverriddenCall:EXTEND()
            assert.has_error(function()
                child()
            end)
            local grandchild = GrandChildWithOverriddenCall()
            assert(grandchild() == "fn1")
        end)

        it("Supports override", function()
            function Child:fn(arg)
                return "Child" .. arg
            end
            function GrandChild:fn(arg)
                return "GrandChild" .. arg
            end
            assert.are.same("Childarg", Child():fn("arg"))
            assert.are.same("GrandChildarg", GrandChild():fn("arg"))
        end)
    end)

    describe("SET_CLASS_METHOD_INDEX", function()
        it("Does not modify parent class", function()
            local _ = Class:EXTEND():SET_CLASS_METHOD_INDEX(function(ori_index)
                return ori_index
            end)
            assert.are.same(Class, Class.__index)
        end)

        it("Enables class to hijack class method indexing", function()
            local ChildWithClassMethodHijacking = Class:EXTEND():SET_CLASS_METHOD_INDEX(function(ori_index)
                return function(_, key)
                    if key == "a" then
                        return "a"
                    else
                        return ori_index[key]
                    end
                end
            end)
            assert.is_nil(ChildWithClassMethodHijacking.b)
            assert.are.same("a", ChildWithClassMethodHijacking.a)
            assert.are.same(Class.BIND, ChildWithClassMethodHijacking.BIND)
        end)
    end)

    describe("Constructor (__call)", function()
        it("Has default initializer", function()
            assert.is_truthy(Child())
            assert.is_truthy(GrandChild())
        end)

        it("Calls parent init", function()
            function Child:init(num)
                self.num = num
            end
            assert.are.same(1, Child(1).num)
            assert.are.same(1, GrandChild(1).num)
        end)

        it("Calls own init", function()
            function Child:init(num)
                self.num = num
            end
            function GrandChild:init(num)
                self.num = 2 * num
            end
            assert.are.same(1, Child(1).num)
            assert.are.same(2, GrandChild(1).num)
        end)
    end)

    describe("BIND", function()
        it("Binds self and arg", function()
            function Child:init()
                self.num = 1
            end
            function Child:add(a, b)
                self.num = self.num + a + b
                return self.num
            end
            local c = Child()
            local f = c:BIND(c.add, 1)
            assert.are.same(4, f(2))
            assert.are.same(4, c.num)

            local c2 = Child()
            local ff = c2:BIND(c2.add, 2, 3)
            assert.are.same(6, ff())
            assert.are.same(6, c2.num)
        end)

        it("Binds args by reference", function()
            function Child:append(arr, e)
                table.insert(arr, e)
            end
            local arr = {}
            local c = Child()
            local f = c:BIND(c.append, arr)
            f(1)
            assert.are.same({ 1 }, arr)
            f(2)
            assert.are.same({ 1, 2 }, arr)
        end)

        it("Returns a function that can take nil in var args", function()
            function Child:nil_to_string(a, b, c)
                return tostring(a), tostring(b), tostring(c)
            end
            local c = Child()
            local f = c:BIND(c.nil_to_string)
            assert.are.same({ "nil", "1", "2" }, { f(nil, 1, 2) })
            assert.are.same({ "nil", "nil", "2" }, { f(nil, nil, 2) })
            assert.are.same({ "nil", "nil", "nil" }, { f(nil, nil, nil) })
        end)
    end)

    describe("SUPER", function()
        it("Calls parent's method", function()
            function Child:init()
                self.num = 1
            end
            function GrandChild:init()
                self.num = 2
            end

            function Child:fn()
                return "Child" .. self.num
            end

            function GrandChild:fn()
                return "GrandChild" .. self.num
            end

            local gc = GrandChild()
            assert.are.same("GrandChild2", gc:fn())
            assert.are.same("Child2", gc:SUPER():fn())
        end)
    end)

    describe("IS", function()
        it("Returns whether the instance belongs to a class", function()
            local Cousin = Class:EXTEND()
            local c = Child()
            assert.is_truthy(c:IS(Child))
            assert.is_truthy(c:IS(Class))
            assert.is_falsy(c:IS(c))
            assert.is_falsy(c:IS(Cousin))
            assert.is_falsy(c:IS(GrandChild))

            local gc = GrandChild()
            assert.is_truthy(gc:IS(GrandChild))
            assert.is_truthy(gc:IS(Child))
            assert.is_truthy(gc:IS(Class))
            assert.is_falsy(gc:IS(gc))
            assert.is_falsy(gc:IS(Cousin))
        end)
    end)

    describe("CLASS", function()
        it("Returns the class of an instance", function()
            assert.are.equal(Child, Child():CLASS())
            assert.are.equal(GrandChild, GrandChild():CLASS())
            assert.are.equal(Child, GrandChild:CLASS())
        end)
        it("Can be used to create child class instance in parent class", function()
            function Child:Clone()
                return self:CLASS()()
            end
            assert.is_true(Child():Clone():IS(Child))
            assert.is_true(GrandChild():Clone():IS(GrandChild))
        end)
    end)
end)
