local FS = require('gh-co.fs')

local CO = {}

local function isComment(pathPattern)
  return string.match(pathPattern, '#') ~= nil
end

local function isMatch(pathPattern, filePath)
  if pathPattern == nil then return false end
  if isComment(pathPattern) then return false end

  return string.match(pathPattern, filePath) ~= nil
end

local function extractCodeowners(str)
  local owners = {}
  for _, owner in ipairs(vim.split(str, ",")) do
    owners.insert(owner)
  end

  return owners
end

CO.matchFileToCodeowner = function(filePath)
  local lines = FS.openCodeownersFileAsLines()

  local codeowners = nil
  for line, _, __ in lines do
    local split = vim.split(line, " ")
    local pathPattern = split[1]
    local owners = split[2]

    if isMatch(pathPattern, filePath) then
      codeowners = extractCodeowners(owners)
      break
    end
  end

  return codeowners or {}
end

return CO
