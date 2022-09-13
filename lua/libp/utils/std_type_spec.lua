local std_type = require("libp.utils.std_type")
local List = require("libp.datatype.List")

describe("reverse", function()
    it("Reverses a list", function()
        assert.are.same({}, std_type.reverse({}))
        assert.are.same({ 4, 3, 2, 1 }, std_type.reverse({ 1, 2, 3, 4 }))
    end)
end)
