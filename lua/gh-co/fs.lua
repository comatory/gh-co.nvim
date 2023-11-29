local FS = {}

FS.cachedCodeownersFilePath = nil

local function hasGithubDirectory(name, kind)
  return name == '.github' and kind == 'directory'
end

local function hasDocsDirectory(name, kind)
  return name == 'docs' and kind == 'directory'
end

local function hasCodeownersFile(name, kind)
  return name == 'CODEOWNERS' and kind == 'file'
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

  assert(rootDirContents, "Not able to detect project root directory. Maybe you should run nvim from the root of the project.")

  local githubDirName = nil
  local docsDirName = nil
  for name, kind in rootDirContents do
    if hasGithubDirectory(name, kind) then
      githubDirName = name
    end

    if hasDocsDirectory(name, kind) then
      docsDirName = name
    end
  end

  local codeownerDirName = rootDirName .. "/" .. githubDirName or docsDirName
  local codeownerDirContents = vim.fs.dir(codeownerDirName)

  assert(
    codeownerDirContents,
    "Directory " .. codeownerDirName .. " does not seem to exist."
  )

  local codeownerFileNameWithinDefaultFolder = nil
  for name, kind in codeownerDirContents do
    if hasCodeownersFile(name, kind) then
      codeownerFileNameWithinDefaultFolder = name
      break
    end
  end

  local codeownerFilePath = nil

  -- handles case when project is storing CODEOWNERS file in root directory
  if codeownerFileNameWithinDefaultFolder == nil then
    for name, kind in vim.fs.dir(rootDirName) do
      if hasCodeownersFile(name, kind) then
        codeownerFilePath = rootDirName .. "/" .. name
        FS.cachedCodeownersFilePath = codeownerFilePath
        break
      end
    end

    return codeownerFilePath
  else
    codeownerFilePath = codeownerDirName .. "/" .. codeownerFileNameWithinDefaultFolder

    FS.cachedCodeownersFilePath = codeownerFilePath

    return codeownerFilePath
  end
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
