local M = {}
local Job = require("libp.Job")

local file_bin_available = vim.fn.executable("file")

function M.info(path)
    if file_bin_available then
        return Job({ cmd = ('file --mime-type "%s"'):format(path) }):stdoutputstr()
    end
end

return M
