local VIter = require("libp.datatype.VIter")

describe("next", function()
    it("Returns only value.", function()
        local iter = VIter({ 1, 2, 3 })
        assert.are.same(1, iter:next())
        assert.are.same(2, iter:next())
        assert.are.same(3, iter:next())
        assert.is_nil(iter:next())
    end)
    it("Works with generic for.", function()
        local i = 1
        for v in VIter({ 1, 2, 3 }) do
            assert.are.same(i, v)
            i = i + 1
        end
        assert.are.same(4, i)
    end)
end)

describe("collect", function()
    it("Returns an array of values", function()
        assert.are.same({ 1, 2, 3 }, VIter({ 1, 2, 3 }):collect())
    end)

    it("Indices are correct after filtered", function()
        assert.are.same(
            { 2, 3 },
            VIter({ 1, 2, 3 }):filter(function(v)
                return v > 1
            end):collect()
        )
    end)

    it("Values correct after mapped", function()
        assert.are.same(
            { 2, 3 },
            VIter({ 1, 2, 3 }):filter(function(v)
                return v > 1
            end):collect()
        )
    end)

    it("Works after mapped filtered", function()
        assert.are.same(
            { 6, 8 },
            VIter({ 1, 2, 3, 4 })
                :map(function(v)
                    return v * 2
                end)
                :filter(function(v)
                    return v > 4
                end)
                :collect()
        )
    end)

    it("Works after filtered mapped", function()
        assert.are.same(
            { 2, 4 },
            VIter({ 1, 2, 3, 4 })
                :filter(function(v)
                    return v < 3
                end)
                :map(function(v)
                    return v * 2
                end)
                :collect()
        )
    end)
end)