local tokenize = require("libp.argparse.tokenizer").tokenize

describe("tokenize_command", function()
    it("Removes beginning/trailing space", function()
        assert.are.same({ "abc", "def" }, tokenize("  abc def  "))
        assert.are.same({ '"abc"', '"def"' }, tokenize('  "abc" "def"  '))
    end)

    it("Removes space between equal sign for flags", function()
        assert.are.same({ "--abc=def", "-hij=klm" }, tokenize("--abc =  def -hij = klm"))
        assert.are.same({ [[--abc="def"]], [[-hij='klm']] }, tokenize([[ --abc =  "def" -hij = 'klm'  ]]))
        assert.are.same({ [[--abc="def"]], [[-hij='klm']] }, tokenize([[--abc =  "def" -hij = 'klm']]))
        assert.are.same(
            { [[--abc=" = def"]], [[-hij=' = klm = ']] },
            tokenize([[--abc =  " = def" -hij = ' = klm = ']])
        )
    end)

    it("Works with escaped quote", function()
        assert.are.same({ [[abc="\"def\""]], [[hij="'klm'"]] }, tokenize([[abc="\"def\"" hij="'klm'"]]))
        assert.are.same({ [[--abc="\"def\""]], [[-hij="'klm'"]] }, tokenize([[--abc =  "\"def\"" -hij = "'klm'"]]))
    end)

    it("Returns nil on missing quote", function()
        assert.are.same({ [[abc="'def"]] }, tokenize([[abc="'def"]]))
        assert.are.same({ [[abc='"def']] }, tokenize([[abc='"def']]))

        assert.is_nil(tokenize([[abc="def]]))
        assert.is_nil(tokenize([[abc='def]]))
        assert.is_nil(tokenize([[abc="\"def\" hij="'klm'"]]))
    end)

    it("Works in complex case", function()
        assert.are.same(
            { "command", "--flag", '"flag_value"', [[-f='\'fvalue\'']], [["\"pos_arg\""]], "'pos_arg2'" },
            tokenize([[  command --flag "flag_value" -f='\'fvalue\'' "\"pos_arg\"" 'pos_arg2']])
        )
    end)
end)
