local FS = require('gh-co.fs')

local CO = {}

local function isComment(pathPattern)
  return string.match(pathPattern, '#') ~= nil
end

local function buildEscapedPattern(rawPattern)
  return string.gsub(rawPattern, "%-", "%%-")
end

local function isMatch(filePath, pathPattern)
  if pathPattern == nil or pathPattern == "" then return false end
  if isComment(pathPattern) then return false end

  return string.match(filePath, buildEscapedPattern(pathPattern)) ~= nil
end

local function collectCodeowners(group)
  local list = {}

  for i = 2, #group, 1 do
    table.insert(list, group[i])
  end

  return list
end

local function sortMatches(matches)
  table.sort(matches, function(a, b)
    return #a.pathPattern > #b.pathPattern
  end)
end

local function containsValue(list, value)
  for i = 1, #list do
    if list[i] == value then return true end
  end

  return false
end

local function mapCodeowners(matches)
  local list = {}

  for _, item in ipairs(matches) do
    for _, owner in ipairs(item.codeowners) do
      if containsValue(list, owner) == false then
        table.insert(list, owner)
      end
    end
  end

  return list
end

CO.matchFilesToCodeowner = function(filePaths)
  local lines = FS.openCodeownersFileAsLines()

  local matches = {}
  for line, _, __ in lines do
    local split = vim.split(line, " ")
    local pathPattern = split[1]

    for _, filePath in ipairs(filePaths) do
      if isMatch(filePath, pathPattern) then
        local codeowners = collectCodeowners(split)
        table.insert(matches, { pathPattern = pathPattern, codeowners = codeowners })
      end
    end
  end

  if #matches == 0 then return {} end

  sortMatches(matches)

  local codeownersList = mapCodeowners(matches)

  return codeownersList
end

return CO
