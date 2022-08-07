local List = require("libp.datatype.List")

describe("Constructor", function()
    it("Takes zero arguments", function()
        local l = List()
        assert.are.same({}, l)
    end)
end)

describe("append", function()
    it("Appends element", function()
        local l = List({ 1, 2 })
        l:append(3)
        assert.are.same({ 1, 2, 3 }, l)
    end)
end)

describe("extend", function()
    it("Extend list-like", function()
        local l = List({ 1, 2 })
        l:extend({ 3, 4 })
        assert.are.same({ 1, 2, 3, 4 }, l)
        l:extend(List({ 5, 6 }))
        assert.are.same({ 1, 2, 3, 4, 5, 6 }, l)
    end)
end)

describe("Concat(_add)", function()
    it("Returns concatenated list ", function()
        local l = List({ 1, 2 })
        local l1 = l + { 3, 4 }
        local l2 = l1 + { 5, 6 }
        assert.are.same({ 1, 2 }, l)
        assert.are.same({ 1, 2, 3, 4 }, l1)
        assert.are.same({ 1, 2, 3, 4, 5, 6 }, l2)
    end)
end)

describe("values", function()
    it("Iterates elements", function()
        local l = List({ 1, 2, 3, 4 })
        local i = 1
        for e in l:values() do
            assert.are.same(i, e)
            i = i + 1
        end
    end)
end)

describe("enumerate", function()
    it("Works with generic for", function()
        local l = List({ 1, 2, 3, 4 })
        for i, e in l:enumerate() do
            assert.are.same(i, e)
        end
    end)
end)

describe("to_iter", function()
    it("Returns a IterList", function()
        local it = List({ 1, 2, 3, 4 }):to_iter()
        assert.are.same({ 1, 2, 3, 4 }, it:collect())
    end)
end)

describe("map", function()
    it("Maps the list to another list", function()
        assert.are.same(
            { 2, 4, 6, 8 },
            List({ 1, 2, 3, 4 }):map(function(e)
                return e * 2
            end)
        )
    end)
end)

describe("filter", function()
    it("Filters the list to another list", function()
        assert.are.same(
            { 2, 4 },
            List({ 1, 2, 3, 4 }):filter(function(e)
                return e % 2 == 0
            end)
        )
    end)
end)

describe("sort", function()
    it("Sorts the list and returns self", function()
        local lst = List({ 1, 3, 2, 4 })
        local lst2 = lst:sort()
        assert.are.same({ 1, 2, 3, 4 }, lst2)
        assert.are.equal(lst, lst2)
    end)
    it("Takes table sort arguments", function()
        assert.are.same(
            { 4, 3, 2, 1 },
            List({ 1, 3, 2, 4 }):sort(function(a, b)
                return b < a
            end)
        )
    end)
end)

describe("for_each", function()
    it("Operates over each element", function()
        local sum = 0
        local indices = {}
        List({ 1, 2, 3, 4 }):for_each(function(e, i)
            sum = sum + e
            table.insert(indices, i)
        end)
        assert.are.same(10, sum)
        assert.are.same({ 1, 2, 3, 4 }, indices)
    end)
end)

describe("unbox_if_one", function()
    it("Returns 1st element if there's only one element", function()
        assert.are.same("a", List({ "a" }):unbox_if_one())
    end)
    it("Returns the list if there's multiple elements", function()
        local l = List({ "a", "b" })
        assert.are.same(l, l:unbox_if_one())
    end)
end)
