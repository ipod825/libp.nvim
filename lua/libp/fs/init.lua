local IterList = require("libp.datatype.IterList")
local uv = require("libp.fs.uv")
local path_join = require("libp.path").join
local M = {
	Watcher = require("libp.fs.Watcher"),
}

function M.stat_mode_num(human_repr)
	vim.validate({ human_repr = { human_repr, "s" } })
	return tonumber(human_repr, 8)
end
local k777 = M.stat_mode_num("777")
local k640 = M.stat_mode_num("640")

function M.is_readable(path)
	vim.validate({ path = { path, "s" } })
	local fd, err = uv.fs_open(path, "r", k640)
	if err then
		return nil, err
	end
	return uv.fs_close(fd)
end

function M.get_mode_string(path)
	local res, err = uv.fs_stat(path)
	if err then
		return nil, err
	end
	return ("%d"):format(bit.band(res, k777))
end

function M.touch(path, mode)
	vim.validate({ path = { path, "s" }, mode = { mode, "s", true } })
	mode = mode and M.stat_mode_num(mode) or k640
	local fd, err = uv.fs_open(path, "a", mode)
	if err then
		return nil, err
	end
	uv.fs_close(fd)
	return true
end

function M.list_dir(dir_name)
	vim.validate({ dir_name = { dir_name, "s" } })
	local handle, err = uv.fs_scandir(dir_name)
	if err then
		return nil, err
	end

	return IterList({
		next_fn = function(_, last_index)
			last_index = last_index or 0
			local name, type = uv.fs_scandir_next(handle)
			if name then
				return last_index + 1, { name = name, type = type }
			end
		end,
	}):collect()
end

function M.copy(src, dst, opts)
	vim.validate({ src = { src, "s" }, dst = { dst, "s" }, opts = { opts, "t", true } })
	if src == dst then
		return nil, true
	end

	local src_stats, err = uv.fs_stat(src)
	if err then
		return nil, err
	end

	if src_stats.type == "file" then
		return uv.fs_copyfile(src, dst, opts)
	elseif src_stats.type == "directory" then
		local handle
		handle, err = uv.fs_scandir(src)
		if err then
			return nil, err
		end

		_, err = uv.fs_mkdir(dst, src_stats.mode)
		if err then
			if not (vim.startswith(err, "EEXIST") and not opts.excl) then
				return nil, err
			end
		end

		while true do
			local name = uv.fs_scandir_next(handle)
			if not name then
				break
			end

			_, err = M.copy(path_join(src, name), path_join(dst, name), opts)
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
