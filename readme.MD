# gh-co.nvim

[Github CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) plugin for neovim. This plugin will help you identify code ownership for the files you are editing or you can identify the owners in your Git history.

## Installation

### Plug

The plugin has standard structure so any method should work fine. I personally use [vim.plug](https://github.com/junegunn/vim-plug), so adding this to your configuration file will work:

`Plug 'comatroy/gh-co.nvim'`

## Features

* show codeowner for currently opened file
* show codeowners for all opened buffers
* show codeowners for specific git commit via SHA
* locate & open CODEOWNERS file

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
