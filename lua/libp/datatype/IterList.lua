local M = require("libp.datatype.Class"):EXTEND()
local List = require("libp.datatype.List")

M.iter = {}
function M:init(opts)
	vim.validate({
		next_fn = { opts.next_fn, "f" },
		invariant = { opts.invariant, "t", true },
		control = { opts.controle, "n", true },
	})

	self.next_fn = opts.next_fn
	self.invariant = opts.invariant
	self.control = opts.control
end

function M:enumerate()
	return self.next_fn, self.invariant, self.control
end

function M:values()
	return coroutine.wrap(function()
		for _, e in self:enumerate() do
			coroutine.yield(e)
		end
	end)
end

function M:next()
	local res
	self.control, res = self.next_fn(self.invariant, self.control)
	return res
end

function M:collect()
	local res = {}
	local i = 1
	for _, v in self:enumerate() do
		res[i] = v
		i = i + 1
	end
	return List(res)
end

function M:for_each(fn)
	vim.validate({ fn = { fn, "function" } })
	for _, v in self:enumerate() do
		fn(v)
	end
end

function M:map(map_fn)
	vim.validate({ map_fn = { map_fn, "function" } })
	return M({
		next_fn = function(invariant, control)
			local v
			control, v = self.next_fn(invariant, control)
			if control then
				return control, map_fn(v)
			end
		end,
		invariant = self.invariant,
		control = self.control,
	})
end

function M:filter(filter_fn)
	vim.validate({ filter_fn = { filter_fn, "function" } })
	return M({
		next_fn = function(invariant, control)
			repeat
				local v
				control, v = self.next_fn(invariant, control)
				if control and filter_fn(v) then
					return control, v
				end
			until not control
		end,
		invariant = self.invariant,
		control = self.control,
	})
end

function M.from_range(beg, ends, step)
	vim.validate({ beg = { beg, "n" }, ends = { ends, "n" }, step = { step, "n", true } })
	if not ends then
		ends = beg
		beg = 1
	end
	step = step or 1

	assert(step ~= 0, "step can not be zero")

	return M({
		next_fn = function(_, control)
			control = control or 0
			local res = beg + control * step
			if step > 0 then
				if res <= ends then
					return control + 1, res
				end
			else
				if res >= ends then
					return control + 1, res
				end
			end
		end,
	})
end

return M
