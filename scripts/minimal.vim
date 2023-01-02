set rtp +=.
exec 'set rtp +='..getcwd()..'/../plenary.nvim/'

lua << EOF
require("libp").setup()
EOF

runtime! plugin/plenary.vim
