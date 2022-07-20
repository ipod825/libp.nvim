local functional = require("libp.functional")

describe("nop", function()
	it("Does nothing", function()
		functional.nop()
	end)
end)

describe("identity", function()
	it("Returns the argument", function()
		assert.are.same(1, functional.identity(1))
		assert.are.same(10, functional.identity(10))
	end)
end)

describe("oneshot", function()
	it("Returns a function that will be called only once", function()
		local var = 0
		local inc = functional.oneshot(function()
			var = var + 1
			return var
		end)
		assert.are.same(1, inc())
		assert.is_nil(inc())
		assert.are.same(1, var)
	end)
end)

describe("head_tail", function()
	it("Returns the argument", function()
		local arr = { 1, 2, 3 }
		local head, tail = functional.head_tail(arr)
		assert.are.same(1, head)
		assert.are.same({ 2, 3 }, tail)
	end)
end)
