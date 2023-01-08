-- Modified from https://github.com/kyazdani42/nvim-web-devicons
local M = {}
local iter = require("libp.iter")
local pathfn = require("libp.utils.pathfn")

M.icons = {
    default = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    [".babelrc"] = {
        icon = "ﬥ",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    [".bash_profile"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            ctermfg = 113,
        },
    },
    [".bashrc"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            ctermfg = 113,
        },
    },
    [".DS_Store"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            ctermfg = 59,
        },
    },
    [".gitattributes"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            ctermfg = 59,
        },
    },
    ["gitconfig"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            ctermfg = 59,
        },
    },
    [".gitignore"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            ctermfg = 59,
        },
    },
    [".gitlab-ci.yml"] = {
        icon = "",
        hl = {
            fg = "#e24329",
            ctermfg = 166,
        },
    },
    [".gitmodules"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            ctermfg = 59,
        },
    },
    [".gvimrc"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    [".npmignore"] = {
        icon = "",
        hl = {
            fg = "#E8274B",
            ctermfg = 161,
        },
    },
    [".npmrc"] = {
        icon = "",
        hl = {
            fg = "#E8274B",
            ctermfg = 161,
        },
    },
    [".settings.json"] = {
        icon = "",
        hl = {
            fg = "#854CC7",
            ctermfg = 98,
        },
    },
    [".vimrc"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    [".zprofile"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            ctermfg = 113,
        },
    },
    [".zshenv"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            ctermfg = 113,
        },
    },
    [".zshrc"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            ctermfg = 113,
        },
    },
    ["Brewfile"] = {
        icon = "",
        hl = {
            fg = "#701516",
            ctermfg = 52,
        },
    },
    ["CMakeLists.txt"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["gitcommit"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            ctermfg = 59,
        },
    },
    ["Dockerfile"] = {
        icon = "",
        hl = {
            fg = "#384d54",
            ctermfg = 59,
        },
    },
    ["Gemfile"] = {
        icon = "",
        hl = {
            fg = "#701516",
            ctermfg = 52,
        },
    },
    ["LICENSE"] = {
        icon = "",
        hl = {
            fg = "#d0bf41",
            ctermfg = 179,
        },
    },
    ["COPYING"] = {
        icon = "",
        hl = {
            fg = "#d0bf41",
            ctermfg = 179,
        },
    },
    ["COPYING.LESSER"] = {
        icon = "",
        hl = {
            fg = "#d0bf41",
            ctermfg = 179,
        },
    },
    ["license"] = {
        icon = "",
        hl = {
            fg = "#d0bf41",
            ctermfg = 179,
        },
    },
    ["R"] = {
        icon = "ﳒ",
        hl = {
            fg = "#358a5b",
            ctermfg = 65,
        },
    },
    ["Rmd"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["Vagrantfile"] = {
        icon = "",
        hl = {
            fg = "#1563FF",
            ctermfg = 27,
        },
    },
    ["_gvimrc"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    ["_vimrc"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    ["postscr"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    ["awk"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            ctermfg = 59,
        },
    },
    ["bash"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            ctermfg = 113,
        },
    },
    ["dosbatch"] = {
        icon = "",
        hl = {
            fg = "#C1F12E",
            ctermfg = 154,
        },
    },
    ["bmp"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["c"] = {
        icon = "",
        hl = {
            fg = "#599eff",
            ctermfg = 75,
        },
    },
    ["c++"] = {
        icon = "",
        hl = {
            fg = "#f34b7d",
            ctermfg = 204,
        },
    },
    ["cbl"] = {
        icon = "⚙",
        hl = {
            fg = "#005ca5",
            ctermfg = 25,
        },
    },
    ["cc"] = {
        icon = "",
        hl = {
            fg = "#f34b7d",
            ctermfg = 204,
        },
    },
    ["cfg"] = {
        icon = "",
        hl = {
            fg = "#ECECEC",
            ctermfg = 231,
        },
    },
    ["clojure"] = {
        icon = "",
        hl = {
            fg = "#8dc149",
            ctermfg = 107,
        },
    },
    ["cljc"] = {
        icon = "",
        hl = {
            fg = "#8dc149",
            ctermfg = 107,
        },
    },
    ["cljs"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["cljd"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["cmake"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["cob"] = {
        icon = "⚙",
        hl = {
            fg = "#005ca5",
            ctermfg = 25,
        },
    },
    ["cobol"] = {
        icon = "⚙",
        hl = {
            fg = "#005ca5",
            ctermfg = 25,
        },
    },
    ["coffee"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    ["conf"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["config.ru"] = {
        icon = "",
        hl = {
            fg = "#701516",
            ctermfg = 52,
        },
    },
    ["cp"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["cpp"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["cpy"] = {
        icon = "⚙",
        hl = {
            fg = "#005ca5",
            ctermfg = 25,
        },
    },
    ["cr"] = {
        icon = "",
        hl = {
            fg = "#000000",
            ctermfg = 16,
        },
    },
    ["cs"] = {
        icon = "",
        hl = {
            fg = "#596706",
            ctermfg = 58,
        },
    },
    ["csh"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            ctermfg = 59,
        },
    },
    ["cson"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    ["css"] = {
        icon = "",
        hl = {
            fg = "#42a5f5",
            ctermfg = 39,
        },
    },
    ["csv"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            ctermfg = 113,
        },
    },
    ["cxx"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["d"] = {
        icon = "",
        hl = {
            fg = "#427819",
            ctermfg = 64,
        },
    },
    ["dart"] = {
        icon = "",
        hl = {
            fg = "#03589C",
            ctermfg = 25,
        },
    },
    ["db"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            ctermfg = 188,
        },
    },
    ["desktop"] = {
        icon = "",
        hl = {
            fg = "#563d7c",
            ctermfg = 60,
        },
    },
    ["diff"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            ctermfg = 59,
        },
    },
    ["doc"] = {
        icon = "",
        hl = {
            fg = "#185abd",
            ctermfg = 25,
        },
    },
    ["dockerfile"] = {
        icon = "",
        hl = {
            fg = "#384d54",
            ctermfg = 59,
        },
    },
    ["drl"] = {
        icon = "",
        hl = {
            fg = "#ffafaf",
            ctermfg = 217,
        },
    },
    ["dropbox"] = {
        icon = "",
        hl = {
            fg = "#0061FE",
            ctermfg = 27,
        },
    },
    ["dump"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            ctermfg = 188,
        },
    },
    ["edn"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["eex"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["ejs"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    ["elm"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["epuppet"] = {
        icon = "",
        hl = {
            fg = "#FFA61A",
            ctermfg = 15,
        },
    },
    ["eruby"] = {
        icon = "",
        hl = {
            fg = "#701516",
            ctermfg = 52,
        },
    },
    ["erlang"] = {
        icon = "",
        hl = {
            fg = "#B83998",
            ctermfg = 132,
        },
    },
    ["elixir"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["exs"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["favicon.ico"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    ["fennel"] = {
        icon = "🌜",
        hl = {
            fg = "#fff3d7",
            ctermfg = 230,
        },
    },
    ["fish"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            ctermfg = 59,
        },
    },
    ["fsharp"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["fsi"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["fsscript"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["fsx"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["gd"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["gemspec"] = {
        icon = "",
        hl = {
            fg = "#701516",
            ctermfg = 52,
        },
    },
    ["gif"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["git"] = {
        icon = "",
        hl = {
            fg = "#F14C28",
            ctermfg = 202,
        },
    },
    ["glb"] = {
        icon = "",
        hl = {
            fg = "#FFB13B",
            ctermfg = 215,
        },
    },
    ["go"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["godot"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["gruntfile"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["gulpfile"] = {
        icon = "",
        hl = {
            fg = "#cc3e44",
            ctermfg = 167,
        },
    },
    ["h"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["haml"] = {
        icon = "",
        hl = {
            fg = "#eaeae1",
            ctermfg = 188,
        },
    },
    ["hbs"] = {
        icon = "",
        hl = {
            fg = "#f0772b",
            ctermfg = 208,
        },
    },
    ["heex"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["hh"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["hpp"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["hrl"] = {
        icon = "",
        hl = {
            fg = "#B83998",
            ctermfg = 132,
        },
    },
    ["haskell"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["htm"] = {
        icon = "",
        hl = {
            fg = "#e34c26",
            ctermfg = 166,
        },
    },
    ["html"] = {
        icon = "",
        hl = {
            fg = "#e44d26",
            ctermfg = 202,
        },
    },
    ["hxx"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["ico"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    ["import"] = {
        icon = "",
        hl = {
            fg = "#ECECEC",
            ctermfg = 231,
        },
    },
    ["dosini"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["java"] = {
        icon = "",
        hl = {
            fg = "#cc3e44",
            ctermfg = 167,
        },
    },
    ["julia"] = {
        icon = "",
        hl = {
            fg = "#a270ba",
            ctermfg = 133,
        },
    },
    ["jpeg"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["jpg"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["javascript"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    ["json"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    ["javascriptreact"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["ksh"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            ctermfg = 59,
        },
    },
    ["kotlin"] = {
        icon = "𝙆",
        hl = {
            fg = "#F88A02",
            ctermfg = 208,
        },
    },
    ["kts"] = {
        icon = "𝙆",
        hl = {
            fg = "#F88A02",
            ctermfg = 208,
        },
    },
    ["leex"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["less"] = {
        icon = "",
        hl = {
            fg = "#563d7c",
            ctermfg = 60,
        },
    },
    ["lhaskell"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["lua"] = {
        icon = "",
        hl = {
            fg = "#51a0cf",
            ctermfg = 74,
        },
    },
    ["make"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["markdown"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["material"] = {
        icon = "",
        hl = {
            fg = "#B83998",
            ctermfg = 132,
        },
    },
    ["md"] = {
        icon = "",
        hl = {
            fg = "#ffffff",
            ctermfg = "white",
        },
    },
    ["mdx"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["mint"] = {
        icon = "",
        hl = {
            fg = "#87c095",
            ctermfg = 108,
        },
    },
    ["mix.lock"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["mjs"] = {
        icon = "",
        hl = {
            fg = "#f1e05a",
            ctermfg = 221,
        },
    },
    ["ocaml"] = {
        icon = "λ",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["mli"] = {
        icon = "λ",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["mustache"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["nim"] = {
        icon = "👑",
        hl = {
            fg = "#f3d400",
            ctermfg = 220,
        },
    },
    ["nix"] = {
        icon = "",
        hl = {
            fg = "#7ebae4",
            ctermfg = 110,
        },
    },
    ["node_modules"] = {
        icon = "",
        hl = {
            fg = "#E8274B",
            ctermfg = 161,
        },
    },
    ["opus"] = {
        icon = "",
        hl = {
            fg = "#F88A02",
            ctermfg = 208,
        },
    },
    ["otf"] = {
        icon = "",
        hl = {
            fg = "#ECECEC",
            ctermfg = 231,
        },
    },
    ["package.json"] = {
        icon = "",
        hl = {
            fg = "#e8274b",
            ctermfg = 196,
        },
    },
    ["package-lock.json"] = {
        icon = "",
        hl = {
            fg = "#7a0d21",
            ctermfg = 88,
        },
    },
    ["pck"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["pdf"] = {
        icon = "",
        hl = {
            fg = "#b30b00",
            ctermfg = 124,
        },
    },
    ["php"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["perl"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["pm"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["png"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["puppet"] = {
        icon = "",
        hl = {
            fg = "#FFA61A",
            ctermfg = 15,
        },
    },
    ["ppt"] = {
        icon = "",
        hl = {
            fg = "#cb4a32",
            ctermfg = 167,
        },
    },
    ["idlang"] = {
        icon = "",
        hl = {
            fg = "#e4b854",
            ctermfg = 179,
        },
    },
    ["Procfile"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["ps1"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            ctermfg = 59,
        },
    },
    ["psb"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["psd"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["python"] = {
        icon = "",
        hl = {
            fg = "#ffbc03",
            ctermfg = 61,
        },
    },
    ["pyc"] = {
        icon = "",
        hl = {
            fg = "#ffe291",
            ctermfg = 67,
        },
    },
    ["pyd"] = {
        icon = "",
        hl = {
            fg = "#ffe291",
            ctermfg = 67,
        },
    },
    ["pyo"] = {
        icon = "",
        hl = {
            fg = "#ffe291",
            ctermfg = 67,
        },
    },
    ["r"] = {
        icon = "ﳒ",
        hl = {
            fg = "#358a5b",
            ctermfg = 65,
        },
    },
    ["rake"] = {
        icon = "",
        hl = {
            fg = "#701516",
            ctermfg = 52,
        },
    },
    ["rakefile"] = {
        icon = "",
        hl = {
            fg = "#701516",
            ctermfg = 52,
        },
    },
    ["ruby"] = {
        icon = "",
        hl = {
            fg = "#701516",
            ctermfg = 52,
        },
    },
    ["rlib"] = {
        icon = "",
        hl = {
            fg = "#dea584",
            ctermfg = 180,
        },
    },
    ["rmd"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["rproj"] = {
        icon = "鉶",
        hl = {
            fg = "#358a5b",
            ctermfg = 65,
        },
    },
    ["rust"] = {
        icon = "",
        hl = {
            fg = "#dea584",
            ctermfg = 180,
        },
    },
    ["rss"] = {
        icon = "",
        hl = {
            fg = "#FB9D3B",
            ctermfg = 215,
        },
    },
    ["sass"] = {
        icon = "",
        hl = {
            fg = "#f55385",
            ctermfg = 204,
        },
    },
    ["scala"] = {
        icon = "",
        hl = {
            fg = "#cc3e44",
            ctermfg = 167,
        },
    },
    ["scss"] = {
        icon = "",
        hl = {
            fg = "#f55385",
            ctermfg = 204,
        },
    },
    ["sh"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            ctermfg = 59,
        },
    },
    ["lprolog"] = {
        icon = "λ",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["slim"] = {
        icon = "",
        hl = {
            fg = "#e34c26",
            ctermfg = 166,
        },
    },
    ["sln"] = {
        icon = "",
        hl = {
            fg = "#854CC7",
            ctermfg = 98,
        },
    },
    ["sml"] = {
        icon = "λ",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["sql"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            ctermfg = 188,
        },
    },
    ["sqlite"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            ctermfg = 188,
        },
    },
    ["sqlite3"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            ctermfg = 188,
        },
    },
    ["styl"] = {
        icon = "",
        hl = {
            fg = "#8dc149",
            ctermfg = 107,
        },
    },
    ["sublime"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            ctermfg = 98,
        },
    },
    ["suo"] = {
        icon = "",
        hl = {
            fg = "#854CC7",
            ctermfg = 98,
        },
    },
    ["systemverilog"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    ["svelte"] = {
        icon = "",
        hl = {
            fg = "#ff3e00",
            ctermfg = 202,
        },
    },
    ["svh"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    ["svg"] = {
        icon = "ﰟ",
        hl = {
            fg = "#FFB13B",
            ctermfg = 215,
        },
    },
    ["swift"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["tads"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["tbc"] = {
        icon = "﯑",
        hl = {
            fg = "#1e5cb3",
            ctermfg = 67,
        },
    },
    ["tcl"] = {
        icon = "﯑",
        hl = {
            fg = "#1e5cb3",
            ctermfg = 67,
        },
    },
    ["terminal"] = {
        icon = "",
        hl = {
            fg = "#31B53E",
            ctermfg = 71,
        },
    },
    ["tex"] = {
        icon = "ﭨ",
        hl = {
            fg = "#3D6117",
            ctermfg = 58,
        },
    },
    ["toml"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["tres"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            ctermfg = 185,
        },
    },
    ["typescript"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["tscn"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["typescriptreact"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["twig"] = {
        icon = "",
        hl = {
            fg = "#8dc149",
            ctermfg = 107,
        },
    },
    ["txt"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            ctermfg = 113,
        },
    },
    ["verilog"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    ["vh"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    ["vhdl"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    ["vim"] = {
        icon = "",
        hl = {
            fg = "#019833",
            ctermfg = 29,
        },
    },
    ["vue"] = {
        icon = "﵂",
        hl = {
            fg = "#8dc149",
            ctermfg = 107,
        },
    },
    ["webmanifest"] = {
        icon = "",
        hl = {
            fg = "#f1e05a",
            ctermfg = 221,
        },
    },
    ["webp"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            ctermfg = 140,
        },
    },
    ["webpack"] = {
        icon = "ﰩ",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    ["xcplayground"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["xls"] = {
        icon = "",
        hl = {
            fg = "#207245",
            ctermfg = 23,
        },
    },
    ["xml"] = {
        icon = "謹",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["xul"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            ctermfg = 173,
        },
    },
    ["yaml"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["yml"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            ctermfg = 66,
        },
    },
    ["zig"] = {
        icon = "",
        hl = {
            fg = "#f69a1b",
            ctermfg = 208,
        },
    },
    ["zsh"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            ctermfg = 113,
        },
    },
    ["solidity"] = {
        icon = "ﲹ",
        hl = {
            fg = "#519aba",
            ctermfg = 67,
        },
    },
    [".env"] = {
        icon = "",
        hl = {
            fg = "#faf743",
            ctermfg = 226,
        },
    },
    ["prisma"] = {
        icon = "卑",
        hl = {
            fg = "#ffffff",
            ctermfg = "white",
        },
    },
    ["lock"] = {
        icon = "",
        hl = {
            fg = "#bbbbbb",
            ctermfg = 250,
        },
    },
    ["log"] = {
        icon = "",
        hl = {
            fg = "#ffffff",
            ctermfg = "white",
        },
    },
}

function M.define_highlights()
    for ft, icon_data in iter.KV(M.icons) do
        if icon_data.hl then
            vim.api.nvim_set_hl(0, M.get_hl_group(ft), icon_data.hl)
        end
    end
end

function M.setup(opts)
    opts = opts or {}
    vim.validate({ icons = { opts.icons, "t", true }, alias = { opts.alias, "t", true } })

    M.icons = vim.tbl_deep_extend("force", M.icons, opts.icons or {})
    M.alias = opts.alias or {}

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("LipbWebDevicons", {}),
        callback = M.define_highlights,
    })
end

function M.get_hl_group(ft)
    vim.validate({ ft = { ft, "s" } })
    ft = ft:gsub("[%.%+%-]", "")
    return "LibpDevIcon" .. ft
end

function M.get(file_path)
    require("libp").check_setup(2, M.alias, M.icons)

    -- First check special name that vim can't detect filetypes.
    local ft = pathfn.basename(file_path)

    if not M.icons[ft] then
        -- Try detect file type.
        if vim.version().minor <= 7 then
            local ori_eventignore = vim.o.eventignore
            vim.opt.eventignore:append("all")

            local buf = vim.api.nvim_create_buf(false, true)
            vim.filetype.match(file_path, buf)
            ft = vim.bo[buf].filetype
            vim.cmd("silent! bwipe " .. buf)

            vim.o.eventignore = ori_eventignore
        else
            ft = vim.filetype.match({ filename = file_path })
        end

        if ft == "" then
            ft = nil
        end

        ft = ft ~= "" and ft or nil

        -- It might be a special buffer created by some plugin. And the plugin might already sets its filetype.
        if not ft and vim.fn.bufexists(file_path) > 0 then
            ft = vim.bo[vim.fn.bufadd(file_path)].filetype
            ft = ft ~= "on" and ft or nil
        end

        -- Use extension as the last resort.
        ft = ft or pathfn.extension(file_path)
    end

    ft = ft or "default"
    ft = M.alias[ft] and M.alias[ft] or ft
    -- Use default if not found.
    local res = M.icons[ft] or M.icons["default"]
    return vim.tbl_extend("keep", res, { hl_group = M.get_hl_group(ft) })
end

return M
