local M = {}

local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"

function M.join(...)
	return table.concat({ ... }, path_sep)
end

local kAlphaNumericalLetters = {
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
	"0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"_",
}
function M.randomAlphaNumerical(length, chars)
	chars = chars or kAlphaNumericalLetters
	local res = ""
	for _ = 1, length do
		res = res .. chars[math.random(1, length)]
	end
	return res
end

function M.find_directory(anchor, dir)
	vim.validate({ anchor = { anchor, { "s", "t" } }, dir = { dir, { "s", "t" }, true } })
	if type(anchor) == "string" then
		anchor = { anchor }
	end
	if type(dir) == "string" then
		dir = { dir }
	end
	dir = dir or { vim.api.nvim_buf_get_name(0), vim.fn.getcwd() }

	local function search(a, d)
		local res = nil
		while #d > 1 do
			if vim.fn.glob(M.join(d, a)) ~= "" then
				return d
			end
			local ori_len
			ori_len, d = #d, M.dirname(d)
			if #d == ori_len then
				break
			end
		end
		return res
	end

	local res
	for _, a in ipairs(anchor) do
		for _, d in ipairs(dir) do
			res = search(a, d)
			if res then
				return res, a
			end
		end
	end
end

function M.dirname(str)
	vim.validate({ std = { str, "s" } })
	local pat = ("%s[^%s]*$"):format(path_sep, path_sep)
	local name = str:gsub(pat, "")
	return name
end

function M.basename(str)
	vim.validate({ std = { str, "s" } })
	local pat = (".*%s([^%s]+)%s?"):format(path_sep, path_sep, path_sep)
	local name = str:gsub(pat, "%1")
	return name
end

return M
