local M = {}

function M.git_project_root()
    return vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
end

function M.script_path()
    return debug.getinfo(2, "S").source:sub(2)
end

function M.script_dir()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*)/")
end

return M
