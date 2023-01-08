local M = {}
local args = require("libp.args")

function M.info(msg)
    vim.notify(msg, vim.log.levels.INFO)
end

function M.set_cwd(path)
    vim.validate({ path = { path, "s" } })
    vim.cmd("lcd " .. path:gsub(" ", "\\ "))
end

function M.str_to_char(s)
    -- TODO: Follow up https://github.com/neovim/neovim/issues/14281
    local res = {}
    local i = 0
    local charnr = vim.fn.strgetchar(s, i)
    while charnr > 0 do
        res[#res + 1] = vim.fn.nr2char(charnr)
        i = i + 1
        charnr = vim.fn.strgetchar(s, i)
    end
    return res
end

function M.warn(msg)
    vim.notify(msg, vim.log.levels.WARN)
end

function M.error(msg)
    vim.notify(msg, vim.log.levels.ERROR)
end

function M.all_rows()
    return 1, vim.fn.line("$")
end

function M.first_visible_line()
    return vim.fn.line("w0")
end

function M.last_visible_line()
    return vim.fn.line("w$")
end

function M.win_get_var(win, name)
    vim.validate({ win = { win, "n" }, name = { name, "s" } })
    local succ, var = pcall(vim.api.nvim_win_get_var, win, name)
    return succ and var or nil
end

function M.buf_get_var(buf, name)
    vim.validate({ buf = { buf, "n" }, name = { name, "s" } })
    local succ, var = pcall(vim.api.nvim_buf_get_var, buf, name)
    return succ and var or nil
end

function M.buf_get_option_and_set(buf, name, new_value)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    vim.validate({ buf = { buf, "n" }, name = { name, "s" }, new_value = args.non_nil(new_value) })
    local ori = vim.bo[buf][name]
    vim.bo[buf][name] = new_value
    return ori
end

function M.buf_get_line(line, buffer)
    vim.validate({
        line = { line, "n" },
        buffer = { buffer, "n", true },
    })
    buffer = buffer or 0
    return vim.api.nvim_buf_get_lines(buffer, line, line + 1, true)[1]
end

function M.buf_get_lines(opts)
    opts = opts or {}
    vim.validate({
        buffer = { opts.buffer, "n", true },
        start = { opts.start, "n", true },
        ends = { opts.ends, "n", true },
        strict_indexing = { opts.strict_indexing, "b", true },
    })
    opts.buffer = opts.buffer or 0
    opts.start = opts.start or 0
    opts.ends = opts.ends or -1
    opts.strict_indexing = args.get_default(opts.strict_indexing, true)
    return vim.api.nvim_buf_get_lines(opts.buffer, opts.start, opts.ends, opts.strict_indexing)
end

function M.win_get_option_and_set(win, name, new_value)
    if not vim.api.nvim_buf_is_valid(win) then
        return
    end
    vim.validate({ win = { win, "n" }, name = { name, "s" }, new_value = args.non_nil(new_value) })
    local ori = vim.api.nvim_win_get_option(win, name)
    vim.api.nvim_win_set_option(win, name, new_value)
    return ori
end

function M.getrow(winid)
    winid = winid or vim.api.nvim_get_current_win()
    return vim.api.nvim_win_get_cursor(winid)[1]
end

function M.getcol(winid)
    winid = winid or vim.api.nvim_get_current_win()
    return vim.api.nvim_win_get_cursor(winid)[2] + 1
end

function M.tabline_end_pos()
    if vim.go.showtabline == 0 then
        return 1
    elseif vim.go.showtabline == 2 then
        return 2
    else
        return #vim.api.nvim_list_tabpages() > 1 and 2 or 1
    end
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

function M.setrow(row, win)
    vim.validate({
        row = {
            row,
            "n",
        },
        win = { win, "n", true },
    })
    win = win or 0
    row = math.min(math.max(row, 1), vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win)))
    vim.api.nvim_win_set_cursor(win, { row, 0 })
end

function M.setcol(col, win)
    vim.validate({
        col = {
            col,
            "n",
        },
        win = { win, "n", true },
    })
    win = win or 0
    local row = M.getrow(win)
    col = math.min(math.max(col, 1), #vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1])
    vim.api.nvim_win_set_cursor(win, { row, col - 1 })
end

function M.ensure_exit_visual_mode()
    if vim.fn.mode() ~= "n" then
        vim.cmd("normal! V")
        -- If we were in visual line mode, the previous cmd might already have
        -- us back in normal mode. Otherwise, we should be in visual line mode
        -- at this point.
        if vim.fn.mode() ~= "n" then
            vim.cmd("normal! V")
        end
    end
end

function M.visual_select_rows(from, to)
    M.ensure_exit_visual_mode()
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
