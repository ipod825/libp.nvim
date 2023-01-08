require("plenary.async").tests.add_to_env()
local Menu = require("libp.ui.Menu")
local vimfn = require("libp.utils.vimfn")

describe("init", function()
    local m
    describe("width/height", function()
        it("Works with no title", function()
            m = Menu({ content = { "a" } })
            m:show()
            assert.are.same(1, vim.api.nvim_win_get_width(m:get_inner_window().id))
            assert.are.same(3, vim.api.nvim_win_get_width(m:get_border_window().id))
            assert.are.same(1, vim.api.nvim_win_get_height(m:get_inner_window().id))
            assert.are.same(3, vim.api.nvim_win_get_height(m:get_border_window().id))
            m:close()

            m = Menu({ content = { "ab", "c" } })
            m:show()
            assert.are.same(2, vim.api.nvim_win_get_width(m:get_inner_window().id))
            assert.are.same(4, vim.api.nvim_win_get_width(m:get_border_window().id))
            assert.are.same(2, vim.api.nvim_win_get_height(m:get_inner_window().id))
            assert.are.same(4, vim.api.nvim_win_get_height(m:get_border_window().id))
            m:close()
        end)

        it("Works when title dominates", function()
            m = Menu({ title = "Ti", content = { "a" } })
            m:show()
            assert.are.same(6, vim.api.nvim_win_get_width(m:get_inner_window().id))
            assert.are.same(8, vim.api.nvim_win_get_width(m:get_border_window().id))
            assert.are.same(1, vim.api.nvim_win_get_height(m:get_inner_window().id))
            assert.are.same(3, vim.api.nvim_win_get_height(m:get_border_window().id))
            m:close()

            m = Menu({ title = "Title", content = { "a", "bc" } })
            m:show()
            assert.are.same(9, vim.api.nvim_win_get_width(m:get_inner_window().id))
            assert.are.same(11, vim.api.nvim_win_get_width(m:get_border_window().id))
            assert.are.same(2, vim.api.nvim_win_get_height(m:get_inner_window().id))
            assert.are.same(4, vim.api.nvim_win_get_height(m:get_border_window().id))
            m:close()
        end)
    end)

    describe("cursor_offset", function() end)

    describe("short_key_map", function()
        it("Sets the item content and map", function()
            local selected = nil
            m = Menu({
                content = { "item a", "item c" },
                short_key_map = { "a", "c" },
                on_select = function(item)
                    selected = item
                end,
            })
            m:show()
            assert.are.same({ "a. item a", "c. item c" }, vimfn.buf_get_lines())
            vim.fn.feedkeys("c", "x")
            assert.are.same("item c", selected)
        end)
    end)

    describe("select_map", function()
        it("Maps the selected content", function()
            local selected = nil
            m = Menu({
                content = { "item a", "item c" },
                select_map = { "a", "c" },
                on_select = function(item)
                    selected = item
                end,
            })
            m:show()
            m:confirm(2)
            assert.are.same("c", selected)
        end)
    end)

    describe("wo", function()
        it("Sets the inner window option", function()
            m = Menu({ content = { "a" }, wo = { diff = true } })
            m:show()
            assert.is_true(vim.api.nvim_win_get_option(0, "diff"))
            m:close()
        end)
    end)
end)

describe("Selection", function()
    it("Works in main thread", function()
        local selected = nil
        local m = Menu({
            content = { "a", "b", "c" },
            on_select = function(item)
                selected = item
            end,
        })
        m:show()
        m:confirm(2)
        assert.are.same("b", selected)
    end)

    a.it("Works in coroutine thread", function()
        Menu.will_select_from_menu(function()
            return 2
        end)
        local res = Menu({
            content = { "a", "b", "c" },
        }):select()
        assert.are.same("b", res)
    end)
end)

describe("Quit without selection", function()
    it("Works in main thread", function()
        local selected = nil
        local m = Menu({
            content = { "a", "b", "c" },
            on_select = function(item)
                selected = item
            end,
        })
        m:show()
        m:close()
        assert.is_nil(selected)
    end)

    a.it("Works in coroutine thread", function()
        Menu.will_select_from_menu(function() end)
        local res = Menu({
            content = { "a", "b", "c" },
        }):select()
        assert.is_nil(res)
    end)
end)
