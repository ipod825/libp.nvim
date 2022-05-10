local Lru = require("libp.datatype.Lru")
local Set = require("libp.datatype.Set")

describe("unordered_values", function()
	it("Returns empty list for empty lru", function()
		assert.are.same({}, Lru():unordered_values())
	end)
	it("Returns unordered values", function()
		local lru = Lru(100)
		lru:add(1)
		lru:add(2)
		lru:add(3)
		assert.are.same(Set({ 1, 2, 3 }), Set(lru:unordered_values()))
	end)
end)

describe("values", function()
	it("Returns empty list for empty lru", function()
		assert.are.same({}, Lru():values())
	end)
	it("Returns the values in order", function()
		local lru = Lru(100)
		lru:add(1)
		lru:add(2)
		lru:add(3)
		assert.are.same({ 3, 2, 1 }, lru:values())
	end)
end)

describe("top", function()
	it("Returns last added value", function()
		local lru = Lru(100)
		assert.are.same(nil, lru:top())
		lru:add(1)
		assert.are.same(1, lru:top())
		lru:add(2)
		assert.are.same(2, lru:top())
		lru:add(3)
		assert.are.same(3, lru:top())
		lru:add(1)
		assert.are.same(1, lru:top())
		lru:add(2)
		assert.are.same(2, lru:top())
		lru:add(3)
		assert.are.same(3, lru:top())
	end)
end)

describe("add", function()
	it("Maintains the mru order", function()
		local lru = Lru(100)
		lru:add(1)
		assert.are.same({ 1 }, lru:values())
		lru:add(2)
		assert.are.same({ 2, 1 }, lru:values())
		lru:add(3)
		assert.are.same({ 3, 2, 1 }, lru:values())
		lru:add(1)
		assert.are.same({ 1, 3, 2 }, lru:values())
		lru:add(2)
		assert.are.same({ 2, 1, 3 }, lru:values())
		lru:add(3)
		assert.are.same({ 3, 2, 1 }, lru:values())
	end)

	it("Respects the capacity", function()
		local lru = Lru(2)
		lru:add(1)
		assert.are.same({ 1 }, lru:values())
		lru:add(2)
		assert.are.same({ 2, 1 }, lru:values())
		lru:add(3)
		assert.are.same({ 3, 2 }, lru:values())
		lru:add(2)
		assert.are.same({ 2, 3 }, lru:values())
		lru:add(1)
		assert.are.same({ 1, 2 }, lru:values())
	end)
end)
