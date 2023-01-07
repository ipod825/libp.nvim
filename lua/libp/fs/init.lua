local uv = require("libp.fs.uv")
local pathfn = require("libp.utils.pathfn")
local mathfn = require("libp.utils.mathfn")
local iter = require("libp.iter")
local M = {
    Watcher = require("libp.fs.Watcher"),
}

function M.stat_mode_num(human_repr)
    vim.validate({ human_repr = { human_repr, "n" } })
    return tonumber(tostring(human_repr), 8)
end
local k777 = M.stat_mode_num(777)
local k640 = M.stat_mode_num(640)
local k100 = M.stat_mode_num(100)

function M.is_directory(path)
    vim.validate({ path = { path, "s" } })
    local fd, err = uv.fs_opendir(path)
    if err then
        return false
    end
    uv.fs_closedir(fd)
    return true
end

function M.is_readable(path)
    vim.validate({ path = { path, "s" } })
    local fd, err = uv.fs_open(path, "r", k640)
    if err then
        return false
    end
    uv.fs_close(fd)
    return true
end

function M.is_executable(path)
    vim.validate({ path = { path, "s" } })
    local res, err = uv.fs_stat(path)
    if err then
        return false
    elseif res.type == "directory" then
        return false
    end
    return mathfn.decimal_to_octal(bit.band(res.mode, k100)) ~= 0
end

function M.chmod(path, mode)
    return uv.fs_chmod(path, M.stat_mode_num(mode))
end

function M.get_mode(path)
    local res, err = uv.fs_stat(path)
    if err then
        return nil, err
    end
    return mathfn.decimal_to_octal(bit.band(res.mode, k777))
end

function M.mkdir(path, mode)
    vim.validate({ path = { path, "s" }, mode = { mode, "n", true } })
    mode = mode or 750
    return uv.fs_mkdir(path, M.stat_mode_num(mode))
end

function M.rm(path)
    vim.validate({ path = { path, "s" } })
    if M.is_directory(path) then
        return M.rmdir(path)
    else
        return uv.fs_unlink(path)
    end
end

function M.rmdir(path)
    vim.validate({ path = { path, "s" } })
    if not M.is_directory(path) then
        return nil, ("%s is not a directory"):format(path)
    end

    local handle, err
    handle, err = uv.fs_scandir(path)
    if err then
        return nil, err
    end

    err = ""
    while true do
        local name = uv.fs_scandir_next(handle)
        if not name then
            break
        end

        local new_path = pathfn.join(path, name)
        local new_err
        if M.is_directory(new_path) then
            _, new_err = M.rmdir(new_path)
        else
            _, new_err = uv.fs_unlink(new_path)
        end
        if new_err then
            err = err .. new_err
        end
    end
    if err == "" then
        uv.fs_rmdir(path)
        return true, nil
    else
        return nil, err
    end
end

function M.touch(path)
    vim.validate({ path = { path, "s" } })
    local fd, err = uv.fs_open(path, "a", k640)
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

    return iter.V(nil, function(_, last_index)
        last_index = last_index or 0
        local name, type = uv.fs_scandir_next(handle)
        if name then
            return last_index + 1, { name = name, type = type }
        end
    end):collect()
end

function M.copy(src, dst, opts)
    vim.validate({ src = { src, "s" }, dst = { dst, "s" }, opts = { opts, "t", true } })
    opts = opts or {}
    if src == dst then
        return true, nil
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
            if vim.startswith(err, "EEXIST") then
                if opts.excl then
                    return nil, err
                end
            else
                return nil, err
            end
        end

        while true do
            local name = uv.fs_scandir_next(handle)
            if not name then
                break
            end

            _, err = M.copy(pathfn.join(src, name), pathfn.join(dst, name), opts)
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
