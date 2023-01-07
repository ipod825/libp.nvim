local Iter = require("libp.iter.Iter")
local spy = require("luassert.spy")

local MyIter = Iter:EXTEND()

local function add_dict(d, next_fn)
    local k, v = next_fn()
    d[k] = v
end

describe("Extension", function()
    it("Makes the __call method of dreived classes invokes its next", function()
        function MyIter:next() end
        local myit = MyIter({})
        local nxt = spy.on(myit, "next")
        myit()
        assert.spy(nxt).was_called()
    end)
end)

describe("constructor", function()
    it("Must provide either next_fn or invariant", function()
        assert.has.errors(function()
            Iter()
        end)
        assert.is_truthy(Iter({}))
        assert.is_truthy(Iter(nil, function() end))
    end)

    it("Defaults next_fn to the builtin next function", function()
        local iter = Iter({})
        assert.are.same(next, iter.next_fn)
    end)
end)

describe("interfaces", function()
    it("Raises error on unimplemented methods", function()
        assert.has.error_match(function()
            Iter({}):next()
        end, "Must be implemented by child")
        assert.has.error_match(function()
            Iter({}):collect()
        end, "Must be implemented by child")
    end)
end)

describe("pairs", function()
    it("Returns the next_fn, invariant, control tuple", function()
        local invariant = {}
        local next_fn = function() end
        local control = 1
        assert.are.same({ next_fn, invariant, control }, { Iter(invariant, next_fn, control):pairs() })
    end)
end)

describe("cycle", function()
    it("Repeats indefinitely", function()
        local iter = Iter({ a = 1 }):cycle()
        assert.are.same({ "a", 1 }, { iter.next_fn() })
        assert.are.same({ "a", 1 }, { iter.next_fn() })
        assert.are.same({ "a", 1 }, { iter.next_fn() })
    end)
    it("Works with take", function()
        local iter = Iter({ a = 1 }):cycle():take(2)
        assert.are.same({ "a", 1 }, { iter.next_fn() })
        assert.are.same({ "a", 1 }, { iter.next_fn() })
        assert.is_nil(iter.next_fn())
    end)
end)

describe("take", function()
    it("Takes first n elements", function()
        local iter = Iter({ 1, 2, 3, 4 }):take(2)
        assert.are.same({ 1, 1 }, { iter.next_fn() })
        assert.are.same({ 2, 2 }, { iter.next_fn() })
        assert.is_nil(iter.next_fn())
    end)
end)
