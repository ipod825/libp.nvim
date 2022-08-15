--- Tokenize the input string into tokens.
-- @module libp.argparse.tokenizer
local M = {}
local vimfn = require("libp.utils.vimfn")

--- Tokenize the input string into tokens. A token belongs to one of the
-- following examples:
--
-- 1. Single quoted string: ' a quoted string, can contain double quote " or
-- escaped single quote \\' '
-- 2. Double quoted string: " a quoted string, can contain single quote ' or
-- escaped double quote \\" "
-- 3. Non space separated characters: this_is-a=token
-- 4. Combination of 1,3 or 2,3: --this="is a token"
-- @tparam string str The input string
-- @treturn {str} The tokens.
function M.tokenize(str)
    local pos = 1
    local res = {}
    local opening_quote = nil
    local last_pos = nil

    -- Normalize: no space at begin/end and between flag and equal signs.
    str = str:gsub("^ *", ""):gsub(" *$", ""):gsub("(%-[^ ='\"]+) *= *", "%1=")

    -- Find quote in the beginning.
    local pbeg2, pend2, p2 = str:find("^(['\"])")
    if pbeg2 then
        last_pos = pos
        opening_quote = p2
        pos = pend2 + 1

        if pos > #str then
            vimfn.error("error: Missing quote.")
            return
        end
    end

    while pos <= #str do
        if not last_pos then
            local pbeg1, pend1 = str:find(" +", pos)
            pbeg2, pend2, p2 = str:find("[^\\](['\"])", pos - 1)
            if (pbeg1 and pbeg2 and pbeg1 <= pbeg2) or (pbeg1 and not pbeg2) then
                -- No begin quote found or space appears before quote. Add token
                -- till space.
                table.insert(res, str:sub(pos, pbeg1 - 1))
                pos = pend1 + 1
            elseif pbeg2 then
                -- Opening quote before space (or no space). Remember the
                -- opening quote and start the following search after the
                -- opening_quote quote.
                last_pos = pos
                opening_quote = p2
                pos = pend2 + 1

                if pos > #str then
                    vimfn.error("error: Missing quote.")
                    return
                end
            else
                -- Reaching end. Add the last token
                table.insert(res, str:sub(pos, #str))
                pos = #str + 1
            end
        else
            -- Closing the quote.
            local _, pend = str:find(("[^\\]%s"):format(opening_quote), pos)
            if pend == nil then
                vimfn.error("error: Missing quote.")
                return
            end

            table.insert(res, str:sub(last_pos, pend))
            pos = str:find("[^ ]", pend + 1) or #str + 1
            last_pos = nil
            opening_quote = nil
        end
    end
    return res
end

return M
