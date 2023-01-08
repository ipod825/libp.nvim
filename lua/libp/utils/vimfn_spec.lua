local vimfn = require("libp.utils.vimfn")
local spy = require("luassert.spy")
local reflection = require("libp.debug.reflection")
local pathfn = require("libp.utils.pathfn")

describe("notify family", function()
    local notify = spy.on(vim, "notify")
    after_each(function()
        notify:clear()
    end)
    describe("info", function()
        it("Notify with info level", function()
            vimfn.info("msg")
            assert.spy(notify).was_called_with("msg", vim.log.levels.INFO)
        end)
    end)
    describe("warn", function()
        it("Notify with warn level", function()
            vimfn.warn("msg")
            assert.spy(notify).was_called_with("msg", vim.log.levels.WARN)
        end)
    end)
    describe("error", function()
        it("Notify with warn level", function()
            vimfn.error("msg")
            assert.spy(notify).was_called_with("msg", vim.log.levels.ERROR)
        end)
    end)
end)

describe("visual_rows", function()
    it("Returns current row in normal mode", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
        vim.cmd("normal! j")

        local row_beg, row_end = vimfn.visual_rows()
        assert.are.same(2, row_beg)
        assert.are.same(2, row_end)
    end)
    it("Returns seleted row beg and end", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
        vim.cmd("normal! ggVG")

        local row_beg, row_end = vimfn.visual_rows()
        assert.are.same(1, row_beg)
        assert.are.same(3, row_end)
    end)
end)

describe("ensure_exit_visual_mode", function()
    it("Stays in normal mode when called in normal mode.", function()
        vimfn.ensure_exit_visual_mode()
        assert.are.same("n", vim.fn.mode())
        vimfn.ensure_exit_visual_mode()
        assert.are.same("n", vim.fn.mode())
    end)
    it("Exit visual mode when called in visual line mode.", function()
        vimfn.ensure_exit_visual_mode()
        vim.cmd("normal! V")
        assert.are.same("V", vim.fn.mode())
        vimfn.ensure_exit_visual_mode()
        assert.are.same("n", vim.fn.mode())
    end)
    it("Exit visual mode when called in visual char mode.", function()
        vimfn.ensure_exit_visual_mode()
        vim.cmd("normal! v")
        assert.are.same("v", vim.fn.mode())
        vimfn.ensure_exit_visual_mode()
        assert.are.same("n", vim.fn.mode())
    end)
end)

describe("selected_rows", function()
    it("Selects the specified rows", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })

        vimfn.visual_select_rows(2, 3)
        local row_beg, row_end = vimfn.visual_rows()
        assert.are.same(2, row_beg)
        assert.are.same(3, row_end)

        vimfn.visual_select_rows(1, 3)
        row_beg, row_end = vimfn.visual_rows()

        assert.are.same(1, row_beg)
        assert.are.same(3, row_end)
    end)
end)

describe("setrow", function()
    it("Sets the row", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
        vimfn.setrow(1)
        assert.are.same(1, vim.api.nvim_win_get_cursor(0)[1])
        vimfn.setrow(2)
        assert.are.same(2, vim.api.nvim_win_get_cursor(0)[1])
    end)

    it("Handles out of bound", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
        vimfn.setrow(2)
        vimfn.setrow(-1)
        assert.are.same(1, vim.api.nvim_win_get_cursor(0)[1])
        vimfn.setrow(4)
        assert.are.same(3, vim.api.nvim_win_get_cursor(0)[1])
    end)

    it("Takes an optional window", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
        local ori_win = vim.api.nvim_get_current_win()
        vim.cmd("vsp")
        local cur_win = vim.api.nvim_get_current_win()
        vimfn.setrow(1, ori_win)
        assert.are.same(1, vim.api.nvim_win_get_cursor(ori_win)[1])
        vimfn.setrow(2, cur_win)
        assert.are.same(2, vim.api.nvim_win_get_cursor(cur_win)[1])
    end)
end)

