require("plenary.async").tests.add_to_env()
local a = require("plenary.async")
local fs = require("libp.fs")

local function it_sync_and_async(description, fn)
	it(description .. " in sync context", fn)
	a.it(description .. " in async context", fn)
end

a.describe("list_dir", function()
	it_sync_and_async("Returns fail when directory does not exist", function()
		local res, err = fs.list_dir("no_such_dir")
		assert.is_falsy(res)
		assert.is_truthy(err)
	end)
	it_sync_and_async("Lists the directories", function()
		local dir = vim.fn.tempname()
		vim.fn.mkdir(dir, "p")
		vim.fn.system(("touch %s/a"):format(dir))
		vim.fn.mkdir(dir .. "/b", "p")
		local res = fs.list_dir(dir)
		assert.is_truthy(res)
		if res and res[1].name ~= "a" then
			res[1], res[2] = res[2], res[1]
		end
		assert.are.same({ { name = "a", type = "file" }, { name = "b", type = "directory" } }, res)
	end)
end)

a.describe("copy", function()
	-- TODO(smwang): Finish the tests.
	it("Copies file", function() end)
	it("Copies directory", function() end)
end)
