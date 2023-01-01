local highlight = require("libp.utils.term.highlight")
local color256_tbl = require("libp.utils.term.color256_tbl")

describe("setup", function()
    it("Respects default_color256_theme", function()
        highlight.setup({ default_color256_theme = "xterm", color256_override = {} })
        assert.are.same(color256_tbl["xterm"], highlight.color256_map)
    end)

    it("Respects color256_override", function()
        highlight.setup({ default_color256_theme = "kitty", color256_override = { [0] = "#123456" } })
        assert.are.same("#123456", highlight.color256_map[0])
    end)
end)

describe("parse_color_code", function()
    highlight.setup({ default_color256_theme = "kitty", color256_override = {} })
    local kitty = color256_tbl["kitty"]

    it("Is correct for single code", function()
        assert.are.same({}, highlight.parse_color_code("0", {}))
        assert.are.same({ bold = true }, highlight.parse_color_code("1", {}))
        assert.are.same({ italic = true }, highlight.parse_color_code("3", {}))
        assert.are.same({ underline = true }, highlight.parse_color_code("4", {}))
        assert.are.same({ reverse = true }, highlight.parse_color_code("7", {}))
        assert.are.same({ strikethrough = true }, highlight.parse_color_code("9", {}))
        assert.are.same({}, highlight.parse_color_code("21", { bold = true }))
        assert.are.same({}, highlight.parse_color_code("22", { bold = true }))
        assert.are.same({}, highlight.parse_color_code("23", { italic = true }))
        assert.are.same({}, highlight.parse_color_code("24", { underline = true }))
        assert.are.same({}, highlight.parse_color_code("27", { reverse = true }))
        assert.are.same({}, highlight.parse_color_code("29", { strikethrough = true }))

        assert.are.same({ ctermfg = 0, fg = kitty[0] }, highlight.parse_color_code("30", {}))
        assert.are.same({ ctermfg = 1, fg = kitty[1] }, highlight.parse_color_code("31", {}))
        assert.are.same({ ctermfg = 2, fg = kitty[2] }, highlight.parse_color_code("32", {}))
        assert.are.same({ ctermfg = 3, fg = kitty[3] }, highlight.parse_color_code("33", {}))
        assert.are.same({ ctermfg = 4, fg = kitty[4] }, highlight.parse_color_code("34", {}))
        assert.are.same({ ctermfg = 5, fg = kitty[5] }, highlight.parse_color_code("35", {}))
        assert.are.same({ ctermfg = 6, fg = kitty[6] }, highlight.parse_color_code("36", {}))
        assert.are.same({ ctermfg = 7, fg = kitty[7] }, highlight.parse_color_code("37", {}))

        assert.are.same({ ctermbg = 0, bg = kitty[0] }, highlight.parse_color_code("40", {}))
        assert.are.same({ ctermbg = 1, bg = kitty[1] }, highlight.parse_color_code("41", {}))
        assert.are.same({ ctermbg = 2, bg = kitty[2] }, highlight.parse_color_code("42", {}))
        assert.are.same({ ctermbg = 3, bg = kitty[3] }, highlight.parse_color_code("43", {}))
        assert.are.same({ ctermbg = 4, bg = kitty[4] }, highlight.parse_color_code("44", {}))
        assert.are.same({ ctermbg = 5, bg = kitty[5] }, highlight.parse_color_code("45", {}))
        assert.are.same({ ctermbg = 6, bg = kitty[6] }, highlight.parse_color_code("46", {}))
        assert.are.same({ ctermbg = 7, bg = kitty[7] }, highlight.parse_color_code("47", {}))

        assert.are.same({ ctermfg = 8, fg = kitty[8] }, highlight.parse_color_code("90", {}))
        assert.are.same({ ctermfg = 9, fg = kitty[9] }, highlight.parse_color_code("91", {}))
        assert.are.same({ ctermfg = 10, fg = kitty[10] }, highlight.parse_color_code("92", {}))
        assert.are.same({ ctermfg = 11, fg = kitty[11] }, highlight.parse_color_code("93", {}))
        assert.are.same({ ctermfg = 12, fg = kitty[12] }, highlight.parse_color_code("94", {}))
        assert.are.same({ ctermfg = 13, fg = kitty[13] }, highlight.parse_color_code("95", {}))
        assert.are.same({ ctermfg = 14, fg = kitty[14] }, highlight.parse_color_code("96", {}))
        assert.are.same({ ctermfg = 15, fg = kitty[15] }, highlight.parse_color_code("97", {}))

        assert.are.same({ ctermbg = 8, bg = kitty[8] }, highlight.parse_color_code("100", {}))
        assert.are.same({ ctermbg = 9, bg = kitty[9] }, highlight.parse_color_code("101", {}))
        assert.are.same({ ctermbg = 10, bg = kitty[10] }, highlight.parse_color_code("102", {}))
        assert.are.same({ ctermbg = 11, bg = kitty[11] }, highlight.parse_color_code("103", {}))
        assert.are.same({ ctermbg = 12, bg = kitty[12] }, highlight.parse_color_code("104", {}))
        assert.are.same({ ctermbg = 13, bg = kitty[13] }, highlight.parse_color_code("105", {}))
        assert.are.same({ ctermbg = 14, bg = kitty[14] }, highlight.parse_color_code("106", {}))
        assert.are.same({ ctermbg = 15, bg = kitty[15] }, highlight.parse_color_code("107", {}))
    end)

    it("Is correct for 256 color", function()
        assert.are.same({ ctermfg = 123, fg = kitty[123] }, highlight.parse_color_code("38;5;123", {}))
        assert.are.same({ ctermfg = 55, fg = kitty[55] }, highlight.parse_color_code("38:5:55", {}))
        assert.are.same({ ctermbg = 123, bg = kitty[123] }, highlight.parse_color_code("48;5;123", {}))
        assert.are.same({ ctermbg = 55, bg = kitty[55] }, highlight.parse_color_code("48:5:55", {}))
    end)

    it("Is correct for true color", function()
        assert.are.same({ fg = "#010203" }, highlight.parse_color_code("38;2;1;2;3", {}))
        assert.are.same({ fg = "#FF0F0F" }, highlight.parse_color_code("38:2:255:15:15", {}))
        assert.are.same({ bg = "#010203" }, highlight.parse_color_code("48;2;1;2;3", {}))
        assert.are.same({ bg = "#FF0F0F" }, highlight.parse_color_code("48:2:255:15:15", {}))
    end)

    it("Accepts attribute/color combination", function()
        assert.are.same(
            { ctermfg = 123, fg = kitty[123], underline = true, bold = true },
            highlight.parse_color_code("38;5;123;1;4", {})
        )
        assert.are.same(
            { bg = "#FF0F0F", reverse = true, strikethrough = true },
            highlight.parse_color_code("48;2;255;15;15;7;9", {})
        )
    end)
end)

