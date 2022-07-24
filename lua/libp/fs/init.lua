local M = { Watcher = require("libp.fs.Watcher") }
local a = require("plenary.async")

function M.list_dir(dir_name, max_entry)
	vim.validate({ dir_name = { dir_name, "s" }, max_entry = { max_entry, "n", true } })
	max_entry = max_entry or 9999999
	local dir = vim.loop.fs_opendir(dir_name, nil, max_entry)
	local _, entries = a.uv.fs_readdir(dir)
	a.uv.fs_closedir(dir)
	a.util.scheduler()
	return entries
end

return M
