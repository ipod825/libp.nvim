local path = require("libp.path")
local reflection = require("libp.debug.reflection")

describe("dirname", function()
    it("Returns parent for file", function()
        assert.are.same("/a", path.dirname("/a/b"))
    end)

    it("Returns directory for directory", function()
        assert.are.same("/a/b", path.dirname("/a/b/"))
    end)

    it("Works with root", function()
        assert.are.same("/", path.dirname("/a"))
    end)
end)

describe("basename", function()
    it("Works with file", function()
        assert.are.same("b", path.basename("a/b"))
    end)

    it("Works with directory", function()
        assert.are.same("b", path.basename("a/b/"))
    end)

    it("Works with root", function()
        assert.are.same("a", path.basename("/a"))
    end)
end)

describe("randomAlphaNumerical", function()
    it("Respects lenght argument", function()
        assert.are.same(3, #path.randomAlphaNumerical(3))
        assert.are.same(4, #path.randomAlphaNumerical(4))
    end)
end)

describe("join", function()
    it("Joins the paths", function()
        assert.are.same("a/b", path.join("a", "b"))
    end)
    it("Works when joinning root", function()
        assert.are.same("/a", path.join("/", "a"))
    end)
end)

describe("join_array", function()
    it("Joins the paths", function()
        assert.are.same("a/b", path.join_array({ "a", "b" }))
    end)
    it("Works when joinning root", function()
        assert.are.same("/a", path.join_array({ "/", "a" }))
    end)
end)

describe("find_directory", function()
    it("Finds first parent of the anchor", function()
        local wdir = path.dirname(vim.fn.tempname())
        local dir = wdir .. "/a/b/c/b/c"
        vim.fn.mkdir(dir, "p")
        assert.are.same(wdir .. "/a/b/c", path.find_directory("b", dir))
    end)

    it("Finds from current file path by default", function()
        local wdir = path.dirname(vim.fn.tempname())
        local dir = wdir .. "/a/b/c/b/c"
        vim.fn.mkdir(dir, "p")
        vim.cmd("cd " .. dir)
        vim.cmd("edit test_file")
        assert.are.same(wdir .. "/a/b/c", path.find_directory("b"))
    end)

    it("Finds from cwd by default", function()
        local wdir = path.dirname(vim.fn.tempname())
        local dir = wdir .. "/a/b/c/b/c"
        vim.fn.mkdir(dir, "p")
        vim.cmd("cd " .. dir)
        assert.are.same(wdir .. "/a/b/c", path.find_directory("b"))
    end)

    it("Works with multiple anchors", function()
        local wdir = path.dirname(vim.fn.tempname())
        local dir = wdir .. "/a/b/c/b/c"
        vim.fn.mkdir(dir, "p")
        local found_dir, base = path.find_directory({ "b", "f" }, dir)
        assert.are.same(wdir .. "/a/b/c", found_dir)
        assert.are.same(base, "b")

        found_dir, base = path.find_directory({ "c", "f" }, dir)
        assert.are.same(wdir .. "/a/b/c/b", found_dir)
        assert.are.same(base, "c")
    end)

    it("Finds first parent of the anchor", function()
        local wdir = path.dirname(vim.fn.tempname())
        local dir = wdir .. "/a/b/c/b/c"
        vim.fn.mkdir(dir, "p")
        assert.are.same(wdir .. "/a/b/c", path.find_directory("b", { dir, dir .. "/f" }))
        assert.is_nil(path.find_directory("k", { dir .. "/f", dir .. "/g" }))
    end)
end)
