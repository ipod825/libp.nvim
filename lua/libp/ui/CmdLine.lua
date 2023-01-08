local M = require("libp.datatype.Class"):EXTEND()
local Buffer = require("libp.ui.Buffer")
local functional = require("libp.functional")
local Window = require("libp.ui.Window")
local a = require("plenary.async")
local Grid = require("libp.ui.Grid")
local vimfn = require("libp.utils.vimfn")

function M:init(opts)
    vim.validate({
        hint = { opts.hint, { "s" }, true },
        wo = { opts.wo, "t", true },
        mappings = { opts.mappings, "t", true },
        on_confirm = { opts.on_confirm, "f", true },
    })

    self.hint = opts.hint or ""
    self.on_confirm = opts.on_confirm or functional.nop
    self.wo = vim.tbl_extend("keep", opts.wo or {}, { winhighlight = "Normal:Normal" })
    self.mappings = opts.mappings or {}
    self.on_cancel = functional.nop
end

function M:show()
    local grid = Grid({ height = vim.o.lines })
    grid:add_row({ height = vim.o.lines - 1 })
    local row = grid:add_row({ height = 1 })
    row
        :add_column({ width = vim.fn.strwidth(self.hint) })
        :fill_window(Window(Buffer({ content = { self.hint } }), { wo = self.wo }))

    self.cmd_buffer = Buffer({
        bo = { modifiable = true },
        mappings = vim.tbl_deep_extend("keep", {
            i = {
                ["<cr>"] = function()
                    local text = vim.fn.getline(".")
                    grid:close()
                    self.on_confirm(text)
                end,
                ["<c-c>"] = function()
                    grid:close()
                    self.on_cancel()
                end,
                ["<esc>"] = function()
                    grid:close()
                    self.on_cancel()
                end,
            },
        }, self.mappings),
    })
    row:add_column({ focusable = true }):fill_window(Window(self.cmd_buffer, { wo = self.wo, focus_on_open = true }))
    grid:show()
    vim.cmd("startinsert")
end

function M:get_content()
    assert(self.cmd_buffer, "cmd_buffer is nil")
    if not vim.api.nvim_buf_is_valid(self.cmd_buffer.id) then
        return
    end
    return vimfn.buf_get_line(0, self.cmd_buffer.id)
end

M.confirm = a.wrap(function(self, callback)
    self.on_confirm = callback
    self.on_cancel = callback
    self:show()
end, 2)

return M
