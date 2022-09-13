local devicon = require("libp.integration.web_devicon")
local reflection = require("libp.debug.reflection")

describe("setup", function()
    it("Default setup has no error", function()
        devicon.setup()
    end)

    it("setup with icon", function()
        devicon.setup({
            icons = {
                ranger = {
                    icon = "",
                },
            },
        })
        assert.are.same("", devicon.get("a.ranger").icon)
    end)

    it("setup with icon and highlight", function()
        devicon.setup({
            icons = {
                ranger = {
                    icon = "",
                    hl = {
                        fg = "#ffffff",
                        ctermfg = "white",
                    },
                },
            },
        })
        devicon.define_highlights()
        assert.is_truthy(vim.api.nvim_get_hl_by_name("LibpDevIconranger", false))
    end)
end)

describe("get", function()
    it("Works", function()
        assert.are.same("", devicon.get("LICENSE").icon)
        assert.are.same("", devicon.get(reflection.script_path()).icon)
        assert.are.same("", devicon.get("a.sh").icon)
        assert.are.same("", devicon.get("ranger://a/b").icon)
        assert.are.same("", devicon.get("rifle.conf").icon)
    end)
end)
