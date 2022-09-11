local LruDict = require("libp.datatype.LruDict")

describe("values", function()
    it("Returns empty list for empty lru", function()
        assert.are.same({}, LruDict.values(LruDict()))
    end)
    it("Returns the values in order", function()
        local lru = LruDict(100)
        lru.a = 1
        lru.b = 2
        lru.c = 3
        assert.are.same({ 3, 2, 1 }, LruDict.values(lru))
    end)
end)

describe("top", function()
    it("Returns last added value", function()
        local lru = LruDict(100)
        assert.are.same(nil, LruDict.top(lru))
        lru.a = 1
        assert.are.same(1, LruDict.top(lru))
        lru.b = 2
        assert.are.same(2, LruDict.top(lru))
        lru.c = 3
        assert.are.same(3, LruDict.top(lru))
        lru.a = 1
        assert.are.same(1, LruDict.top(lru))
        lru.b = 2
        assert.are.same(2, LruDict.top(lru))
        lru.c = 3
        assert.are.same(3, LruDict.top(lru))
    end)
end)

describe("__index", function()
    it("Returns nil when no such value", function()
        local lru = LruDict(100)
        assert.is_nil(lru.a)
    end)
    it("Maintains the mru order", function()
        local lru = LruDict(100)
        lru.a = 1
        assert.are.same({ 1 }, LruDict.values(lru))
        lru.b = 2
        assert.are.same({ 2, 1 }, LruDict.values(lru))
        lru.c = 3
        assert.are.same({ 3, 2, 1 }, LruDict.values(lru))
        lru.a = 1
        assert.are.same({ 1, 3, 2 }, LruDict.values(lru))
        lru.b = 2
        assert.are.same({ 2, 1, 3 }, LruDict.values(lru))
        lru.c = 3
        assert.are.same({ 3, 2, 1 }, LruDict.values(lru))
    end)

    it("Respects the capacity", function()
        local lru = LruDict(2)
        lru.a = 1
        assert.are.same({ 1 }, LruDict.values(lru))
        lru.b = 2
        assert.are.same({ 2, 1 }, LruDict.values(lru))
        lru.c = 3
        assert.are.same({ 3, 2 }, LruDict.values(lru))
        lru.b = 2
        assert.are.same({ 2, 3 }, LruDict.values(lru))
        lru.a = 1
        assert.are.same({ 1, 2 }, LruDict.values(lru))
    end)
end)

describe("__newindex", function()
    it("Does nothing when empty", function()
        local lru = LruDict(2)
        lru.a = nil
        assert.are.same({}, LruDict.values(lru))
    end)
    it("Removes single element", function()
        local lru = LruDict(2)
        lru.a = 1
        assert.are.same({ 1 }, LruDict.values(lru))
        lru.a = nil
        assert.are.same({}, LruDict.values(lru))
    end)
    it("Removes top element", function()
        local lru = LruDict(3)
        lru.a = 1
        lru.b = 2
        lru.c = 3
        assert.are.same({ 3, 2, 1 }, LruDict.values(lru))
        lru.c = nil
        assert.are.same({ 2, 1 }, LruDict.values(lru))
    end)
    it("Removes middle element", function()
        local lru = LruDict(3)
        lru.a = 1
        lru.b = 2
        lru.c = 3
        lru.b = nil
        assert.are.same({ 3, 1 }, LruDict.values(lru))
    end)
    it("Removes last element", function()
        local lru = LruDict(3)
        lru.a = 1
        lru.b = 2
        lru.c = 3
        assert.are.same({ 3, 2, 1 }, LruDict.values(lru))
        lru.a = nil
        assert.are.same({ 3, 2 }, LruDict.values(lru))
    end)
    it("Removes evicted element", function()
        local lru = LruDict(2)
        lru.a = 1
        lru.b = 2
        lru.c = 3
        assert.are.same({ 3, 2 }, LruDict.values(lru))
        lru.a = nil
        assert.are.same({ 3, 2 }, LruDict.values(lru))
    end)

    it("Updates the value", function()
        local lru = LruDict(2)
        lru.a = 1
        lru.b = 2
        lru.c = 3
        lru.a = 10
        assert.are.same({ 10, 3, 2 }, LruDict.values(lru))
    end)
end)
