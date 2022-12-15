# gh-co.nvim

Github CODEOWNERS plugin for neovim.

## Features

* show codeowner for currently opened file
* show codeowners for all opened buffers
* show codeowners for specific git commit via SHA
* locate & open CODEOWNERS file

## API

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
