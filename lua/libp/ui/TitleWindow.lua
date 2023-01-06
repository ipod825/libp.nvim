local M = require("libp.ui.Window"):EXTEND()
local vimfn = require("libp.utils.vimfn")

function M:init(buffer, opts)
    opts = opts or {}
    opts.wo = vim.tbl_extend("force", opts.wo or {}, {
        winhighlight = "Normal:LibpTitleWindow",
    })

    buffer:set_content_and_reload({
        require("libp.ui").center_align_text(vimfn.buf_get_lines({ buffer = buffer.id }), vim.o.columns),
    })
    self:SUPER():init(buffer, opts)
end

return M
