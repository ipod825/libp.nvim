local OrderedDict = require("libp.datatype.OrderedDict")

describe("OrderedDict", function()
    it("Is like a dict", function()
        local d = OrderedDict()
        d.a = 1
        d.b = 2
        assert.are.same(d.a, 1)
        assert.are.same(d.b, 2)

        d.a = nil
        assert.is_falsy(d.a)
        assert.are.same(d.b, 2)
    end)

    it("Returns the original data", function()
        local d = OrderedDict()
        d.b = 1
        d.a = 2
        assert.are.same({ b = 1, a = 2 }, OrderedDict.data(d))
    end)

    it("Is ordered in pairs", function()
        local d = OrderedDict()
        d.b = 1
        d.a = 2
        local iter = OrderedDict.pairs(d)
        assert.are.same({ "b", 1 }, { iter:next() })
        assert.are.same({ "a", 2 }, { iter:next() })
    end)

    it("Is ordered in pairs after deletion", function()
        local d = OrderedDict()
        d.b = 1
        d.a = 2
        d.b = nil
        d.c = 3
        local iter = OrderedDict.pairs(d)
        assert.are.same({ "a", 2 }, { iter:next() })
        assert.are.same({ "c", 3 }, { iter:next() })
    end)

    it("Is ordered in keys", function()
        local d = OrderedDict()
        d.b = 1
        d.a = 2
        local iter = OrderedDict.keys(d)
        assert.are.same("b", iter:next())
        assert.are.same("a", iter:next())
    end)

    it("Is ordered in keys after deletion", function()
        local d = OrderedDict()
        d.b = 1
        d.a = 2
        d.b = nil
        d.c = 3
        local iter = OrderedDict.keys(d)
        assert.are.same("a", iter:next())
        assert.are.same("c", iter:next())
    end)

    it("Is ordered in values", function()
        local d = OrderedDict()
        d.b = 1
        d.a = 2
        local iter = OrderedDict.values(d)
        assert.are.same(1, iter:next())
        assert.are.same(2, iter:next())
    end)

    it("Is ordered in values after deletion", function()
        local d = OrderedDict()
        d.b = 1
        d.a = 2
        d.b = nil
        d.c = 3
        local iter = OrderedDict.values(d)
        assert.are.same(2, iter:next())
        assert.are.same(3, iter:next())
    end)

    it("Works with reference values", function()
        local inner = {}
        local d = OrderedDict()
        d.a = inner

        d.a.key = 1
        assert.is_truthy(inner.key)

        d.a.key = nil
        assert.is_falsy(inner.key)
    end)
end)
