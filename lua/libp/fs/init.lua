local M = { Watcher = require("libp.fs.Watcher") }
local path = require("libp.path")
local IterList = require("libp.datatype.IterList")
local a = require("plenary.async")

function M.list_dir(dir_name)
	vim.validate({ dir_name = { dir_name, "s" } })
	local err, handle = a.uv.fs_scandir(dir_name)
	a.util.scheduler()
	if err then
		return err, false
	end

	return IterList({
		next_fn = function(_, last_index)
			last_index = last_index or 0
			local name, type = vim.loop.fs_scandir_next(handle)
			if name then
				return last_index + 1, { name = name, type = type }
			end
		end,
	}):collect()
end

function M.copy(src, dst, opts)
	if src == dst then
		return nil, true
	end

	local err, src_stats = a.uv.fs_stat(src)
	if err then
		return err, false
	end

	if src_stats.type == "file" then
		return a.uv.fs_copyfile(src, dst, opts)
	elseif src_stats.type == "directory" then
		local handle
		err, handle = a.uv.fs_scandir(src)
		if err then
			return err, false
		end

		err = a.uv.fs_mkdir(dst, src_stats.mode)
		if err then
			if not (vim.startswith(err, "EEXIST") and not opts.excl) then
				return err, false
			end
		end

		while true do
			local name = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end

			err = M.copy(path.join(src, name), path.join(dst, name), opts)
			if err then
				return err, false
			end
		end
	else
		err = string.format("'%s' illegal file type '%s'", src, src_stats.type)
		return err, false
	end

	return nil, true
end

return M
