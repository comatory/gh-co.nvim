local FS = {}

FS.cachedCodeownersFilePath = nil

local function hasCodeownersFile(path)
  local dirContents = vim.fs.dir(path)
  for name, kind in dirContents do
    if name == 'CODEOWNERS' and kind == 'file' then
      return true
    end
  end
  return false
end

local function getRootDirectoryName(currentPath)
  local dir = vim.fs.dirname(
    vim.fs.find(
      { ".github", "docs" },
      {
        path = currentPath,
        upward = true
      }
    )[1]
  )
  return dir or nil
end

local function getRealFilePath(candidatePath)
  local _, candidateDir = vim.fs.dir(candidatePath)

  if candidateDir == nil then
    return vim.loop.cwd()
  end

  return candidatePath
end

FS.getFilePath = function()
  return vim.api.nvim_buf_get_name(0) or nil
end

FS.getFilePaths = function()
  local buffers = {}

  for buffer = 1, vim.fn.bufnr('$') do
    if vim.fn.buflisted(buffer) == 1 then
      table.insert(buffers, vim.api.nvim_buf_get_name(buffer))
    end
  end

  return buffers
end

FS.getCodeownersFilePath = function()
  local rootDirName = getRootDirectoryName(getRealFilePath(FS.getFilePath()))

  if rootDirName == nil then return nil end

  local rootDirContents = vim.fs.dir(rootDirName)

  assert(rootDirContents, [[
    Not able to detect project root directory. Maybe you should run nvim from the root of the project.
  ]])

  local hasGithubDir = false
  local hasDocsDir = false
  local hasRootCodeowners = false
  for name, kind in rootDirContents do
    if kind == 'directory' then
      if name == '.github' then
        hasGithubDir = true
      elseif name == 'docs' then
        hasDocsDir = true
      end
    elseif kind == 'file' and name == 'CODEOWNERS' then
      hasRootCodeowners = true
    end
  end

  local codeownerFilePath = nil
  if hasGithubDir and hasCodeownersFile(rootDirName .. '/.github') then
    codeownerFilePath = rootDirName .. '/.github/CODEOWNERS'
  elseif hasDocsDir and hasCodeownersFile(rootDirName .. '/docs') then
    codeownerFilePath = rootDirName .. '/docs/CODEOWNERS'
  elseif hasRootCodeowners then
    codeownerFilePath = rootDirName .. '/CODEOWNERS'
  end

  FS.cachedCodeownersFilePath = codeownerFilePath
  return codeownerFilePath
end

FS.openCodeownersFile = function()
  local path = FS.cachedCodeownersFilePath or FS.getCodeownersFilePath()

  if path == nil then return '' end

  local file = io.open(path, 'r')
  assert(file, "Unable to load codeowner file at path " .. path)

  local data = file:read('a')
  io.close(file)

  return data
end

FS.openCodeownersFileAsLines = function()
  local path = FS.cachedCodeownersFilePath or FS.getCodeownersFilePath()

  if path == nil then return {} end

  return io.lines(path)
end

return FS