describe("get_ansi_code_highlight", function()
    describe("Single line", function()
        it("Returned reset attributes not carry over if reset at the end", function()
            local marks, attributes = highlight.get_ansi_code_highlight({ "[4mA[m" }, {})
            assert.are.same({ { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 } }, marks)
            assert.are.same({}, attributes)

            marks, attributes = highlight.get_ansi_code_highlight({ "[4mA[0m" }, {})
            assert.are.same({ { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 } }, marks)
            assert.are.same({}, attributes)

            marks, attributes = highlight.get_ansi_code_highlight({ "[4mA[4;0m" }, {})
            assert.are.same({ { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 } }, marks)
            assert.are.same({}, attributes)
        end)

        it("Returned attributes carry over if not reset at the end", function()
            local marks, attributes = highlight.get_ansi_code_highlight({ "[4mA" }, {})
            assert.are.same({ { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 } }, marks)
            assert.are.same({ underline = true }, attributes)
        end)

        it("Returns multiple marks", function()
            local marks = highlight.get_ansi_code_highlight({ "[4mA[1m[3mBC [m" }, {})
            assert.are.same({
                { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 },
                { hl_group = "libpterm_bld_itl_udl", line = 0, col_start = 1, col_end = 4 },
            }, marks)

            marks = highlight.get_ansi_code_highlight({ "[4mA[1m[3mBC " }, {})
            assert.are.same({
                { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 },
                { hl_group = "libpterm_bld_itl_udl", line = 0, col_start = 1, col_end = 4 },
            }, marks)
        end)
    end)

    describe("Two lines", function()
        it("Attributes carries over to the second line if not reset", function()
            local marks, attributes = highlight.get_ansi_code_highlight({ "[4mA", "B[m[3mC" }, {})
            assert.are.same({
                { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 },
                { hl_group = "libpterm_udl", line = 1, col_start = 0, col_end = 1 },
                { hl_group = "libpterm_itl", line = 1, col_start = 1, col_end = 2 },
            }, marks)
            assert.are.same({ italic = true }, attributes)
        end)

        it("Attributes does not carry over to the second line if reset", function()
            local marks, attributes = highlight.get_ansi_code_highlight({ "[4mA[m", "B[m[3mC[m" }, {})
            assert.are.same({
                { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 },
                { hl_group = "libpterm_itl", line = 1, col_start = 1, col_end = 2 },
            }, marks)
            assert.are.same({}, attributes)
        end)
    end)

    it("Accepts optional carry over attributes", function()
        local previous_attributes = { underline = true }
        local marks, attributes = highlight.get_ansi_code_highlight({ "B[m[3mC[m" }, previous_attributes)
        assert.are.same({
            { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 },
            { hl_group = "libpterm_itl", line = 0, col_start = 1, col_end = 2 },
        }, marks)
        assert.are.same({}, attributes)

        previous_attributes = { underline = true }
        marks, attributes = highlight.get_ansi_code_highlight({ "B[m[3mC" }, previous_attributes)
        assert.are.same({
            { hl_group = "libpterm_udl", line = 0, col_start = 0, col_end = 1 },
            { hl_group = "libpterm_itl", line = 0, col_start = 1, col_end = 2 },
        }, marks)
        assert.are.same({ italic = true }, attributes)
    end)

    it("Accepts optional row_offset", function()
        local marks, attributes = highlight.get_ansi_code_highlight({ "B[m[3mC[m" }, nil, 10)
        assert.are.same({
            { hl_group = "libpterm_itl", line = 10, col_start = 1, col_end = 2 },
        }, marks)
    end)
end)
