local M = {}

function M.all_rows()
	return 1, vim.fn.line("$")
end

function M.first_visible_line()
	return vim.fn.line("w0")
end

function M.last_visible_line()
	return vim.fn.line("w$")
end

function M.current_row()
	return vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())[1]
end

function M.editable_width(win_id)
	vim.validate({ win_id = { win_id, { "n" } } })
	win_id = win_id == 0 and vim.api.nvim_get_current_win() or win_id
	return vim.api.nvim_win_get_width(win_id) - vim.fn.getwininfo(win_id)[1].textoff
end

-- todo: Monitor new API: https://github.com/neovim/neovim/pull/13896
--@param mark1 Name of mark starting the region
--@param mark2 Name of mark ending the region
--@param options Table containing the adjustment function, register type and selection mode
--@return region region between the two marks, as returned by |vim.region|
--@return start (row,col) tuple denoting the start of the region
--@return finish (row,col) tuple denoting the end of the region
function M.get_marked_region(mark1, mark2, options)
	local bufnr = 0
	local adjust = options.adjust or function(pos1, pos2)
		return pos1, pos2
	end
	local regtype = options.regtype or vim.fn.visualmode()
	local selection = options.selection or (vim.o.selection ~= "exclusive")

	local pos1 = vim.fn.getpos(mark1)
	local pos2 = vim.fn.getpos(mark2)
	pos1, pos2 = adjust(pos1, pos2)

	local start = { pos1[2] - 1, pos1[3] - 1 + pos1[4] }
	local finish = { pos2[2] - 1, pos2[3] - 1 + pos2[4] }

	-- Return if start or finish are invalid
	if start[2] < 0 or finish[1] < start[1] then
		return
	end

	local region = vim.region(bufnr, start, finish, regtype, selection)
	return region, start, finish
end

function M.setrow(row)
	vim.validate({ row = {
		row,
		function()
			return row > 0
		end,
	} })
	vim.api.nvim_win_set_cursor(0, { row, 0 })
end

function M.visual_select_rows(from, to)
	if vim.fn.mode() ~= "n" then
		vim.cmd("normal! V")
		-- If we were in visual line mode, the previous cmd might already have
		-- us back in normal mode. Otherwise, we should be in visual line mode
		-- at this point.
		if vim.fn.mode() ~= "n" then
			vim.cmd("normal! V")
		end
	end
	M.setrow(from)
	vim.cmd("normal! V")
	M.setrow(to)
end

function M.visual_rows()
	local visual_modes = {
		v = true,
		V = true,
		-- [t'<C-v>'] = true, -- Visual block does not seem to be supported by vim.region
	}

	-- Return current line if not in visual mode.
	if visual_modes[vim.api.nvim_get_mode().mode] == nil then
		local cursor = vim.api.nvim_win_get_cursor(0)
		return cursor[1], cursor[1]
	end

	local options = {}
	options.adjust = function(pos1, pos2)
		if vim.fn.visualmode() == "V" then
			pos1[3] = 1
			pos2[3] = 2 ^ 31 - 1
		end

		if pos1[2] > pos2[2] then
			pos2[3], pos1[3] = pos1[3], pos2[3]
			return pos2, pos1
		elseif pos1[2] == pos2[2] and pos1[3] > pos2[3] then
			return pos2, pos1
		else
			return pos1, pos2
		end
	end

	local _, start, finish = M.get_marked_region("v", ".", options)
	return start[1] + 1, finish[1] + 1
end

return M