describe("setcol", function()
    it("Sets the col", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ab", "cde" })
        vimfn.setrow(1)
        vimfn.setcol(1)
        assert.are.same({ 1, 0 }, vim.api.nvim_win_get_cursor(0))
        vimfn.setcol(2)
        assert.are.same({ 1, 1 }, vim.api.nvim_win_get_cursor(0))

        vimfn.setrow(2)
        vimfn.setcol(2)
        assert.are.same({ 2, 1 }, vim.api.nvim_win_get_cursor(0))
        vimfn.setcol(3)
        assert.are.same({ 2, 2 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("Handles out of bound", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ab", "cde" })
        vimfn.setrow(2)
        vimfn.setcol(2)
        vimfn.setcol(-1)
        assert.are.same({ 2, 0 }, vim.api.nvim_win_get_cursor(0))
        vimfn.setcol(4)
        assert.are.same({ 2, 2 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("Takes an optional window", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ab", "cde" })
        vimfn.setrow(2)
        vimfn.setcol(1)
        local ori_win = vim.api.nvim_get_current_win()
        vim.cmd("vsp")
        local cur_win = vim.api.nvim_get_current_win()
        vimfn.setcol(2, ori_win)
        vimfn.setcol(3, cur_win)
        assert.are.same(1, vim.api.nvim_win_get_cursor(ori_win)[2])
        assert.are.same(2, vim.api.nvim_win_get_cursor(cur_win)[2])
    end)
end)

describe("first_visible_line", function()
    it("Returns seleted row beg and end", function()
        local content = {}
        for i = 1, 2 * vim.o.lines do
            table.insert(content, tostring(i))
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, content)

        assert.are.same(1, vimfn.first_visible_line())
        assert.are.same(vim.o.lines - 2, vimfn.last_visible_line())

        vim.cmd("normal! ")
        assert.are.same(2, vimfn.first_visible_line())
        assert.are.same(vim.o.lines - 1, vimfn.last_visible_line())
    end)
end)

describe("all_rows", function()
    it("Returns 1, line('$')", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })

        local row_beg, row_end = vimfn.all_rows()
        assert.are.same(1, row_beg)
        assert.are.same(3, row_end)
    end)
end)

describe("getrow", function()
    it("Returns the current row", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
        vimfn.setrow(1)
        assert.are.same(1, vimfn.getrow())
        vimfn.setrow(2)
        assert.are.same(2, vimfn.getrow())
        vimfn.setrow(3)
        assert.are.same(3, vimfn.getrow())
    end)
    it("Takes optional window id", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
        local ori_win = vim.api.nvim_get_current_win()
        vim.cmd("vsp")
        local cur_win = vim.api.nvim_get_current_win()
        vimfn.setrow(1, cur_win)

        vimfn.setrow(1, ori_win)
        assert.are.same(1, vimfn.getrow(ori_win))
        vimfn.setrow(2, ori_win)
        assert.are.same(2, vimfn.getrow(ori_win))
        vimfn.setrow(3, ori_win)
        assert.are.same(3, vimfn.getrow(ori_win))
        assert.are.same(1, vimfn.getrow(cur_win))
    end)
end)

describe("getcol", function()
    it("Returns the current row", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ab", "cde", "fghi" })
        vimfn.setrow(3)
        vimfn.setcol(1)
        assert.are.same(1, vimfn.getcol())
        vimfn.setcol(2)
        assert.are.same(2, vimfn.getcol())
        vimfn.setcol(3)
        assert.are.same(3, vimfn.getcol())
    end)
    it("Takes optional window id", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ab", "cde", "fghi" })
        vimfn.setrow(1)
        vimfn.setcol(1)
        local ori_win = vim.api.nvim_get_current_win()
        vim.cmd("vsp")
        local cur_win = vim.api.nvim_get_current_win()

        vimfn.setrow(3, ori_win)
        vimfn.setcol(1, ori_win)
        assert.are.same(1, vimfn.getcol(ori_win))
        vimfn.setcol(2, ori_win)
        assert.are.same(2, vimfn.getcol(ori_win))
        vimfn.setcol(3, ori_win)
        assert.are.same(3, vimfn.getcol(ori_win))
        assert.are.same(1, vimfn.getcol(cur_win))
        assert.are.same(1, vimfn.getcol(cur_win))
    end)
end)

describe("editable_width", function()
    it("Returns width excluding gutter", function()
        vim.o.number = false
        local ori_winwidth = vim.api.nvim_win_get_width(0)
        assert.are.same(ori_winwidth, vimfn.editable_width(0))
        vim.o.number = true
        assert.are.same(ori_winwidth - 4, vimfn.editable_width(0))
        vim.o.number = false
    end)
end)

describe("win_get_var", function()
    it("Returns nil if variable missing", function()
        assert.is_nil(vimfn.win_get_var(0, "no_such_var"))
    end)

    it("Returns the window variable if present", function()
        vim.api.nvim_win_set_var(0, "var", 1)
        assert.are.same(1, vimfn.win_get_var(0, "var"))
    end)
end)

describe("buf_get_var", function()
    it("Returns nil if variable missing", function()
        assert.is_nil(vimfn.buf_get_var(0, "no_such_var"))
    end)

    it("Returns the bufdow variable if present", function()
        vim.api.nvim_buf_set_var(0, "var", 1)
        assert.are.same(1, vimfn.buf_get_var(0, "var"))
    end)
end)

describe("buf_get_lines", function()
    before_each(function()
        vim.api.nvim_buf_set_lines(0, 0, -1, true, { "a", "b", "c" })
    end)
    after_each(function()
        vim.cmd("bwipeout!")
    end)

    it("Defaults buffer to 0 start to 0 ends to -1", function()
        assert.are.same({ "a", "b", "c" }, vimfn.buf_get_lines())
    end)

    it("Accepts start", function()
        assert.are.same({ "b", "c" }, vimfn.buf_get_lines({ buffer = 0, start = 1 }))
    end)

    it("Accepts ends", function()
        assert.are.same({ "a", "b" }, vimfn.buf_get_lines({ buffer = 0, ends = 2 }))
    end)

    it("Defaults strict_indexing to false", function()
        assert.has.errors(function()
            vimfn.buf_get_lines({ buffer = 0, ends = 20 })
        end)
    end)

    it("Accepts strict indexing", function()
        assert.are.same({ "a", "b", "c" }, vimfn.buf_get_lines({ buffer = 0, ends = 20, strict_indexing = false }))
    end)
end)

describe("buf_get_line", function()
    before_each(function()
        vim.api.nvim_buf_set_lines(0, 0, -1, true, { "a", "b", "c" })
    end)
    after_each(function()
        vim.cmd("bwipeout!")
    end)

    it("Defaults buffer to 0 ", function()
        assert.are.same("a", vimfn.buf_get_line(0))
        assert.are.same("b", vimfn.buf_get_line(1))
        assert.are.same("c", vimfn.buf_get_line(2))
        assert.has.errors(function()
            vimfn.buf_get_line(3)
        end)
    end)

    it("Accepts buffer", function()
        assert.are.same("a", vimfn.buf_get_line(0,0))
    end)
end)

describe("str_to_char", function()
    it("Returns characters of a string", function()
        assert.are.same({ "中", "文" }, vimfn.str_to_char("中文"))
        assert.are.same({ "に", "ほ", "ん", "ご" }, vimfn.str_to_char("にほんご"))
        assert.are.same({ "한", "국", "인" }, vimfn.str_to_char("한국인"))
        assert.are.same({ "e", "n", "g", "l", "i", "s", "h" }, vimfn.str_to_char("english"))
        assert.are.same({ "中", "e", "に", "한" }, vimfn.str_to_char("中eに한"))
    end)
end)

describe("set_cwd", function()
    it("sets the cwd", function()
        local ori_cwd = vim.fn.getcwd()
        vimfn.set_cwd(vim.fn.getcwd() .. "/..")
        assert.are.same(pathfn.dirname(ori_cwd), vim.fn.getcwd())
    end)
end)

describe("tabline_end_pos", function()
    it("Returns 1 if tabline not visible", function()
        assert.are.same(1, vimfn.tabline_end_pos())

        local ori = vim.o.showtabline
        vim.o.showtabline = 0

        vim.cmd("tabe")
        assert.are.same(1, vimfn.tabline_end_pos())

        vim.cmd("tabc")
        vim.o.showtabline = ori
    end)

    it("Returns 2 if tabline is shown", function()
        assert.are.same(1, vimfn.tabline_end_pos())

        local ori = vim.o.showtabline
        vim.o.showtabline = 1

        vim.cmd("tabe")
        assert.are.same(2, vimfn.tabline_end_pos())

        vim.cmd("tabc")
        vim.o.showtabline = ori
    end)

    it("Returns 2 if tabline always shown", function()
        local ori = vim.o.showtabline
        vim.o.showtabline = 2

        vim.cmd("tabe")
        assert.are.same(2, vimfn.tabline_end_pos())

        vim.cmd("tabc")
        vim.o.showtabline = ori
    end)
end)

describe("buf_get_option_and_set", function()
    it("Get nil when buf is invalid", function()
        assert.is_nil(vimfn.buf_get_option_and_set(-1))
    end)
    it("Set the option and returns the original", function()
        local expected = vim.api.nvim_buf_get_option(0, "autoindent")
        local ori = vimfn.buf_get_option_and_set(0, "autoindent", not expected)
        assert.are.same(expected, ori)
        assert.are.not_same(expected, vim.api.nvim_buf_get_option(0, "autoindent"))
        vimfn.buf_get_option_and_set(0, "autoindent", ori)
        assert.are.same(expected, vim.api.nvim_buf_get_option(0, "autoindent"))
    end)
end)

describe("win_get_option_and_set", function()
    it("Get nil when win is invalid", function()
        assert.is_nil(vimfn.win_get_option_and_set(-1))
    end)
    it("Set the option and returns the original", function()
        local expected = vim.api.nvim_win_get_option(0, "breakindent")
        local ori = vimfn.win_get_option_and_set(0, "breakindent", not expected)
        assert.are.same(expected, ori)
        assert.are.not_same(expected, vim.api.nvim_win_get_option(0, "breakindent"))
        vimfn.win_get_option_and_set(0, "breakindent", ori)
        assert.are.same(expected, vim.api.nvim_win_get_option(0, "breakindent"))
    end)
end)
