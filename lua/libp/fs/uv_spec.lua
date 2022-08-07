require("plenary.async").tests.add_to_env()
local uv = require("libp.fs.uv")
local auv = require("libp.fs.uv_async")

describe("__index", function()
    it("Gets vim.loop function in main thread", function()
        assert.are.equal(vim.loop.fs_open, uv.fs_open)
    end)

    a.it("Gets uv_async function in couroutine thread", function()
        assert.are.equal(auv.fs_open, uv.fs_open)
    end)
end)
