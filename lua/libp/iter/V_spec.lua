local V = require("libp.iter.V")
local functional = require("libp.functional")

describe("map filter", function()
    it("Maps then filters values", function()
        assert.are.same(
            { 2, 6 },
            V({ 1, 2, 3 })
                :map(function(v)
                    return v * 2
                end)
                :filter(function(v)
                    return v % 4 ~= 0
                end)
                :collect()
        )
    end)
end)

describe("filter map", function()
    it("Filters then maps values", function()
        assert.are.same(
            { 2, 6 },
            V({ 1, 2, 3 })
                :filter(function(v)
                    return v % 2 ~= 0
                end)
                :map(function(v)
                    return v * 2
                end)
                :collect()
        )
    end)
end)

describe("fold", function()
    local op = functional.binary_op
    it("Return starting value if empty", function()
        assert.are.same(0, V({}):fold(0, op.add))
    end)
    it("Accumulates the elements", function()
        assert.are.same(10, V({ 1, 2, 3, 4 }):fold(0, op.add))
        assert.are.same(48, V({ 1, 2, 3, 4 }):fold(2, op.mult))
    end)
end)

describe("last", function()
    it("Returns nil if input is empty", function()
        assert.is_nil(V({}):last())
    end)
    it("Returns the last element", function()
        assert.are.same(4, V({ 1, 2, 3, 4 }):last())
    end)
end)

describe("count", function()
    it("Returns the number of elements", function()
        assert.are.same(0, V({}):count())
        assert.are.same(2, V({ 1, 2 }):count())
    end)
end)

describe("cycle", function()
    it("Repeats indefinitely", function()
        local iter = V({ 1 }):cycle()
        assert.are.same(1, iter:next())
        assert.are.same(1, iter:next())
        assert.are.same(1, iter:next())
    end)
    it("Works with take", function()
        local iter = V({ 1 }):cycle():take(2)
        assert.are.same(1, iter:next())
        assert.are.same(1, iter:next())
        assert.is_nil(iter:next())
    end)
end)

describe("take", function()
    it("Takes first n elements", function()
        assert.are.same({ 1, 2 }, V({ 1, 2, 3 }):take(2):collect())
    end)
end)
