local KV = require("libp.iter.KV")

describe("map", function()
    it("Maps values", function()
        assert.are.same(
            { 2, 4, 6 },
            KV({ 1, 2, 3 }):map(function(k, v)
                return k, v * 2
            end):collect()
        )
        assert.are.same(
            { [2] = 2, [4] = 4, [6] = 6 },
            KV({ 1, 2, 3 }):map(function(k, v)
                return k * 2, v * 2
            end):collect()
        )
    end)
end)

describe("filter", function()
    it("Filter values", function()
        assert.are.same(
            { 1, [3] = 3 },
            KV({ 1, 2, 3 }):filter(function(v)
                return v % 2 ~= 0
            end):collect()
        )

        assert.are.same(
            { [2] = 2 },
            KV({ 1, 2, 3 }):filter(function(k, v)
                return k > 1 and v < 3
            end):collect()
        )
    end)
end)

describe("map filter", function()
    it("Maps then filters values", function()
        assert.are.same(
            { [1] = 2, [3] = 6 },
            KV({ 1, 2, 3 })
                :map(function(k, v)
                    return k, v * 2
                end)
                :filter(function(k, v)
                    return v % 4 ~= 0
                end)
                :collect()
        )
    end)

    it("Maps then filters values", function()
        assert.are.same(
            { [3] = 6 },
            KV({ 1, 2, 3 })
                :map(function(k, v)
                    return k, v * 2
                end)
                :filter(function(k, v)
                    return k > 2 and v % 4 ~= 0
                end)
                :collect()
        )
    end)
end)

describe("filter map", function()
    it("Filters then maps values", function()
        assert.are.same(
            { [1] = 2, [3] = 6 },
            KV({ 1, 2, 3 })
                :filter(function(k, v)
                    return v % 2 ~= 0
                end)
                :map(function(k, v)
                    return k, v * 2
                end)
                :collect()
        )
    end)

    it("Filters then maps values", function()
        assert.are.same(
            { [3] = 6 },
            KV({ 1, 2, 3 })
                :filter(function(k, v)
                    return k > 1 and v % 2 ~= 0
                end)
                :map(function(k, v)
                    return k, v * 2
                end)
                :collect()
        )
    end)
end)

describe("fold", function()
    local function add(acc, curr)
        acc[1] = acc[1] + curr[1]
        acc[2] = acc[2] + curr[2]
        return acc
    end

    local function mult(acc, curr)
        acc[1] = acc[1] * curr[1]
        acc[2] = acc[2] * curr[2]
        return acc
    end

    it("Return starting value if empty", function()
        assert.are.same({ 0, 0 }, KV({}):fold({ 0, 0 }, add))
    end)
    it("Accumulates the elements", function()
        assert.are.same({ 10, 10 }, KV({ 1, 2, 3, 4 }):fold({ 0, 0 }, add))
        assert.are.same({ 24, 48 }, KV({ 1, 2, 3, 4 }):fold({ 1, 2 }, mult))
    end)
end)

describe("last", function()
    it("Returns nil if input is empty", function()
        assert.is_nil(KV({}):last())
    end)
    it("Returns the last element", function()
        assert.are.same({ 4, 4 }, KV({ 1, 2, 3, 4 }):last())
        assert.are.same({ 4, "4" }, KV({ "1", "2", "3", "4" }):last())
    end)
end)

describe("count", function()
    it("Returns the number of elements", function()
        assert.are.same(0, KV({}):count())
        assert.are.same(2, KV({ 1, 2 }):count())
    end)
end)
