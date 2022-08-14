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

describe("map", function()
    it("Maps the list to another list", function()
        assert.are.same(
            { 2, 4, 6, 8 },
            List({ 1, 2, 3, 4 }):map(function(v)
                return v * 2
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

describe("unbox_if_one", function()
    it("Returns 1st element if there's only one element", function()
        assert.are.same("a", List({ "a" }):unbox_if_one())
    end)
    it("Returns the list if there's multiple elements", function()
        local l = List({ "a", "b" })
        assert.are.same(l, l:unbox_if_one())
    end)
end)

describe("slicing", function()
    it("Returns the slice of the list", function()
        assert.are.same({ 2, 3, 4 }, List({ 1, 2, 3, 4 })[{ 2 }])
        assert.are.same({ 2, 3 }, List({ 1, 2, 3, 4 })[{ 2, 3 }])
        assert.are.same({ 1, 2, 3 }, List({ 1, 2, 3, 4 })[{ nil, 3 }])
        assert.is_nil(List({ 1, 2, 3, 4 })[0])
        assert.are.same(4, List({ 1, 2, 3, 4 })[4])
        assert.is_nil(List({ 1, 2, 3, 4 })[5])
    end)
end)
