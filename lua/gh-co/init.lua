local FS = require('gh-co.fs')
local CO = require('gh-co.co')

local M = {}

M.healthcheck = function()
  print('gh-co.nvim is OK!')
end

M.showCodeownersFile = function()
  local path = FS.getCodeownersFilePath()

  if path == nil then return end

  vim.cmd.edit(path)
end

M.status = function()
  print('CODEOWNERS path:', FS.cachedCodeownersFilePath)
end

M.who = function()
  local filePath = FS.getFilePath()
  local owners = CO.matchFileToCodeowner(filePath)

  str = ""
  for _, owner in ipairs(owners) do
    str = str .. " " .. owner
  end

  return str
end

M.whoPrint = function()
  local filePath = FS.getFilePath()
  local owners = CO.matchFileToCodeowner(filePath)

  for _, owner in ipairs(owners) do
    print(owner)
  end
end

M.init = function()
  -- cache path to codeowners path
  FS.getCodeownersFilePath()

  -- commands
  vim.cmd("command! -bang -nargs=0 GhCoHealthcheck :lua require('gh-co').healthcheck()")
  vim.cmd("command! -bang -nargs=0 GhCoStatus :lua require('gh-co').status()")
  vim.cmd("command! -bang -nargs=0 GhCoShowFile :lua require('gh-co').showCodeownersFile()")
  vim.cmd("command! -bang -nargs=0 GhCoWho :lua require('gh-co').who()")
  vim.cmd("command! -bang -nargs=0 GhCoWhoPrint :lua require('gh-co').whoPrint()")
end

return M
