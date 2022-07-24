require("plenary.async").tests.add_to_env()
local a = require("plenary.async")
local fs = require("libp.fs")

a.describe("list_dir", function()
	a.it("Lists the directories", function()
		local dir = vim.fn.tempname()
		vim.fn.mkdir(dir, "p")
		vim.fn.system(("touch %s/a"):format(dir))
		vim.fn.mkdir(dir .. "/b", "p")
		local res = fs.list_dir(dir)
		if res[1].name ~= "a" then
			res[1], res[2] = res[2], res[1]
		end
		assert.are.same({ { name = "a", type = "file" }, { name = "b", type = "directory" } }, res)
	end)
end)
