local Iter = require("libp.datatype.Iter")
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

describe("count", function()
    it("Returns the number of elements", function()
        local iter = MyIter({ k = "v", k2 = "v2" })
        assert.are.same(2, iter:count())
    end)
end)

describe("mapkv", function()
    it("Works", function()
        local ori_iter = MyIter({ k = "v" })
        local mapped_iter = ori_iter:mapkv(function(k, v)
            return v, k
        end)
        -- Mapped iter should be of the same class.
        assert.are.same(MyIter, mapped_iter:CLASS())
        -- Mapped iter's next_fn returns what the map function returns.
        assert.are.same({ "v", "k" }, { mapped_iter.next_fn() })
        -- The ori_iter's internal should be updated.
        assert.are.same("k", ori_iter.control)
        -- The iterator should be terminated when reaches the end.
        assert.is_nil(mapped_iter.next_fn())
        assert.is_nil(ori_iter.control)
    end)
end)

describe("mapkv", function()
    it("Works", function()
        local ori_iter = MyIter({ k = "v" })
        local mapped_iter = ori_iter:map(function(v)
            return "mapped_v"
        end)
        -- Mapped iter should be of the same class.
        assert.are.same(MyIter, mapped_iter:CLASS())
        -- Mapped iter's next_fn returns ori_iter's control and what the map function returns.
        local returned_k, returned_v = mapped_iter.next_fn()
        assert.are.same({ ori_iter.control, "mapped_v" }, { returned_k, returned_v })
        -- The ori_iter's internal should be updated.
        assert.are.same("k", ori_iter.control)
        -- The iterator should be terminated when reaches the end.
        assert.is_nil(mapped_iter.next_fn())
        assert.is_nil(ori_iter.control)
    end)
end)

describe("filter", function()
    it("Works", function()
        local ori_iter = MyIter({ a = "va", b = "vb" })
        local filtered_iter = ori_iter:filter(function(v)
            return v ~= "va"
        end)
        -- Filtered iter should be of the same class.
        assert.are.same(MyIter, filtered_iter:CLASS())
        -- Filtered iter's next_fn returns ori_iter's control and what the map function returns.
        assert.are.same({ "b", "vb" }, { filtered_iter.next_fn() })
        -- The ori_iter's internal should be updated.
        assert.are.same("b", ori_iter.control)
        -- The iterator should be terminated when reaches the end.
        assert.is_nil(filtered_iter.next_fn())
        assert.is_nil(ori_iter.control)
    end)
end)

describe("filterkv", function()
    it("Works", function()
        local ori_iter = MyIter({ a = "va", b = "vb", c = "vc" })
        local filtered_iter = ori_iter:filterkv(function(k, v)
            return v ~= "va" and v ~= "vb"
        end)
        -- Filtered iter should be of the same class.
        assert.are.same(MyIter, filtered_iter:CLASS())
        -- Filtered iter's next_fn returns ori_iter's control and what the map function returns.
        assert.are.same({ "c", "vc" }, { filtered_iter.next_fn() })
        -- The ori_iter's internal should be updated.
        assert.are.same("c", ori_iter.control)
        -- The iterator should be terminated when reaches the end.
        assert.is_nil(filtered_iter.next_fn())
        assert.is_nil(ori_iter.control)
    end)
end)

describe("chain map filter", function()
    it("Works with dict", function()
        local iter = Iter({ a = 1, b = 2, c = 3, d = 4 })
        local new_iter = iter:filter(function(v)
            return v % 2 == 0
        end):map(function(v)
            return v * 2
        end)
        local res = {}
        add_dict(res, new_iter.next_fn)
        add_dict(res, new_iter.next_fn)
        assert.are.same({ b = 4, d = 8 }, res)
        assert.is_nil(new_iter.next_fn())
    end)
    it("Works with array", function()
        local iter = Iter({ 1, 2, 3, 4 })
        local new_iter = iter:filter(function(v)
            return v % 2 == 0
        end):map(function(v)
            return v * 2
        end)
        assert.are.same({ 2, 4 }, { new_iter.next_fn() })
        assert.are.same({ 4, 8 }, { new_iter.next_fn() })
        assert.is_nil(new_iter.next_fn())
    end)
end)

describe("chain mapkv filterkv", function()
    it("Works with dict", function()
        local iter = Iter({ a = 1, b = 2, c = 3, d = 5 })
        local new_iter = iter:filterkv(function(k, v)
            return k ~= "a" and v < 5
        end):mapkv(function(k, v)
            return v, k
        end)
        local res = {}
        add_dict(res, new_iter.next_fn)
        add_dict(res, new_iter.next_fn)
        assert.are.same({ [2] = "b", [3] = "c" }, res)
        assert.is_nil(new_iter.next_fn())
    end)
    it("Works with array", function()
        local iter = Iter({ 1, 2, 3, 4 })
        local new_iter = iter:filterkv(function(k, v)
            return k < 4 and v % 2 ~= 0
        end):mapkv(function(k, v)
            return k, v * 2
        end)
        assert.are.same({ 1, 2 }, { new_iter.next_fn() })
        assert.are.same({ 3, 6 }, { new_iter.next_fn() })
        assert.is_nil(new_iter.next_fn())
    end)
end)

describe("chain filter map", function()
    it("Works with dict", function()
        local iter = Iter({ a = 1, b = 2, c = 3, d = 5 })
        local new_iter = iter:map(function(v)
            return v * 2
        end):filter(function(v)
            return v < 6
        end)
        local res = {}
        add_dict(res, new_iter.next_fn)
        add_dict(res, new_iter.next_fn)
        assert.are.same({ a = 2, b = 4 }, res)
        assert.is_nil(new_iter.next_fn())
    end)
    it("Works with array", function()
        local iter = Iter({ 1, 2, 3, 4 })
        local new_iter = iter:map(function(v)
            return v * 2
        end):filter(function(v)
            return v > 4
        end)
        assert.are.same({ 3, 6 }, { new_iter.next_fn() })
        assert.are.same({ 4, 8 }, { new_iter.next_fn() })
        assert.is_nil(new_iter.next_fn())
    end)
end)

describe("chain filterkv mapkv", function()
    it("Works with dict", function()
        local iter = Iter({ a = 1, b = 2, c = 3, d = 4 })
        local new_iter = iter:mapkv(function(k, v)
            return "k" .. k, v * 2
        end):filterkv(function(k, v)
            return k ~= "kc" and v > 2
        end)
        local res = {}
        add_dict(res, new_iter.next_fn)
        add_dict(res, new_iter.next_fn)
        assert.are.same({ kb = 4, kd = 8 }, res)
        assert.is_nil(new_iter.next_fn())
    end)
    it("Works with array", function()
        local iter = Iter({ 1, 2, 3, 4 })
        local new_iter = iter:mapkv(function(k, v)
            return k, v * 2
        end):filterkv(function(k, v)
            return k > 1 and v > 4
        end)
        assert.are.same({ 3, 6 }, { new_iter.next_fn() })
        assert.are.same({ 4, 8 }, { new_iter.next_fn() })
        assert.is_nil(new_iter.next_fn())
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
