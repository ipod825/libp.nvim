local String = getmetatable("").__index
local values = require("libp.iter").values

function String:split_trim(sep)
    local res = {}
    for s in values(self:split(sep)) do
        table.insert(res, vim.trim(s))
    end
    return res
end

function String:split(sep)
    if #self == 0 then
        return {}
    end
    sep = sep or " "
    local res = {}
    local beg = 1
    local sep_is_space = sep == " "
    if sep_is_space then
        beg = self:find("[^ ]")
        sep = " +"
    end

    while true do
        local sep_beg, sep_end = self:find(sep, beg)
        if sep_beg then
            table.insert(res, self:sub(beg, sep_beg - 1))
            beg = sep_end + 1
        else
            if not sep_is_space or beg <= #self then
                table.insert(res, self:sub(beg, #self))
            end
            return res
        end
    end
end

function String:unquote()
    local res = self:gsub('^"(.+)"$', "%1")
    res = res:gsub("^'(.+)'$", "%1")
    return res
end

function String:find_pattern(pattern, ...)
    return select(3, self:find(pattern, ...))
end
