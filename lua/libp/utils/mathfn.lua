local M = {}

function M.decimal_to_octal(deci_num)
    local octal_num = 0
    local countval = 1

    while deci_num ~= 0 do
        local remainder = math.floor(deci_num % 8)
        octal_num = octal_num + remainder * countval
        countval = countval * 10
        deci_num = math.floor(deci_num / 8)
    end
    return octal_num
end

return M
