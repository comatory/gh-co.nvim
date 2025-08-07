local FS = require('gh-co.fs')
local CO = require('gh-co.co')
local G = require('gh-co.git')

local M = {}

local function createNamedBuffer(name)
  local buffer = vim.api.nvim_create_buf(true, true)

  if buffer == 0 then return nil end

  vim.api.nvim_buf_set_name(buffer, name)

  return buffer
end

local function getBufferHandleByName(name)
  for buffer = 1, vim.fn.bufnr('$') do
    if vim.api.nvim_buf_is_valid(buffer) then
      local bufferName = vim.api.nvim_buf_get_name(buffer)

      if bufferName == name then return buffer end
    end
  end
end

local function writeBufferOwnerContents(buffer, owners)
  local lineCount = vim.api.nvim_buf_line_count(buffer)
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, lineCount, false, {})

  if #owners > 0 then
    for index, owner in ipairs(owners) do
      vim.api.nvim_buf_set_lines(buffer, index - 1, index, false, { owner })
    end
  else
    vim.api.nvim_buf_set_lines(buffer, 0, 1, false, { '[no owners detected]' })
  end

  vim.bo[buffer].modifiable = false
  vim.api.nvim_set_current_buf(buffer)
end

local function checkCodeownersFileExists()
  assert(FS.cachedCodeownersFilePath, "Problem reading Codeowners file path. Try running :GhCoHealthcheck")
end

M.healthcheck = function()
  print('gh-co.nvim plugin loaded OK. Codeowners file path:', FS.cachedCodeownersFilePath or 'not found')
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
  checkCodeownersFileExists()
  local filePath = FS.getFilePath()
  local owners = CO.matchFilesToCodeowner({ filePath })

  local str = ""
  for _, owner in ipairs(owners) do
    str = str .. " " .. owner
  end

  print(str)
end

M.whos = function()
  checkCodeownersFileExists()
  local filePaths = FS.getFilePaths()
  local owners = CO.matchFilesToCodeowner(filePaths)

  local existingBuffer = getBufferHandleByName('gh-co://whos')

  if existingBuffer then
    writeBufferOwnerContents(existingBuffer, owners)
  else
    local buffer = createNamedBuffer('gh-co://whos')

    if buffer == 0 then return end

    writeBufferOwnerContents(buffer, owners)
  end
end

M.gitWho = function(sha)
  checkCodeownersFileExists()
  local filePaths = G.getAffectedFiles(sha)
  local owners = CO.matchFilesToCodeowner(filePaths)

  local existingBuffer = getBufferHandleByName('gh-co://git-who')

  if existingBuffer then
    writeBufferOwnerContents(existingBuffer, owners)
  else
    local buffer = createNamedBuffer('gh-co://git-who')

    if buffer == 0 then return end

    writeBufferOwnerContents(buffer, owners)
  end
end

M.init = function()
  -- cache path to codeowners path
  FS.getCodeownersFilePath()

  -- setup filetype detection and syntax highlighting for CODEOWNERS files
  local group = vim.api.nvim_create_augroup("GhCoCodeowners", { clear = true })
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = group,
    pattern = { "CODEOWNERS", "*/CODEOWNERS", ".github/CODEOWNERS", "docs/CODEOWNERS" },
    callback = function(args)
      local bufnr = args.buf
      vim.bo[bufnr].filetype = 'codeowners'

      -- Apply syntax highlighting
      local syntax = require('gh-co.syntax')
      syntax.setup_codeowners_syntax(bufnr)
    end,
  })

  -- commands
  vim.cmd("command! -bang -nargs=0 GhCoHealthcheck :lua require('gh-co').healthcheck()")
  vim.cmd("command! -bang -nargs=0 GhCoStatus :lua require('gh-co').status()")
  vim.cmd("command! -bang -nargs=0 GhCoShowFile :lua require('gh-co').showCodeownersFile()")
  vim.cmd("command! -bang -nargs=0 GhCoWho :lua require('gh-co').who()")
  vim.cmd("command! -bang -nargs=0 GhCoWhos :lua require('gh-co').whos()")
  vim.cmd("command! -bang -nargs=1 GhCoGitWho :lua require('gh-co').gitWho(<f-args>)")
end

return M
