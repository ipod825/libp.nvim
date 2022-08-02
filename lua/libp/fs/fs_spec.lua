require("plenary.async").tests.add_to_env()
local a = require("plenary.async")
local fs = require("libp.fs")
local reflection = require("libp.debug.reflection")

local function itsa(description, fn)
	it(description .. " in sync context", fn)
	a.it(description .. " in async context", fn)
end

-- TODO(smwang): add modifier fs. fs.succ, fs.fail, fs.same
local function fs_succ(state, arguments)
	local res, err = arguments[1], arguments[2]
	return res and (err == nil)
end

local function fs_fail(state, arguments)
	local res, err = arguments[1], arguments[2]
	state.failure_message = ([[
    Expect fs operation fail
    Passed in:
    %s, %s
    Expected:
    non-nil, nil
    ]]):format(res, err)
	return res == nil and err
end

assert:register("assertion", "fs_succ", fs_succ, "pos", "neg")
assert:register("assertion", "fs_fail", fs_fail, "pos", "neg")

describe("stat_mode_num", function()
	itsa("Returns number version of file mode", function()
		assert.are.same(52, fs.stat_mode_num("064"))
		assert.are.same(493, fs.stat_mode_num("755"))
	end)
end)

describe("is_readable", function()
	itsa("Returns if file is readable", function()
		assert.is.fs_succ(fs.is_readable(reflection.script_path()))
		assert.is.fs_fail(fs.is_readable("no_such_file"))
	end)

	itsa("Returns if directory is readable", function()
		assert.is.fs_succ(fs.is_readable(reflection.script_dir()))
		assert.is.fs_fail(fs.is_readable("no_such_directory"))
	end)
	-- TODO: Test file exists but not readable.
end)

describe("get_mode_string", function()
	-- TODO(smwang): todo
end)

describe("touch", function()
	itsa("Creates a file", function()
		local tmp = vim.fn.tempname()
		assert.is.fs_succ(fs.touch(tmp))
		assert.is.fs_succ(fs.is_readable(tmp))
	end)
	it("Accepts mode", function()
		-- TODO(smwang): todo
	end)
end)

a.describe("list_dir", function()
	itsa("Returns fail when directory does not exist", function()
		local res, err = fs.list_dir("no_such_dir")
		assert.is_falsy(res)
		assert.is_truthy(err)
	end)
	itsa("Lists the directories", function()
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
	itsa("Copies file", function() end)
	itsa("Copies directory", function() end)
end)
