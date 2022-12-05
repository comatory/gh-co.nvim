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

FS.getCodeownersFilePath = function()
  local rootDirName = getRootDirectoryName(getRealFilePath(FS.getFilePath()))
  local _, rootDirStatus = vim.fs.dir(rootDirName)

  assert(rootDirStatus, "Not able to detect project root directory. Maybe you should run nvim from the root of the project.")

  local githubDirName = nil
  local docsDirName = nil
  for name, kind in vim.fs.dir(rootDirName) do
    if hasGithubDirectory(name, kind) then
      githubDirName = name
    end

    if hasDocsDirectory(name, kind) then
      docsDirName = name
    end
  end

  local codeownerDirName = rootDirName .. "/" .. githubDirName or docsDirName
  local _, codeownerDirStatus = vim.fs.dir(codeownerDirName)

  assert(
    codeownerDirStatus,
    "Directory " .. codeownerDirName .. " does not seem to exist."
  )

  local codeownerFileName = nil
  for name, kind in vim.fs.dir(codeownerDirName) do
    if hasCodeownersFile(name, kind) then
      codeownerFileName = name
      break
    end
  end

  if codeownerFileName == nil then return nil end

  local codeownerFilePath = codeownerDirName .. "/" .. codeownerFileName

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
