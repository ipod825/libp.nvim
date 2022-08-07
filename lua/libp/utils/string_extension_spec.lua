require("libp.utils.string_extension")

describe("find_pattern", function()
    it("Returns nil if no match", function()
        local a = "abc def ghi"
        assert.is_nil(a:find_pattern("defg"), nil)
    end)

    it("Finds matched string", function()
        local a = "abc def ghi"
        assert.are.same("def", a:find_pattern("(def)"))
    end)
end)

describe("split white space", function()
    it("Defaults to use space as delimiter", function()
        local a = "abc def ghi"
        assert.are.same({ "abc", "def", "ghi" }, a:split())
    end)

    it("Removes leading/trailing white space", function()
        local a = "     abc def ghi   "
        assert.are.same({ "abc", "def", "ghi" }, a:split(" "))
    end)

    it("Removes multiple white space", function()
        local a = "     abc        def ghi"
        assert.are.same({ "abc", "def", "ghi" }, a:split(" "))
    end)
end)

describe("split non-white space", function()
    it("Does not remove leading/tailing delimiter", function()
        local a = "\nabc\ndef\nghi\n"
        assert.are.same({ "", "abc", "def", "ghi", "" }, a:split("\n"))
    end)

    it("Does not remove multiple delimiter", function()
        local a = "abc\n\ndef\nghi"
        assert.are.same({ "abc", "", "def", "ghi" }, a:split("\n"))
    end)
end)

describe("split_trim", function()
    it("Defaults to use space as delimiter", function()
        local a = "abc def ghi"
        assert.are.same({ "abc", "def", "ghi" }, a:split_trim())
    end)

    it("Returns array with splited string", function()
        local a = "abc def ghi"
        assert.are.same({ "abc", "def", "ghi" }, a:split_trim(" "))
    end)

    it("Trims each element", function()
        local a = "abc, def, ghi"
        assert.are.same({ "abc", "def", "ghi" }, a:split_trim(","))
    end)
end)

describe("unquote", function()
    it("Returns empty string for empty string", function()
        assert.are.same("", (""):unquote())
    end)
    it("Unquotes single quotation", function()
        assert.are.same("a", ("'a'"):unquote())
    end)
    it("Unquotes double quotation", function()
        assert.are.same("a", ('"a"'):unquote())
    end)
end)
