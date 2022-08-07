require("libp.utils.string_extension")
local M = require("libp.argparse.Parser"):EXTEND()
local tokenize = require("libp.argparse.tokenizer").tokenize

function M:parse(str)
    vim.validate({ str = { str, "s" } })
    return self:parse_internal(tokenize(str))
end

function M:parse_internal(args)
    return { { self.prog, args } }
end

return M
