local Parser = require("libp.argparse.Parser")

describe("add_argument", function()
	local parser
	before_each(function()
		parser = Parser()
	end)
	describe("positional", function()
		it("Defaults to required", function()
			parser:add_argument("a")
			assert.are.same(nil, parser:parse(""))
		end)

		it("Respects required", function()
			parser:add_argument("a", { required = false })
			assert.are.same({}, parser:parse(""))
		end)

		describe("type", function()
			it("Defaults to string type", function()
				parser:add_argument("a")
				assert.are.same({ a = "1" }, parser:parse("1"))
			end)

			it("Converts types", function()
				parser:add_argument("a", { type = "number" })
				assert.are.same({ a = 1 }, parser:parse("1"))
			end)
		end)

		describe("nargs", function()
			it("Defaults to 1", function()
				parser:add_argument("a")
				assert.are.same(nil, parser:parse("1 2"))
				assert.are.same({ a = "1" }, parser:parse("1"))
			end)

			it("Respects nargs", function()
				parser:add_argument("a", { nargs = 2 })
				assert.are.same({ a = { "1", "2" } }, parser:parse("1 2"))
			end)

			it("Takes + nargs", function()
				parser:add_argument("a", { nargs = "+" })
				assert.are.same(nil, parser:parse(""))
				assert.are.same({ a = "1" }, parser:parse("1"))
				assert.are.same({ a = { "1", "2" } }, parser:parse("1 2"))
				assert.are.same({ a = { "1", "2", "3" } }, parser:parse("1 2 3"))
			end)

			it("Takes * nargs", function()
				parser:add_argument("a", { nargs = "*" })
				assert.are.same({}, parser:parse(""))
				assert.are.same({ a = "1" }, parser:parse("1"))
				assert.are.same({ a = { "1", "2" } }, parser:parse("1 2"))
				assert.are.same({ a = { "1", "2", "3" } }, parser:parse("1 2 3"))
			end)
		end)

		it("Takes multiple positional arguments", function()
			parser:add_argument("a")
			parser:add_argument("b")
			assert.are.same({ a = "1", b = "2" }, parser:parse("1 2"))
			assert.are.same(nil, parser:parse("1 2 3"))
		end)

		it("Takes multiple positional arguments", function()
			parser:add_argument("a", { nargs = 2 })
			parser:add_argument("b")
			assert.are.same({ a = { "1", "2" }, b = "3" }, parser:parse("1 2 3"))
			assert.are.same(nil, parser:parse("1 2 3 4"))
		end)

		it("Takes multiple positional arguments", function()
			parser:add_argument("a")
			parser:add_argument("b", { nargs = 2 })
			assert.are.same({ a = "1", b = { "2", "3" } }, parser:parse("1 2 3"))
			assert.are.same(nil, parser:parse("1 2 3 4"))
		end)
	end)

	describe("short flag", function()
		it("Defaults to not required", function()
			parser:add_argument("-f")
			assert.are.same({}, parser:parse(""))
			assert.are.same({ f = "f" }, parser:parse("-f f"))
		end)

		it("Respects required", function()
			parser:add_argument("-f", { required = true })
			assert.are.same(nil, parser:parse(""))
			assert.are.same({ f = "f" }, parser:parse("-f f"))
		end)

		describe("type", function()
			it("Defaults to string type", function()
				parser:add_argument("-f")
				assert.are.same({ f = "1" }, parser:parse("-f 1"))
			end)

			it("Converts types", function()
				parser:add_argument("-f", { type = "number" })
				assert.are.same({ f = 1 }, parser:parse("-f 1"))
			end)
		end)

		describe("nargs", function()
			it("Defaults to 1", function()
				parser:add_argument("-f")
				assert.are.same(nil, parser:parse("-f f1 f2"))
				assert.are.same({ f = "f1" }, parser:parse("-f f1"))
			end)

			it("Respects nargs", function()
				parser:add_argument("-f", { nargs = 2 })
				assert.are.same(nil, parser:parse("-f f1"))
				assert.are.same({ f = { "f1", "f2" } }, parser:parse("-f f1 f2"))
			end)

			it("Takes + nargs", function()
				parser:add_argument("-f", { nargs = "+" })
				assert.are.same(nil, parser:parse(""))
				assert.are.same({ f = "f1" }, parser:parse("-f f1"))
				assert.are.same({ f = { "f1", "f2" } }, parser:parse("-f f1 f2"))
				assert.are.same({ f = { "f1", "f2", "f3" } }, parser:parse("-f f1 f2 f3"))
			end)

			it("Takes * nargs", function()
				parser:add_argument("-f", { nargs = "*" })
				assert.are.same({}, parser:parse(""))
				assert.are.same({ f = "f1" }, parser:parse("-f f1"))
				assert.are.same({ f = { "f1", "f2" } }, parser:parse("-f f1 f2"))
				assert.are.same({ f = { "f1", "f2", "f3" } }, parser:parse("-f f1 f2 f3"))
			end)
		end)

		it("Takes multiple short flags", function()
			parser:add_argument("-a")
			parser:add_argument("-b")
			assert.are.same({ a = "1", b = "2" }, parser:parse("-a 1 -b 2"))
			assert.are.same({ a = "1", b = "2" }, parser:parse("-b 2 -a 1 "))
			assert.are.same(nil, parser:parse("-a 1 2 -b 2"))
			assert.are.same(nil, parser:parse("-a 1 -b 2 3"))
			assert.are.same(nil, parser:parse("-b 2 3 -a 1 "))
			assert.are.same(nil, parser:parse("-b 2 -a 1 3"))
		end)

		it("Takes multiple short flags", function()
			parser:add_argument("-a", { nargs = 2 })
			parser:add_argument("-b")
			assert.are.same({ a = { "1", "2" }, b = "3" }, parser:parse("-a 1 2 -b 3"))
			assert.are.same({ a = { "1", "2" }, b = "3" }, parser:parse(" -b 3 -a 1 2"))
			assert.are.same(nil, parser:parse("-a 1 -b 2"))
			assert.are.same(nil, parser:parse("-a 1 2 3 -b 2 "))
			assert.are.same(nil, parser:parse("-b 2 3 -a 1 2"))
		end)

		it("Takes multiple short flags", function()
			parser:add_argument("-a")
			parser:add_argument("-b", { nargs = 2 })
			assert.are.same({ a = "1", b = { "2", "3" } }, parser:parse("-a 1 -b 2 3"))
			assert.are.same({ a = "1", b = { "2", "3" } }, parser:parse("-b 2 3 -a 1"))
			assert.are.same(nil, parser:parse("-a 1 -b 2"))
			assert.are.same(nil, parser:parse("-a 1 2 3 -b 2 "))
			assert.are.same(nil, parser:parse("-b 2 3 -a 1 2"))
		end)
	end)

	describe("flag", function()
		it("Defaults to not required", function()
			parser:add_argument("--flag")
			assert.are.same({}, parser:parse(""))
			assert.are.same({ flag = "f" }, parser:parse("--flag f"))
		end)

		it("Respects required", function()
			parser:add_argument("--flag", { required = true })
			assert.are.same(nil, parser:parse(""))
			assert.are.same({ flag = "f" }, parser:parse("--flag f"))
		end)

		describe("type", function()
			it("Defaults to string type", function()
				parser:add_argument("--flag")
				assert.are.same({ flag = "1" }, parser:parse("--flag 1"))
			end)

			it("Converts types", function()
				parser:add_argument("--flag", { type = "number" })
				assert.are.same({ flag = 1 }, parser:parse("--flag 1"))
			end)
		end)

		describe("nargs", function()
			it("Defaults to 1", function()
				parser:add_argument("--flag")
				assert.are.same(nil, parser:parse("--flag f1 f2"))
				assert.are.same({ flag = "f1" }, parser:parse("--flag f1"))
			end)

			it("Respects nargs", function()
				parser:add_argument("--flag", { nargs = 2 })
				assert.are.same(nil, parser:parse("--flag f1"))
				assert.are.same({ flag = { "f1", "f2" } }, parser:parse("--flag f1 f2"))
			end)

			it("Takes + nargs", function()
				parser:add_argument("--flag", { nargs = "+" })
				assert.are.same(nil, parser:parse(""))
				assert.are.same({ flag = "f1" }, parser:parse("--flag f1"))
				assert.are.same({ flag = { "f1", "f2" } }, parser:parse("--flag f1 f2"))
				assert.are.same({ flag = { "f1", "f2", "f3" } }, parser:parse("--flag f1 f2 f3"))
			end)

			it("Takes * nargs", function()
				parser:add_argument("--flag", { nargs = "*" })
				assert.are.same({}, parser:parse(""))
				assert.are.same({ flag = "f1" }, parser:parse("--flag f1"))
				assert.are.same({ flag = { "f1", "f2" } }, parser:parse("--flag f1 f2"))
				assert.are.same({ flag = { "f1", "f2", "f3" } }, parser:parse("--flag f1 f2 f3"))
			end)
		end)

		it("Takes multiple flags", function()
			parser:add_argument("--a")
			parser:add_argument("--b")
			assert.are.same({ a = "1", b = "2" }, parser:parse("--a 1 --b 2"))
			assert.are.same({ a = "1", b = "2" }, parser:parse("--b 2 --a 1 "))
		end)

		it("Takes multiple flags", function()
			parser:add_argument("--a", { nargs = 2 })
			parser:add_argument("--b")
			assert.are.same({ a = { "1", "2" }, b = "3" }, parser:parse("--a 1 2 --b 3"))
			assert.are.same({ a = { "1", "2" }, b = "3" }, parser:parse(" --b 3 --a 1 2"))
		end)

		it("Takes multiple flags", function()
			parser:add_argument("--a")
			parser:add_argument("--b", { nargs = 2 })
			assert.are.same({ a = "1", b = { "2", "3" } }, parser:parse("--a 1 --b 2 3"))
			assert.are.same({ a = "1", b = { "2", "3" } }, parser:parse("--b 2 3 --a 1"))
		end)
	end)

	describe("Composite", function()
		it("Takes positional and flag", function()
			parser:add_argument("a")
			parser:add_argument("--flag")
			assert.are.same({ a = "1", flag = "2" }, parser:parse("1 --flag 2"))
			assert.are.same({ a = "1", flag = "2" }, parser:parse(" --flag 2 1"))
			assert.are.same({ a = "1" }, parser:parse("1"))
			assert.are.same(nil, parser:parse("--flag 1"))
		end)

		it("Takes positional and flag", function()
			parser:add_argument("a", { nargs = 2 })
			parser:add_argument("--flag")
			assert.are.same({ a = { "1", "2" }, flag = "3" }, parser:parse("1 2 --flag 3"))
			assert.are.same({ a = { "1", "2" }, flag = "3" }, parser:parse("--flag 3 1 2"))
			assert.are.same({ a = { "1", "2" } }, parser:parse("1 2"))
			assert.are.same(nil, parser:parse("--flag 1"))
			assert.are.same(nil, parser:parse("1"))
		end)

		it("Takes positional and flag", function()
			parser:add_argument("a")
			parser:add_argument("--flag", { nargs = 2 })
			assert.are.same({ a = "1", flag = { "2", "3" } }, parser:parse("1 --flag 2 3"))
			assert.are.same({ a = "1", flag = { "2", "3" } }, parser:parse("--flag 2 3 1"))
			assert.are.same({ a = "1" }, parser:parse("1"))
			assert.are.same(nil, parser:parse("1 --flag 2"))
			assert.are.same(nil, parser:parse("--flag 1 2"))
		end)

		it("Takes positional and flag", function()
			parser:add_argument("a", { nargs = "+" })
			parser:add_argument("--flag", { nargs = 2 })
			assert.are.same(nil, parser:parse("--flag 2 3"))
			assert.are.same({ a = "1", flag = { "2", "3" } }, parser:parse("1 --flag 2 3"))
			assert.are.same({ a = "1", flag = { "2", "3" } }, parser:parse("--flag 2 3 1"))
			assert.are.same({ a = { "1", "2" }, flag = { "2", "3" } }, parser:parse("1 2 --flag 2 3"))
		end)

		it("Takes positional and flag", function()
			parser:add_argument("a")
			parser:add_argument("--flag", { nargs = "*" })
			assert.are.same(nil, parser:parse(""))
			assert.are.same(nil, parser:parse("--flag 2 3"))
			assert.are.same({ a = "1" }, parser:parse("1"))
			assert.are.same({ a = "1", flag = "2" }, parser:parse("1 --flag 2 "))
			assert.are.same({ a = "1", flag = { "2", "3" } }, parser:parse("1 --flag 2 3"))
			assert.are.same({ a = "1", flag = { "2", "3", "4" } }, parser:parse("1 --flag 2 3 4"))
		end)

		it("Takes positional and flag", function()
			parser:add_argument("a")
			parser:add_argument("--flag", { nargs = "+" })
			assert.are.same(nil, parser:parse(""))
			assert.are.same(nil, parser:parse("1"))
			assert.are.same(nil, parser:parse("--flag 2 3"))
			assert.are.same({ a = "1", flag = "2" }, parser:parse("1 --flag 2 "))
			assert.are.same({ a = "1", flag = { "2", "3" } }, parser:parse("1 --flag 2 3"))
			assert.are.same({ a = "1", flag = { "2", "3", "4" } }, parser:parse("1 --flag 2 3 4"))
		end)
	end)
end)

