local BorderWindow = require("libp.ui.BorderWindow")
local vimfn = require("libp.utils.vimfn")

function open_box(b, width, height)
    b:open({
        relative = "editor",
        width = width,
        height = height,
        row = 10,
        col = 20,
        zindex = 1,
        anchor = "NW",
    })
end

describe("open", function()
    it("Sets the border content", function()
        local b = BorderWindow({ title = "Title", border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" } })
        local width = 40
        local height = 5
        open_box(b, width, height)

        local contents = vimfn.buf_get_lines({ buffer = b.buffer.id })

        assert.is_true(vim.startswith(contents[1], "┌─"))
        assert.is_true(vim.endswith(contents[1], "─┐"))
        assert.is_truthy(contents[1]:match(" Title "))

        local middle_line = ("│%s│"):format((" "):rep(width - 2))
        for i = 2, height - 1 do
            assert.are.same(contents[i], middle_line)
        end

        assert.is_true(vim.startswith(contents[height], "└─"))
        assert.is_true(vim.endswith(contents[height], "─┘"))
        assert.is_falsy(contents[height]:match(" "))
    end)

    it("Does not set title line if top borders are missing", function()
        local b = BorderWindow({ title = "Title", border = { nil, nil, nil, "│", "┘", "─", "└", "│" } })
        local width = 40
        local height = 5
        open_box(b, width, height)

        local contents = vimfn.buf_get_lines({ buffer = b.buffer.id })

        local middle_line = ("│%s│"):format((" "):rep(width - 2))
        for i = 1, height - 1 do
            assert.are.same(contents[i], middle_line)
        end

        assert.is_true(vim.startswith(contents[height], "└─"))
        assert.is_true(vim.endswith(contents[height], "─┘"))
        assert.is_falsy(contents[height]:match(" "))
    end)

    it("Does not set bottom line if bottom borders are missing", function()
        local b = BorderWindow({ title = "Title", border = { "┌", "─", "┐", "│", nil, nil, nil, "│" } })
        local width = 40
        local height = 5
        open_box(b, width, height)

        local contents = vimfn.buf_get_lines({ buffer = b.buffer.id })

        assert.is_true(vim.startswith(contents[1], "┌─"))
        assert.is_true(vim.endswith(contents[1], "─┐"))
        assert.is_truthy(contents[1]:match(" Title "))

        local middle_line = ("│%s│"):format((" "):rep(width - 2))
        for i = 2, height do
            assert.are.same(contents[i], middle_line)
        end
    end)

    it("Does not set left line if left borders are missing", function()
        local b = BorderWindow({ title = "Title", border = { nil, "─", "┐", "│", "┘", "─", nil, nil } })
        local width = 40
        local height = 5
        open_box(b, width, height)

        local contents = vimfn.buf_get_lines({ buffer = b.buffer.id })

        assert.is_true(vim.startswith(contents[1], "─"))
        assert.is_true(vim.endswith(contents[1], "─┐"))
        assert.is_truthy(contents[1]:match(" Title "))

        local middle_line = ("%s│"):format((" "):rep(width - 1))
        for i = 2, height - 1 do
            assert.are.same(contents[i], middle_line)
        end

        assert.is_true(vim.startswith(contents[height], "─"))
        assert.is_true(vim.endswith(contents[height], "─┘"))
        assert.is_falsy(contents[height]:match(" "))
    end)

    it("Does not set right line if right borders are missing", function()
        local b = BorderWindow({ title = "Title", border = { "┌", "─", nil, nil, nil, "─", "└", "│" } })
        local width = 40
        local height = 5
        open_box(b, width, height)

        local contents = vimfn.buf_get_lines({ buffer = b.buffer.id })

        assert.is_true(vim.startswith(contents[1], "┌─"))
        assert.is_true(vim.endswith(contents[1], "──"))
        assert.is_truthy(contents[1]:match(" Title "))

        local middle_line = ("│%s"):format((" "):rep(width - 1))
        for i = 2, height - 1 do
            assert.are.same(contents[i], middle_line)
        end

        assert.is_true(vim.startswith(contents[height], "└─"))
        assert.is_true(vim.endswith(contents[height], "──"))
        assert.is_falsy(contents[height]:match(" "))
    end)
end)
