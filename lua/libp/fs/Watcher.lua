local M = require("libp.datatype.Class"):EXTEND()

function M:init(path, callback, flags)
	local watcher = vim.loop.new_fs_event()
	flags = flags or {}
	watcher:start(
		path,
		flags,
		vim.schedule_wrap(function(...)
			callback(watcher, ...)
		end)
	)
end

return M
