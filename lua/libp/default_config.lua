return {
    highlights = {
        LibpBufferMark1 = { link = "Search" },
        LibpBufferMark2 = { ctermfg = 0, ctermbg = 46, fg = "#000000", bg = "#98be65" },
        LibpBufferMark3 = { ctermfg = 0, ctermbg = 14, fg = "#000000", bg = "#36d0e0" },
        LibpTitleWindow = { link = "Title" },
    },
    integration = {
        web_devicon = {
            -- Overriding default icons and their highlight. The key is valid
            -- filetypes output by `:echo &ft` vim command. The highlight is a
            -- lua table accepting `nvim_set_hl`'s third argument.
            -- Example:
            -- icons = {
            --     ["python"] = {
            --         icon = "",
            --         hl = {
            --             fg = "#ffbc03",
            --             underline=true,
            --         },
            --     },
            -- },
            icons = {},
            -- Aliases to icons' keys. Useful for mapping new filetype to
            -- existing icons without defining the same icon entry for the new
            -- filetype. For example, if you use fugitive, you might want to add
            -- the following aliases:
            -- alias = { fugitive = "git" },
            alias = {},
        },
    },
    utils = {
        term = {
            -- Default theme defining cterm color code (0~255) to the hash code.
            -- Available theme: xterm, kitty.
            default_color256_theme = "kitty",
            -- Map from color code (0~255) to hash code for overriding the
            -- default theme. Partial or full override are both supported.
            -- Example: color256_override = { [1]='#1234aa'}.
            color256_override = {},
        },
    },
}
