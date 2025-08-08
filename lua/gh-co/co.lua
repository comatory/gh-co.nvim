local FS = require('gh-co.fs')

local CO = {}

local function isComment(pathPattern)
  return string.match(pathPattern, '#') ~= nil
end

local function buildEscapedPattern(rawPattern)
  -- Escape Lua pattern special characters except *
  local escaped = string.gsub(rawPattern, "([%-%+%?%(%)])", "%%%1")
  -- Convert * to match any character except /
  escaped = string.gsub(escaped, "%*", "[^/]*")
  -- Anchor pattern to match from start if it doesn't begin with /
  if not string.match(escaped, "^/") then
    escaped = escaped .. "$"
  end
  return escaped
end

-- matches file path substrings
local function isMatch(filePath, pathPattern)
  if pathPattern == nil or pathPattern == "" then return false end
  if isComment(pathPattern) then return false end

  local pattern = buildEscapedPattern(pathPattern)
  return string.match(filePath, pattern) ~= nil
end

-- Detects `*` pattern (global match - only exact "*")
local function isGlobalMatch(pathPattern)
  if pathPattern == nil or pathPattern == "" then return false end
  if isComment(pathPattern) then return false end

  return pathPattern == "*"
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
  local globalCodeowners = nil
  for line, _, __ in lines do
    local split = vim.split(line, " ")
    local pathPattern = split[1]

    for _, filePath in ipairs(filePaths) do
      if isGlobalMatch(pathPattern) then
        globalCodeowners = collectCodeowners(split)
      elseif isMatch(filePath, pathPattern) then
        table.insert(matches, { pathPattern = pathPattern, codeowners = collectCodeowners(split) })
      end
    end
  end

  if #matches == 0 and globalCodeowners ~= nil and #globalCodeowners ~= 0 then return globalCodeowners end
  if #matches == 0 then return {} end

  sortMatches(matches)

  local codeownersList = mapCodeowners(matches)

  return codeownersList
end

return CO
