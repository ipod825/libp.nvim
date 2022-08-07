local M = require("libp.datatype.Class"):EXTEND()

function M:init(path, callback, flags)
    self._watcher = vim.loop.new_fs_event()
    flags = flags or {}
    self._watcher:start(
        path,
        flags,
        vim.schedule_wrap(function(...)
            callback(self._watcher, ...)
        end)
    )
end

function M:stop()
    self._watcher:stop()
end

return M
