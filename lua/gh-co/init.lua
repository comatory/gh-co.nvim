local FS = require('gh-co.fs')
local CO = require('gh-co.co')

local M = {}

M.healthcheck = function()
  print('gh-co.nvim is OK!')
end

M.showCodeownersFile = function()
  print(FS.openCodeownersFile())
end

M.status = function()
  print('CODEOWNERS path:', FS.cachedCodeownersFilePath)
end

M.who = function()
  local filePath = FS.getFilePath()
  CO.matchFileToCodeowner(filePath)
end

M.init = function()
  -- cache path to codeowners path
  FS.getCodeownersFilePath()

  -- commands
  vim.cmd("command! -bang -nargs=0 GhCoHealthcheck :lua require('gh-co').healthcheck()")
  vim.cmd("command! -bang -nargs=0 GhCoStatus :lua require('gh-co').status()")
  vim.cmd("command! -bang -nargs=0 GhCoShowFile :lua require('gh-co').showCodeownersFile()")
  vim.cmd("command! -bang -nargs=0 GhCoWho :lua require('gh-co').who()")
end

return M
