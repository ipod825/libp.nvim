local KVIter = require("libp.datatype.KVIter")

describe("next", function()
    it("Returns key value.", function()
        local iter = KVIter({ 4, 5, 6 })
        assert.are.same({ 1, 4 }, { iter:next() })
        assert.are.same({ 2, 5 }, { iter:next() })
        assert.are.same({ 3, 6 }, { iter:next() })
        assert.is_nil(iter:next())
    end)
    it("Works with generic for.", function()
        local i = 1
        for k, v in KVIter({ 4, 5, 6 }) do
            assert.are.same(i, k)
            assert.are.same(i + 3, v)
            i = i + 1
        end
        assert.are.same(4, i)
    end)
end)

describe("collect", function()
    it("Returns a dict", function()
        assert.are.same({ a = 1, b = 2, c = 3 }, KVIter({ a = 1, b = 2, c = 3 }):collect())
    end)

    it("Works after mapped filtered", function()
        assert.are.same(
            { c = 6, d = 8 },
            KVIter({ a = 1, b = 2, c = 3, d = 4 })
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
            { a = 2, b = 4 },
            KVIter({ a = 1, b = 2, c = 3, d = 4 })
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
