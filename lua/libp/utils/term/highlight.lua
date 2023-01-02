-- Inspired by norcalli/nvim-terminal.lua
local M = {}
local color256_tbl = require("libp.utils.term.color256_tbl")
local List = require("libp.datatype.List")

local HIGHLIGHT_NAMESPACE = "libpterm"

-- stylua: ignore start
local code_to_attribute = {
    [1] = "bold", [3] = "italic", [4] = "underline",
    [7] = "reverse", [9] = "strikethrough",
}

local code_to_reset_attribute = {
    [21] = "bold", [22] = "bold", [23] = "italic",
    [24] = "underline", [27] = "reverse", [29] = "strikethrough",
}

local code_to_cterm_fg = {
    [30] = 0, [31] = 1, [32] = 2, [33] = 3, [34] = 4, [35] = 5, [36] = 6, [37] = 7,
    [90] = 8, [91] = 9, [92] = 10, [93] = 11, [94] = 12, [95] = 13, [96] = 14, [97] = 15,
}

local code_to_cterm_bg = {
    [40] = 0, [41] = 1, [42] = 2, [43] = 3, [44] = 4, [45] = 5, [46] = 6, [47] = 7,
    [100] = 8, [101] = 9, [102] = 10, [103] = 11, [104] = 12, [105] = 13, [106] = 14, [107] = 15,
}
-- stylua: ignore end

-- Initialized in M:setup
local code_to_fg = {}
local code_to_bg = {}

function M.setup(opts)
    vim.validate({
        default_color256_theme = { opts.default_color256_theme, "s" },
        color256_override = { opts.color256_override, "t" },
    })

    M.namespace = vim.api.nvim_create_namespace(HIGHLIGHT_NAMESPACE)
    M.highlight_groups = {}
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("LipbTerm", {}),
        callback = function()
            for group, attributes in pairs(M.highlight_groups) do
                vim.api.nvim_set_hl(0, group, attributes)
            end
        end,
    })

    assert(
        color256_tbl[opts.default_color256_theme] ~= nil,
        ("Unsupported color map name. Available names: %s"):format(vim.tbl_keys(color256_tbl))
    )
    M.color256_map = vim.tbl_extend("force", color256_tbl[opts.default_color256_theme], opts.color256_override)

    for i = 30, 37 do
        code_to_fg[i] = M.color256_map[code_to_cterm_fg[i]]
    end
    for i = 90, 97 do
        code_to_fg[i] = M.color256_map[code_to_cterm_fg[i]]
    end
    for i = 40, 47 do
        code_to_bg[i] = M.color256_map[code_to_cterm_bg[i]]
    end
    for i = 100, 107 do
        code_to_bg[i] = M.color256_map[code_to_cterm_bg[i]]
    end
end

local function parse_code_to_attributes(code, attributes)
    if code == 0 then
        -- RESET
        attributes = {}
    elseif code_to_attribute[code] then
        attributes[code_to_attribute[code]] = true
    elseif code_to_reset_attribute[code] then
        attributes[code_to_reset_attribute[code]] = nil
    elseif code_to_fg[code] then
        attributes.ctermfg = code_to_cterm_fg[code]
        attributes.fg = code_to_fg[code]
    elseif code_to_bg[code] then
        attributes.ctermbg = code_to_cterm_bg[code]
        attributes.bg = code_to_bg[code]
    elseif code == 39 then
        attributes.ctermfg = nil
        attributes.fg = nil
    elseif code == 49 then
        attributes.ctermbg = nil
        attributes.bg = nil
    end
    return attributes
end

function M.parse_color_code(code_str, attributes)
    -- Reset
    if #code_str == 0 then
        return {}
    end

    local codes = vim.tbl_map(tonumber, vim.split(code_str, "[;:]"))
    local i = 0
    while i < #codes do
        i = i + 1
        if codes[i] == 38 or codes[i] == 48 then
            local cterm = codes[i] == 38 and "ctermfg" or "ctermbg"
            local gui = codes[i] == 38 and "fg" or "bg"
            if codes[i + 1] == 5 then
                attributes[cterm] = codes[i + 2]
                attributes[gui] = M.color256_map[codes[i + 2]]
                i = i + 2
            else
                attributes[gui] = ("#%02X%02X%02X"):format(codes[i + 2], codes[i + 3], codes[i + 4])
                i = i + 4
            end
        else
            attributes = parse_code_to_attributes(codes[i], attributes)
        end
    end
    return attributes
end

