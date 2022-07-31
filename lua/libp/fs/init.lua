local M = { Watcher = require("libp.fs.Watcher") }
local path = require("libp.path")
local IterList = require("libp.datatype.IterList")
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

function M.list_dir2(dir_name)
	vim.validate({ dir_name = { dir_name, "s" } })
	local err, handle = a.uv.fs_scandir(dir_name)
	if err then
		return err, false
	end

	return IterList({
		next_fn = function(_, last_index)
			last_index = last_index or 0
			local name = vim.loop.fs_scandir_next(handle)
			if name then
				local stats
				stats = vim.loop.fs_stat(path.join(dir_name, name))
				a.util.scheduler()
				if stats then
					stats.name = name
					return last_index + 1, stats
				end
				-- return last_index + 1, name
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
