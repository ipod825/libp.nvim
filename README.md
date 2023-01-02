Libp
=============
[![CI Status](https://github.com/ipod825/libp.nvim/workflows/CI/badge.svg?branch=main)](https://github.com/ipod825/libp.nvim/actions)

A library for neovim plugins.

## Dependency
1. [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation
------------

Use you preferred package manager. Below we use [packer.nvim](https://github.com/wbthomason/packer.nvim) as an example.

```lua
use {'nvim-lua/plenary.nvim'}
use {
	"ipod825/libp.nvim",
	config = function()
		require("libp").setup()
	end,
}
```

## Documentation
See the [online doc](https://ipod825.github.io/libp.nvim/)
