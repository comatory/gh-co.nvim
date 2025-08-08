rockspec_format = "3.0"
package = "gh-co.nvim"
version = "0.0.4-1"
source = {
   url = "git+ssh://git@github.com/comatory/gh-co.nvim.git"
}
description = {
   summary = "Github CODEOWNERS Neovim plugin",
   detailed = "Displays the code owners for current buffer, all opened buffers or lists owners by providing git SHAs",
   homepage = "https://github.com/comatory/gh-co.nvim",
   license = "CC0 1.0 Universal"
}
dependencies = {
   "lua >= 5.1",
   "luacheck",
}
test_dependencies = {
   "luaunit >= 3.4"
}
build = {
   type = "builtin",
   modules = {
      ["gh-co.co"] = "lua/gh-co/co.lua",
      ["gh-co.fs"] = "lua/gh-co/fs.lua",
      ["gh-co.git"] = "lua/gh-co/git.lua",
      ["gh-co.init"] = "lua/gh-co/init.lua",
      ["gh-co.syntax"] = "lua/gh-co/syntax.lua"
   }
}
test = {
  type = "command",
  command = "lua -l lua/setup lua/gh-co/co.test.lua -o TAP"
}
