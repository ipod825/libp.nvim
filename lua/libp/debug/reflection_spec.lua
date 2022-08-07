local reflection = require("libp.debug.reflection")

describe("git_project_root", function()
    it("Returns the git root directory", function()
        assert.are.same(vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel")), reflection.git_project_root())
    end)
end)

describe("script_path", function()
    it("Returns the script path", function()
        assert.are.same(
            ("%s/%s"):format(reflection.git_project_root(), "lua/libp/debug/reflection_spec.lua"),
            reflection.script_path()
        )
    end)
end)

describe("script_dir", function()
    it("Returns the directory containing the script", function()
        assert.are.same(("%s/%s"):format(reflection.git_project_root(), "lua/libp/debug"), reflection.script_dir())
    end)
end)