describe("parse", function()
	local parser
	before_each(function()
		parser = Parser()
		parser:add_argument("-f", { nargs = "*" })
		parser:add_argument("--flag", { nargs = "*" })
	end)

	it("Works well with quotes", function()
		assert.are.same({}, parser:parse(""))
		assert.are.same({ f = [["1"]], flag = [["2"]] }, parser:parse([[-f "1" --flag "2"]]))
		assert.are.same(
			{ f = { [["1"]], [["2"]] }, flag = { [["3"]], [["4"]] } },
			parser:parse([[-f "1" "2" --flag "3" "4" ]])
		)
		assert.are.same(
			{ f = { [["\"1"]], [['"2']] }, flag = { [["\"3\""]], [['"4"']] } },
			parser:parse([[-f "\"1" '"2' --flag "\"3\"" '"4"' ]])
		)
		-- Missing quotes
		assert.are.same(nil, parser:parse([[-f "\"1 '"2' --flag "\"3\"" '"4"' ]]))
		assert.are.same(nil, parser:parse([[-f "\"1" '"2 --flag "\"3\"" '"4"' ]]))
		assert.are.same(nil, parser:parse([[-f "\"1" '"2' --flag "\"3\" '"4"' ]]))
		assert.are.same(nil, parser:parse([[-f "\"1" '"2' --flag "\"3\"" '"4" ]]))
	end)

	it("Works well with equal signs", function()
		assert.are.same({ f = [["1"]], flag = [["2"]] }, parser:parse([[-f="1" --flag="2"]]))
		assert.are.same({ f = [["=1"]], flag = [["=2"]] }, parser:parse([[-f="=1" --flag ="=2"]]))
		assert.are.same(
			{ f = { [["=1"]], [["2"]] }, flag = { [["3"]], [["=4"]] } },
			parser:parse([[-f "=1" "2" --flag "3" "=4" ]])
		)
	end)
end)

describe("add_subparser", function()
	it("Takes a parser instance", function()
		local parser = Parser()
		local sub_parser = Parser("sub")
		parser:add_subparser(sub_parser)
		assert.are.same({ { "", {} }, { "sub", {} } }, parser:parse("sub"))
	end)

	it("Takes multiple sub_parsers", function()
		local parser = Parser()
		parser:add_subparser("sub1")
		parser:add_subparser("sub2")
		assert.are.same({ { "", {} }, { "sub1", {} } }, parser:parse("sub1"))
		assert.are.same({ { "", {} }, { "sub2", {} } }, parser:parse("sub2"))
	end)

	it("Takes recursive sub_parsers", function()
		local parser = Parser()
		local sub_parser = parser:add_subparser("sub")
		sub_parser:add_subparser("subsub")
		assert.are.same({ { "", {} }, { "sub", {} }, { "subsub", {} } }, parser:parse("sub subsub"))
	end)

	it("Takes recursive multiple sub_parsers", function()
		local parser = Parser()
		local sub_parser1 = parser:add_subparser("sub1")
		local sub_parser2 = parser:add_subparser("sub2")
		sub_parser1:add_subparser("sub1sub1")
		sub_parser1:add_subparser("sub1sub2")
		sub_parser2:add_subparser("sub2sub1")
		sub_parser2:add_subparser("sub2sub2")
		assert.are.same({ { "", {} }, { "sub1", {} }, { "sub1sub1", {} } }, parser:parse("sub1 sub1sub1"))
		assert.are.same({ { "", {} }, { "sub1", {} }, { "sub1sub2", {} } }, parser:parse("sub1 sub1sub2"))
		assert.are.same({ { "", {} }, { "sub2", {} }, { "sub2sub2", {} } }, parser:parse("sub2 sub2sub2"))
		assert.are.same({ { "", {} }, { "sub2", {} }, { "sub2sub1", {} } }, parser:parse("sub2 sub2sub1"))
	end)

	it("Respects global options", function()
		local parser = Parser()
		parser:add_argument("a", { type = "number" })
		parser:add_argument("--flag", { nargs = 2 })
		local sub_parser = parser:add_subparser("sub")
		sub_parser:add_argument("sub_a", { type = "number" })
		sub_parser:add_argument("--sub_flag", { nargs = 2 })
		local res = parser:parse("--flag f1 f2 1 sub --sub_flag subf1 subf2 2")
		assert.are.same({
			{ "", { a = 1, flag = { "f1", "f2" } } },
			{ "sub", { sub_a = 2, sub_flag = { "subf1", "subf2" } } },
		}, res)
	end)

	it("Returns hierarchical result", function()
		local parser = Parser("prog")
		local sub_parser = parser:add_subparser("sub")
		sub_parser:add_subparser("subsub")
		assert.are.same({ { "prog", {} }, { "sub", {} }, { "subsub", {} } }, parser:parse("sub subsub", true))
	end)
end)

describe("get_completion_list", function()
	local parser = nil
	before_each(function()
		parser = Parser()
		parser:add_argument("a", { type = "number" })
		parser:add_argument("--flag", { nargs = 2 })
		parser:add_subparser("sub2")
		local sub_parser = parser:add_subparser("sub")
		sub_parser:add_argument("sub_a", { type = "number" })
		sub_parser:add_argument("--sub_flag", { nargs = 2 })
	end)

	it("Returns top flag and subcommands", function()
		assert.are.same({
			"--flag",
			"sub",
			"sub2",
		}, parser:get_completion_list(""))
	end)

	it("Returns things statrs with hint", function()
		assert.are.same({
			"--flag",
		}, parser:get_completion_list("", "-"))
		assert.are.same({
			"--flag",
		}, parser:get_completion_list("", "--"))
		assert.are.same({
			"sub",
			"sub2",
		}, parser:get_completion_list("s", "s"))
		assert.are.same({
			"sub",
			"sub2",
		}, parser:get_completion_list("su", "su"))
		-- Kind of an edge case. "sub" is successfully parsed. So can't complete
		-- commands at same level.
		assert.are.same({}, parser:get_completion_list("sub", "sub"))
	end)

	it("Returns sub-flags", function()
		assert.are.same({ "--sub_flag" }, parser:get_completion_list("sub"))
		assert.are.same({}, parser:get_completion_list("sub2"))
	end)

	it("Returns sub-flags with hints", function()
		assert.are.same({ "--sub_flag" }, parser:get_completion_list("sub", "-"))
	end)
end)