local function generate_highlight_group_name(attributes)
    local result = { HIGHLIGHT_NAMESPACE }
    if attributes.bold then
        table.insert(result, "bld")
    end
    if attributes.italic then
        table.insert(result, "itl")
    end
    if attributes.underline then
        table.insert(result, "udl")
    end
    if attributes.reverse then
        table.insert(result, "rev")
    end
    if attributes.strikethrough then
        table.insert(result, "stk")
    end
    if attributes.ctermfg then
        table.insert(result, "cfg")
        table.insert(result, attributes.ctermfg)
    end
    if attributes.ctermbg then
        table.insert(result, "cbg")
        table.insert(result, attributes.ctermbg)
    end
    if attributes.fg then
        table.insert(result, "fg")
        table.insert(result, (attributes.fg:sub(2)))
    end
    if attributes.bg then
        table.insert(result, "bg")
        table.insert(result, (attributes.bg:sub(2)))
    end

    return table.concat(result, "_")
end

local function get_highlight_group(attributes)
    local highlight_group = generate_highlight_group_name(attributes)

    if not M.highlight_groups[highlight_group] then
        vim.api.nvim_set_hl(0, highlight_group, attributes)
        M.highlight_groups[highlight_group] = vim.deepcopy(attributes)
    end
    return highlight_group
end

-- Returns an array of nvim_buf_add_highlight arguments for `lines` for lines
-- with ansi escape characters. Note:
-- 1. The return rows are their indices (zero-based) in `lines` plus
--    `row_offset` (default 0). Caller can pass in `row_offset`  if calling this
--    function for highlighting consecutive lines.
-- 2. The caller is assumed to remove the escape characters and the columns
--    returned take that into consideration.
-- 3. As ansi escape control carries over lines, to support multiple to this
--    function for consecutive lines, this function returns the carried over
--    ansi escape control attributes as the second argument. If this function is
--    called multiple times for highlighting consecutive lines, the caller
--    must catch the returned attributed and pass in last returned attributes.
function M.get_ansi_code_highlight(lines, attributes, row_offset)
    require("libp").check_setup(2, M.highlight_groups, M.color256_map)
    vim.validate({
        lines = { lines, "t" },
        attributes = { attributes, "t", true },
        row_offset = { row_offset, "n", true },
    })
    attributes = attributes or {}
    row_offset = row_offset or 0

    -- For each line
    -- 1. Find the first control mark.
    -- 2. Maybe highlight characters from beginning of the line to the first
    --    control mark using attributes from the last line.
    -- 3. Find next control mark. Highlight the characters from last mark end to
    --    next mark beginning, both offset by total control character length of
    --    the current line so far (control characters are assumed to be removed
    --    later by the caller).
    -- 4. Repeat step 3 until no more control mark can be found.
    -- 5. Check if attributes can be inherited by the following lines. If not,
    --    reset it (see step 2).
    local res = List()
    for i, line in ipairs(lines) do
        local last_mark_beg, last_mark_end, last_mark_code = line:find("%[([%d;:]*)m")

        if not vim.tbl_isempty(attributes) and last_mark_beg > 1 then
            res:append({
                hl_group = get_highlight_group(attributes),
                line = i - 1,
                col_start = 0,
                col_end = last_mark_beg - 1,
            })
        end

        local total_line_control_char_length = 0
        while last_mark_beg do
            total_line_control_char_length = total_line_control_char_length + last_mark_end - last_mark_beg + 1
            local next_mark_beg, next_mark_end, next_mark_code = line:find("%[([%d;:]*)m", last_mark_end + 1)
            attributes = M.parse_color_code(last_mark_code, attributes)
            if not vim.tbl_isempty(attributes) then
                if next_mark_beg then
                    -- Skip highlighting if no character between last_mark_end and next_mark_beg
                    if next_mark_beg - last_mark_end > 1 then
                        res:append({
                            hl_group = get_highlight_group(attributes),
                            line = i - 1 + row_offset,
                            col_start = last_mark_end - total_line_control_char_length,
                            col_end = next_mark_beg - total_line_control_char_length - 1,
                        })
                    end
                elseif last_mark_end < #line then
                    -- Skip highlighting if no last_mark_end is the last bytes.
                    res:append({
                        hl_group = get_highlight_group(attributes),
                        line = i - 1 + row_offset,
                        col_start = last_mark_end - total_line_control_char_length,
                        col_end = #line - total_line_control_char_length,
                    })
                end
            end

            last_mark_beg, last_mark_end, last_mark_code = next_mark_beg, next_mark_end, next_mark_code
        end

        if last_mark_end == #line and (#last_mark_code == 0 or vim.endswith(last_mark_code, "0")) then
            attributes = {}
        end
    end

    return res, attributes
end

return M
