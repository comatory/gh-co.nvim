local FS = require('gh-co.fs')
local CO = require('gh-co.co')
local G = require('gh-co.git')

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
  local owners = CO.matchFilesToCodeowner({ filePath })

  str = ""
  for _, owner in ipairs(owners) do
    str = str .. " " .. owner
  end

  print(str)
end

M.whos = function()
  local filePaths = FS.getFilePaths()
  local owners = CO.matchFilesToCodeowner(filePaths)

  local buffer = vim.api.nvim_create_buf(true, true)

  if buffer == 0 then return end

  vim.api.nvim_buf_set_name(buffer, 'gh-co://whos')

  local lineCount = vim.api.nvim_buf_line_count(buffer)
  vim.api.nvim_buf_set_lines(buffer, 0, lineCount, false, {})

  for index, owner in ipairs(owners) do
    vim.api.nvim_buf_set_lines(buffer, index - 1, index, false, { owner })
  end

  vim.api.nvim_set_current_buf(buffer)
end

M.gitWho = function(sha)
  local filePaths = G.getAffectedFiles(sha)
  local owners = CO.matchFilesToCodeowner(filePaths)

  local buffer = vim.api.nvim_create_buf(true, true)

  if buffer == 0 then return end

  vim.api.nvim_buf_set_name(buffer, 'gh-co://git-who')

  local lineCount = vim.api.nvim_buf_line_count(buffer)
  vim.api.nvim_buf_set_lines(buffer, 0, lineCount, false, {})

  for index, owner in ipairs(owners) do
    vim.api.nvim_buf_set_lines(buffer, index - 1, index, false, { owner })
  end

  vim.api.nvim_set_current_buf(buffer)
end

M.init = function()
  -- cache path to codeowners path
  FS.getCodeownersFilePath()

  -- commands
  vim.cmd("command! -bang -nargs=0 GhCoHealthcheck :lua require('gh-co').healthcheck()")
  vim.cmd("command! -bang -nargs=0 GhCoStatus :lua require('gh-co').status()")
  vim.cmd("command! -bang -nargs=0 GhCoShowFile :lua require('gh-co').showCodeownersFile()")
  vim.cmd("command! -bang -nargs=0 GhCoWho :lua require('gh-co').who()")
  vim.cmd("command! -bang -nargs=0 GhCoWhos :lua require('gh-co').whos()")
  vim.cmd("command! -bang -nargs=1 GhCoGitWho :lua require('gh-co').gitWho(<f-args>)")
end

return M
