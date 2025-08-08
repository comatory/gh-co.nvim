# gh-co.nvim

[Github CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) plugin for neovim. This plugin will help you identify code ownership for the files you are editing or you can identify the owners in your Git history.

## Installation

The plugin has standard structure so any method should work fine.

### [`lazy.nvim`](https://github.com/folke/lazy.nvim)

```lua
-- ~/.config/nvim/lua/plugins/gh-co.lua
return {
  "comatory/gh-co.nvim",
  config = function()
     vim.keymap.set("n", "<leader>gg", ":GhCoWho<CR>", {})
  end
}
```

### [`vim.plug`](https://github.com/junegunn/vim-plug)

`Plug 'comatory/gh-co.nvim'`

## Features

* show codeowner for currently opened file
* show codeowners for all opened buffers
* show codeowners for specific git commit via SHA
* locate & open CODEOWNERS file
* syntax highlighting for CODEOWNERS files

## API

The plugin exposes several commands prefixed with `GhCo*`. There are no default key bindings for running these so it's up to you to configure it.

### `:GhCoHealthcheck`

Show whether plugin is running OK.

### `:GhCoStatus`

Shows plugin configuration.

### `:GhCoShowFile`

Open CODEOWNERS file in a buffer.

### `:GhCoWho`

Show codeowners for file in an active buffer.

### `:GhCoWhos`

Show codeowners for files in all buffers.

### `:GhCoGitWho <SHA>`

Show codeowners for files affected by commit SHA.

## Development

Project is using luarocks to manage dependencies. After cloning the repo run:

```bash
luarocks install --deps-only gh-co.nvim-0.0.4-1.rockspec
```

### Lint

Run `PATH="./lua_modules/bin:PATH" luacheck lua` to lint the codebase

### Test

Run `luarocks test`
