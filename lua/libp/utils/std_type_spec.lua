local std_type = require("libp.utils.std_type")
local List = require("libp.datatype.List")

describe("reverse", function()
	it("Reverses a list", function()
		assert.are.same({}, std_type.reverse({}))
		assert.are.same({ 4, 3, 2, 1 }, std_type.reverse({ 1, 2, 3, 4 }))
	end)
end)

describe("weak_reference", function()
	it("Makes reference weak", function()
		local a = {}
		local b = std_type.weak_reference({})
		a.b = b
		b.a = a
		assert.is_truthy(a)
		assert.is_truthy(b.a)

		a = nil
		collectgarbage("collect")

		assert.is_nil(a)
		assert.is_nil(b.a)
	end)
	it("Works with non-trivial type", function()
		local a = {}
		local b = std_type.weak_reference(List({ a }))
		a.b = b
		b:append(a)

		assert.is_truthy(a)
		assert.is_truthy(b[1])
		assert.is_truthy(b[2])

		a = nil
		collectgarbage("collect")

		assert.is_nil(a)
		assert.is_nil(b[1])
		assert.is_nil(b[2])
	end)
end)
