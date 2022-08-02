local path = require("libp.path")
local IterList = require("libp.datatype.IterList")
local M = {
	Watcher = require("libp.fs.Watcher"),
}

function M.list_dir(dir_name)
	vim.validate({ dir_name = { dir_name, "s" } })
	local handle, err = M.uv.fs_scandir(dir_name)
	if err then
		return nil, err
	end

	return IterList({
		next_fn = function(_, last_index)
			last_index = last_index or 0
			local name, type = M.uv.fs_scandir_next(handle)
			if name then
				return last_index + 1, { name = name, type = type }
			end
		end,
	}):collect()
end

function M:copy(src, dst, opts)
	vim.validate({ src = { src, "s" }, dst = { dst, "s" }, opts = { opts, "t", true } })
	if src == dst then
		return nil, true
	end

	local src_stats, err = M.uv.fs_stat(src)
	if err then
		return nil, err
	end

	if src_stats.type == "file" then
		return M.uv.fs_copyfile(src, dst, opts)
	elseif src_stats.type == "directory" then
		local handle
		handle, err = M.uv.fs_scandir(src)
		if err then
			return nil, err
		end

		_, err = M.uv.fs_mkdir(dst, src_stats.mode)
		if err then
			if not (vim.startswith(err, "EEXIST") and not opts.excl) then
				return nil, err
			end
		end

		while true do
			local name = M.uv.fs_scandir_next(handle)
			if not name then
				break
			end

			_, err = M.copy(path.join(src, name), path.join(dst, name), opts)
			if err then
				return nil, err
			end
		end
	else
		err = string.format("'%s' illegal file type '%s'", src, src_stats.type)
		return nil, err
	end

	return true
end

return M
