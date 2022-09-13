local devicon = require("libp.integration.web_devicon")
local reflection = require("libp.debug.reflection")

describe("setup", function()
    it("Has no error", function()
        devicon.setup()
    end)
end)

describe("get", function()
    it("Works", function()
        assert.are.same("", devicon.get("LICENSE").icon)
        assert.are.same("", devicon.get(reflection.script_path()).icon)
        assert.are.same("", devicon.get("a.sh").icon)
    end)
end)
