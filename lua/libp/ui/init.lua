local M = {
    Buffer = require("libp.ui.Buffer"),
    DiffWindow = require("libp.ui.DiffWindow"),
    TitleWindow = require("libp.ui.TitleWindow"),
    FileBuffer = require("libp.ui.FileBuffer"),
    FilePreviewBuffer = require("libp.ui.FilePreviewBuffer"),
    Grid = require("libp.ui.Grid"),
    InfoBox = require("libp.ui.InfoBox"),
    Menu = require("libp.ui.Menu"),
    CmdLine = require("libp.ui.CmdLine"),
    Window = require("libp.ui.Window"),
    BorderWindow = require("libp.ui.BorderWindow"),
    BorderedWindow = require("libp.ui.BorderedWindow"),
}
local values = require("libp.iter").values

function M.center_align_text(content, total_width)
    vim.validate({ content = { content, "t" }, total_width = { total_width, "n" } })
    local num_pads = #content + 1
    local pad_width = total_width
    local content_width = 0
    for c in values(content) do
        pad_width = pad_width - #c
        content_width = content_width + #c
    end
    pad_width = math.floor(pad_width / num_pads)
    local offset = math.floor((total_width - pad_width * num_pads - content_width) / 2)

    local res = (" "):rep(offset)
    local pad = (" "):rep(pad_width)
    for c in values(content) do
        res = res .. pad .. c
    end
    return res
end

return M
