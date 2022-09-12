-- Modified from https://github.com/kyazdani42/nvim-web-devicons
local M = {}
local KVIter = require("libp.datatype.KVIter")
local path = require("libp.path")

M.icons = {
    default = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    [".babelrc"] = {
        icon = "ﬥ",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    [".bash_profile"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            cterm_fg = "113",
        },
    },
    [".bashrc"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            cterm_fg = "113",
        },
    },
    [".DS_Store"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            cterm_fg = "59",
        },
    },
    [".gitattributes"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            cterm_fg = "59",
        },
    },
    ["gitconfig"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            cterm_fg = "59",
        },
    },
    [".gitignore"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            cterm_fg = "59",
        },
    },
    [".gitlab-ci.yml"] = {
        icon = "",
        hl = {
            fg = "#e24329",
            cterm_fg = "166",
        },
    },
    [".gitmodules"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            cterm_fg = "59",
        },
    },
    [".gvimrc"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    [".npmignore"] = {
        icon = "",
        hl = {
            fg = "#E8274B",
            cterm_fg = "161",
        },
    },
    [".npmrc"] = {
        icon = "",
        hl = {
            fg = "#E8274B",
            cterm_fg = "161",
        },
    },
    [".settings.json"] = {
        icon = "",
        hl = {
            fg = "#854CC7",
            cterm_fg = "98",
        },
    },
    [".vimrc"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    [".zprofile"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            cterm_fg = "113",
        },
    },
    [".zshenv"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            cterm_fg = "113",
        },
    },
    [".zshrc"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            cterm_fg = "113",
        },
    },
    ["Brewfile"] = {
        icon = "",
        hl = {
            fg = "#701516",
            cterm_fg = "52",
        },
    },
    ["CMakeLists.txt"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["gitcommit"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            cterm_fg = "59",
        },
    },
    ["Dockerfile"] = {
        icon = "",
        hl = {
            fg = "#384d54",
            cterm_fg = "59",
        },
    },
    ["Gemfile"] = {
        icon = "",
        hl = {
            fg = "#701516",
            cterm_fg = "52",
        },
    },
    ["LICENSE"] = {
        icon = "",
        hl = {
            fg = "#d0bf41",
            cterm_fg = "179",
        },
    },
    ["R"] = {
        icon = "ﳒ",
        hl = {
            fg = "#358a5b",
            cterm_fg = "65",
        },
    },
    ["Rmd"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["Vagrantfile"] = {
        icon = "",
        hl = {
            fg = "#1563FF",
            cterm_fg = "27",
        },
    },
    ["_gvimrc"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    ["_vimrc"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    ["postscr"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    ["awk"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            cterm_fg = "59",
        },
    },
    ["bash"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            cterm_fg = "113",
        },
    },
    ["dosbatch"] = {
        icon = "",
        hl = {
            fg = "#C1F12E",
            cterm_fg = "154",
        },
    },
    ["bmp"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["c"] = {
        icon = "",
        hl = {
            fg = "#599eff",
            cterm_fg = "75",
        },
    },
    ["c++"] = {
        icon = "",
        hl = {
            fg = "#f34b7d",
            cterm_fg = "204",
        },
    },
    ["cbl"] = {
        icon = "⚙",
        hl = {
            fg = "#005ca5",
            cterm_fg = "25",
        },
    },
    ["cc"] = {
        icon = "",
        hl = {
            fg = "#f34b7d",
            cterm_fg = "204",
        },
    },
    ["cfg"] = {
        icon = "",
        hl = {
            fg = "#ECECEC",
            cterm_fg = "231",
        },
    },
    ["clojure"] = {
        icon = "",
        hl = {
            fg = "#8dc149",
            cterm_fg = "107",
        },
    },
    ["cljc"] = {
        icon = "",
        hl = {
            fg = "#8dc149",
            cterm_fg = "107",
        },
    },
    ["cljs"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["cljd"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["cmake"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["cob"] = {
        icon = "⚙",
        hl = {
            fg = "#005ca5",
            cterm_fg = "25",
        },
    },
    ["cobol"] = {
        icon = "⚙",
        hl = {
            fg = "#005ca5",
            cterm_fg = "25",
        },
    },
    ["coffee"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    ["conf"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["config.ru"] = {
        icon = "",
        hl = {
            fg = "#701516",
            cterm_fg = "52",
        },
    },
    ["cp"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["cpp"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["cpy"] = {
        icon = "⚙",
        hl = {
            fg = "#005ca5",
            cterm_fg = "25",
        },
    },
    ["cr"] = {
        icon = "",
        hl = {
            fg = "#000000",
            cterm_fg = "16",
        },
    },
    ["cs"] = {
        icon = "",
        hl = {
            fg = "#596706",
            cterm_fg = "58",
        },
    },
    ["csh"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            cterm_fg = "59",
        },
    },
    ["cson"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    ["css"] = {
        icon = "",
        hl = {
            fg = "#42a5f5",
            cterm_fg = "39",
        },
    },
    ["csv"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            cterm_fg = "113",
        },
    },
    ["cxx"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["d"] = {
        icon = "",
        hl = {
            fg = "#427819",
            cterm_fg = "64",
        },
    },
    ["dart"] = {
        icon = "",
        hl = {
            fg = "#03589C",
            cterm_fg = "25",
        },
    },
    ["db"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            cterm_fg = "188",
        },
    },
    ["desktop"] = {
        icon = "",
        hl = {
            fg = "#563d7c",
            cterm_fg = "60",
        },
    },
    ["diff"] = {
        icon = "",
        hl = {
            fg = "#41535b",
            cterm_fg = "59",
        },
    },
    ["doc"] = {
        icon = "",
        hl = {
            fg = "#185abd",
            cterm_fg = "25",
        },
    },
    ["dockerfile"] = {
        icon = "",
        hl = {
            fg = "#384d54",
            cterm_fg = "59",
        },
    },
    ["drl"] = {
        icon = "",
        hl = {
            fg = "#ffafaf",
            cterm_fg = "217",
        },
    },
    ["dropbox"] = {
        icon = "",
        hl = {
            fg = "#0061FE",
            cterm_fg = "27",
        },
    },
    ["dump"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            cterm_fg = "188",
        },
    },
    ["edn"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["eex"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["ejs"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    ["elm"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["epuppet"] = {
        icon = "",
        color = "#FFA61A",
    },
    ["eruby"] = {
        icon = "",
        hl = {
            fg = "#701516",
            cterm_fg = "52",
        },
    },
    ["erlang"] = {
        icon = "",
        hl = {
            fg = "#B83998",
            cterm_fg = "132",
        },
    },
    ["elixir"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["exs"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["favicon.ico"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    ["fennel"] = {
        color = "#fff3d7",
        hl = {
            fg = "🌜",
            cterm_fg = "230",
        },
    },
    ["fish"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            cterm_fg = "59",
        },
    },
    ["fsharp"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["fsi"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["fsscript"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["fsx"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["gd"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["gemspec"] = {
        icon = "",
        hl = {
            fg = "#701516",
            cterm_fg = "52",
        },
    },
    ["gif"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["git"] = {
        icon = "",
        hl = {
            fg = "#F14C28",
            cterm_fg = "202",
        },
    },
    ["glb"] = {
        icon = "",
        hl = {
            fg = "#FFB13B",
            cterm_fg = "215",
        },
    },
    ["go"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["godot"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["gruntfile"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["gulpfile"] = {
        icon = "",
        hl = {
            fg = "#cc3e44",
            cterm_fg = "167",
        },
    },
    ["h"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["haml"] = {
        icon = "",
        hl = {
            fg = "#eaeae1",
            cterm_fg = "188",
        },
    },
    ["hbs"] = {
        icon = "",
        hl = {
            fg = "#f0772b",
            cterm_fg = "208",
        },
    },
    ["heex"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["hh"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["hpp"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["hrl"] = {
        icon = "",
        hl = {
            fg = "#B83998",
            cterm_fg = "132",
        },
    },
    ["haskell"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["htm"] = {
        icon = "",
        hl = {
            fg = "#e34c26",
            cterm_fg = "166",
        },
    },
    ["html"] = {
        icon = "",
        hl = {
            fg = "#e44d26",
            cterm_fg = "202",
        },
    },
    ["hxx"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["ico"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    ["import"] = {
        icon = "",
        hl = {
            fg = "#ECECEC",
            cterm_fg = "231",
        },
    },
    ["dosini"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["java"] = {
        icon = "",
        hl = {
            fg = "#cc3e44",
            cterm_fg = "167",
        },
    },
    ["julia"] = {
        icon = "",
        hl = {
            fg = "#a270ba",
            cterm_fg = "133",
        },
    },
    ["jpeg"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["jpg"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["javascript"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    ["json"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    ["javascriptreact"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["ksh"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            cterm_fg = "59",
        },
    },
    ["kotlin"] = {
        icon = "𝙆",
        hl = {
            fg = "#F88A02",
            cterm_fg = "208",
        },
    },
    ["kts"] = {
        icon = "𝙆",
        hl = {
            fg = "#F88A02",
            cterm_fg = "208",
        },
    },
    ["leex"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["less"] = {
        icon = "",
        hl = {
            fg = "#563d7c",
            cterm_fg = "60",
        },
    },
    ["lhaskell"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["lua"] = {
        icon = "",
        hl = {
            fg = "#51a0cf",
            cterm_fg = "74",
        },
    },
    ["make"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["markdown"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["material"] = {
        icon = "",
        hl = {
            fg = "#B83998",
            cterm_fg = "132",
        },
    },
    ["md"] = {
        icon = "",
        hl = {
            fg = "#ffffff",
            cterm_fg = "white",
        },
    },
    ["mdx"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["mint"] = {
        icon = "",
        hl = {
            fg = "#87c095",
            cterm_fg = "108",
        },
    },
    ["mix.lock"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["mjs"] = {
        icon = "",
        hl = {
            fg = "#f1e05a",
            cterm_fg = "221",
        },
    },
    ["ocaml"] = {
        icon = "λ",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["mli"] = {
        icon = "λ",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["mustache"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["nim"] = {
        icon = "👑",
        hl = {
            fg = "#f3d400",
            cterm_fg = "220",
        },
    },
    ["nix"] = {
        icon = "",
        hl = {
            fg = "#7ebae4",
            cterm_fg = "110",
        },
    },
    ["node_modules"] = {
        icon = "",
        hl = {
            fg = "#E8274B",
            cterm_fg = "161",
        },
    },
    ["opus"] = {
        icon = "",
        hl = {
            fg = "#F88A02",
            cterm_fg = "208",
        },
    },
    ["otf"] = {
        icon = "",
        hl = {
            fg = "#ECECEC",
            cterm_fg = "231",
        },
    },
    ["package.json"] = {
        icon = "",
        color = "#e8274b",
    },
    ["package-lock.json"] = {
        icon = "",
        color = "#7a0d21",
    },
    ["pck"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["pdf"] = {
        icon = "",
        hl = {
            fg = "#b30b00",
            cterm_fg = "124",
        },
    },
    ["php"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["perl"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["pm"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["png"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["puppet"] = {
        icon = "",
        color = "#FFA61A",
    },
    ["ppt"] = {
        icon = "",
        hl = {
            fg = "#cb4a32",
            cterm_fg = "167",
        },
    },
    ["idlang"] = {
        icon = "",
        hl = {
            fg = "#e4b854",
            cterm_fg = "179",
        },
    },
    ["Procfile"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["ps1"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            cterm_fg = "59",
        },
    },
    ["psb"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["psd"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["python"] = {
        icon = "",
        hl = {
            fg = "#ffbc03",
            cterm_fg = "61",
        },
    },
    ["pyc"] = {
        icon = "",
        hl = {
            fg = "#ffe291",
            cterm_fg = "67",
        },
    },
    ["pyd"] = {
        icon = "",
        hl = {
            fg = "#ffe291",
            cterm_fg = "67",
        },
    },
    ["pyo"] = {
        icon = "",
        hl = {
            fg = "#ffe291",
            cterm_fg = "67",
        },
    },
    ["r"] = {
        icon = "ﳒ",
        hl = {
            fg = "#358a5b",
            cterm_fg = "65",
        },
    },
    ["rake"] = {
        icon = "",
        hl = {
            fg = "#701516",
            cterm_fg = "52",
        },
    },
    ["rakefile"] = {
        icon = "",
        hl = {
            fg = "#701516",
            cterm_fg = "52",
        },
    },
    ["ruby"] = {
        icon = "",
        hl = {
            fg = "#701516",
            cterm_fg = "52",
        },
    },
    ["rlib"] = {
        icon = "",
        hl = {
            fg = "#dea584",
            cterm_fg = "180",
        },
    },
    ["rmd"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["rproj"] = {
        icon = "鉶",
        hl = {
            fg = "#358a5b",
            cterm_fg = "65",
        },
    },
    ["rust"] = {
        icon = "",
        hl = {
            fg = "#dea584",
            cterm_fg = "180",
        },
    },
    ["rss"] = {
        icon = "",
        hl = {
            fg = "#FB9D3B",
            cterm_fg = "215",
        },
    },
    ["sass"] = {
        icon = "",
        hl = {
            fg = "#f55385",
            cterm_fg = "204",
        },
    },
    ["scala"] = {
        icon = "",
        hl = {
            fg = "#cc3e44",
            cterm_fg = "167",
        },
    },
    ["scss"] = {
        icon = "",
        hl = {
            fg = "#f55385",
            cterm_fg = "204",
        },
    },
    ["sh"] = {
        icon = "",
        hl = {
            fg = "#4d5a5e",
            cterm_fg = "59",
        },
    },
    ["lprolog"] = {
        icon = "λ",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["slim"] = {
        icon = "",
        hl = {
            fg = "#e34c26",
            cterm_fg = "166",
        },
    },
    ["sln"] = {
        icon = "",
        hl = {
            fg = "#854CC7",
            cterm_fg = "98",
        },
    },
    ["sml"] = {
        icon = "λ",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["sql"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            cterm_fg = "188",
        },
    },
    ["sqlite"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            cterm_fg = "188",
        },
    },
    ["sqlite3"] = {
        icon = "",
        hl = {
            fg = "#dad8d8",
            cterm_fg = "188",
        },
    },
    ["styl"] = {
        icon = "",
        hl = {
            fg = "#8dc149",
            cterm_fg = "107",
        },
    },
    ["sublime"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            cterm_fg = "98",
        },
    },
    ["suo"] = {
        icon = "",
        hl = {
            fg = "#854CC7",
            cterm_fg = "98",
        },
    },
    ["systemverilog"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    ["svelte"] = {
        icon = "",
        hl = {
            fg = "#ff3e00",
            cterm_fg = "202",
        },
    },
    ["svh"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    ["svg"] = {
        icon = "ﰟ",
        hl = {
            fg = "#FFB13B",
            cterm_fg = "215",
        },
    },
    ["swift"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["tads"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["tbc"] = {
        icon = "﯑",
        hl = {
            fg = "#1e5cb3",
            cterm_fg = "67",
        },
    },
    ["tcl"] = {
        icon = "﯑",
        hl = {
            fg = "#1e5cb3",
            cterm_fg = "67",
        },
    },
    ["terminal"] = {
        icon = "",
        hl = {
            fg = "#31B53E",
            cterm_fg = "71",
        },
    },
    ["tex"] = {
        icon = "ﭨ",
        hl = {
            fg = "#3D6117",
            cterm_fg = "58",
        },
    },
    ["toml"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["tres"] = {
        icon = "",
        hl = {
            fg = "#cbcb41",
            cterm_fg = "185",
        },
    },
    ["typescript"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["tscn"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["typescriptreact"] = {
        icon = "",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["twig"] = {
        icon = "",
        hl = {
            fg = "#8dc149",
            cterm_fg = "107",
        },
    },
    ["txt"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            cterm_fg = "113",
        },
    },
    ["verilog"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    ["vh"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    ["vhdl"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    ["vim"] = {
        icon = "",
        hl = {
            fg = "#019833",
            cterm_fg = "29",
        },
    },
    ["vue"] = {
        icon = "﵂",
        hl = {
            fg = "#8dc149",
            cterm_fg = "107",
        },
    },
    ["webmanifest"] = {
        icon = "",
        hl = {
            fg = "#f1e05a",
            cterm_fg = "221",
        },
    },
    ["webp"] = {
        icon = "",
        hl = {
            fg = "#a074c4",
            cterm_fg = "140",
        },
    },
    ["webpack"] = {
        icon = "ﰩ",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    ["xcplayground"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["xls"] = {
        icon = "",
        hl = {
            fg = "#207245",
            cterm_fg = "23",
        },
    },
    ["xml"] = {
        icon = "謹",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["xul"] = {
        icon = "",
        hl = {
            fg = "#e37933",
            cterm_fg = "173",
        },
    },
    ["yaml"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["yml"] = {
        icon = "",
        hl = {
            fg = "#6d8086",
            cterm_fg = "66",
        },
    },
    ["zig"] = {
        icon = "",
        hl = {
            fg = "#f69a1b",
            cterm_fg = "208",
        },
    },
    ["zsh"] = {
        icon = "",
        hl = {
            fg = "#89e051",
            cterm_fg = "113",
        },
    },
    ["solidity"] = {
        icon = "ﲹ",
        hl = {
            fg = "#519aba",
            cterm_fg = "67",
        },
    },
    [".env"] = {
        icon = "",
        hl = {
            fg = "#faf743",
            cterm_fg = "226",
        },
    },
    ["prisma"] = {
        icon = "卑",
        hl = {
            fg = "#ffffff",
            cterm_fg = "white",
        },
    },
    ["lock"] = {
        icon = "",
        hl = {
            fg = "#bbbbbb",
            cterm_fg = "250",
        },
    },
    ["log"] = {
        icon = "",
        hl = {
            fg = "#ffffff",
            cterm_fg = "white",
        },
    },
}

local file_name_alias = {
    ["COPYING"] = "LICENSE",
    ["COPYING.LESSER"] = "LICENSE",
    ["license"] = "LICENSE",
}

function M.get_hl_group(ft)
    return "LibpDevIcon" .. ft
end

function M.setup(opts)
    if M.loaded then
        return
    end
    M.loaded = true

    opts = opts or {}
    if opts.icons then
        M.icons = vim.tbl_deep_extend("force", M.icons, opts.icons)
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("LipbWebDevicons", {}),
        callback = function()
            for ft, icon_data in KVIter(M.icons) do
                vim.api.nvim_set_hl(0, M.get_hl_group(ft), icon_data.hl)
            end
        end,
    })
end

function M.get(file_path)
    M.setup()

    -- First check special name that vim can't detect filetypes.
    local basename = path.basename(file_path)
    basename = file_name_alias[basename] or basename
    local ft = basename

    local data = M.icons[basename]
    if not data then
        -- Try detect file type.
        if vim.version().minor <= 7 then
            local ori_eventignore = vim.o.eventignore
            vim.opt.eventignore:append("all")

            local buf = vim.api.nvim_create_buf(false, true)
            vim.filetype.match(file_path, buf)
            ft = vim.api.nvim_buf_get_option(buf, "filetype")
            vim.cmd("bwipe " .. buf)

            vim.o.eventignore = ori_eventignore
        else
            ft = vim.filetype.match({ filename = file_path })
        end

        -- If vim can't detect filetype from file content. Use extension as the
        -- last resort.
        if ft == "" then
            ft = path.extension(file_path) or ft
        end

        -- Use default if not found.
        data = M.icons[ft] or M.icons["default"]
    end

    return vim.tbl_extend("keep", data, { hl_group = M.get_hl_group(ft) })
end

return M
