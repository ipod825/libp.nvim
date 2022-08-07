local M = require("libp.datatype.Class"):EXTEND()
local List = require("libp.datatype.List")

local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"
local join = function(...)
    return table.concat({ ... }, path_sep)
end

function M:init(opts)
    vim.validate({ log_file = { opts.log_file, "s" } })
    self:config(opts)
    self.log_date_format = "%H:%M:%S"
    self.format_func = function(arg)
        local res
        if arg == nil then
            res = "nil"
        elseif type(arg) == "string" then
            res = arg
        elseif type(arg) == "table" and arg["IS"] and arg:IS(List) then
            res = vim.inspect(arg, { newline = "", depth = 1 })
        else
            res = vim.inspect(arg, { newline = "" })
        end
        return ("%s⏎\n"):format(res)
    end

    self.logfilename = join(vim.fn.stdpath("cache"), opts.log_file)

    vim.fn.mkdir(vim.fn.stdpath("cache"), "p")
    self.logfile = assert(io.open(self.logfilename, "a+"))
    self.logfile:write("===New Logging Session===\n")

    for level, levelnr in pairs(vim.log.levels) do
        self[level:lower()] = self:BIND(self.log, levelnr)
    end
end

function M:config(opts)
    opts = vim.tbl_extend("keep", opts or {}, { level = vim.log.levels.WARN })
    self.current_level = opts.level
end

function M:get_filename()
    return self.logfilename
end

function M:set_level(level)
    self.current_level = level
end

function M:get_level()
    return self.current_level
end

function M:set_format_func(handle)
    assert(handle == vim.inspect or type(handle) == "function", "handle must be a function")
    self.format_func = handle
end

function M:log(level, ...)
    if level < self.current_level then
        return false
    end
    local argc = select("#", ...)
    if argc == 0 then
        return true
    end

    local info = debug.getinfo(2, "Sln")
    local header = string.format(
        "🗎[%s][%s] ...%s:%s %s",
        level,
        os.date(self.log_date_format),
        string.sub(info.short_src, #info.short_src - 15),
        info.currentline,
        info.name
    )
    self.logfile:write(header, "\n")
    for i = 1, argc do
        self.logfile:write(self.format_func(select(i, ...)))
    end
    self.logfile:flush()
end

return M
