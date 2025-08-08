-- Add local lua path for testing
package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local lu = require("luaunit")

-- Create minimal vim global for testing
vim = {
  split = function(s, sep)
    local result = {}
    local pattern = "([^" .. sep .. "]*)"
    for match in string.gmatch(s .. sep, pattern .. sep) do
      table.insert(result, match)
    end
    return result
  end,
  fs = {
    dirname = function() return "/test/.github" end,
    find = function() return {"/test/.github"} end,
    dir = function(path)
      -- Mock directory iterator - return .github directory for root, CODEOWNERS for .github
      if path:match("%.github$") then
        local called = false
        return function()
          if not called then
            called = true
            return "CODEOWNERS", "file"
          end
          return nil
        end
      else
        -- Root directory - return .github directory
        local called = false
        return function()
          if not called then
            called = true
            return ".github", "directory"
          end
          return nil
        end
      end
    end
  },
  loop = {
    cwd = function() return "/test" end
  },
  api = {
    nvim_buf_get_name = function() return "" end
  },
  fn = {
    bufnr = function() return 0 end,
    buflisted = function() return 0 end
  }
}

local CO = require("gh-co.co")

TestCO = {}

function TestCO:setUp()
  -- Mock the FS.openCodeownersFileAsLines to return empty iterator for each test
  self.FS = require("gh-co.fs")
  self.originalOpenCodeownersFileAsLines = self.FS.openCodeownersFileAsLines
  self.FS.openCodeownersFileAsLines = function()
    return function() return nil end
  end
end

function TestCO:tearDown()
  -- Restore original function
  self.FS.openCodeownersFileAsLines = self.originalOpenCodeownersFileAsLines
end

function TestCO:testMatchFilesToCodeownerEmpty() -- luacheck: ignore 212
  -- Test empty file paths returns empty list
  local result = CO.matchFilesToCodeowner({})
  lu.assertEquals(result, {})
end

function TestCO:testGlobalPattern() -- luacheck: ignore 212
  -- Test * pattern matches all files and assigns global owners
  self.FS.openCodeownersFileAsLines = function()
    local lines = {"* @global-owner1 @global-owner2"}
    local i = 0
    return function()
      i = i + 1
      return lines[i]
    end
  end
  
  local result = CO.matchFilesToCodeowner({"README.md", "src/main.js"})
  lu.assertEquals(result, {"@global-owner1", "@global-owner2"})
end

function TestCO:testJavaScriptPattern() -- luacheck: ignore 212
  -- Test *.js pattern matches JavaScript files
  self.FS.openCodeownersFileAsLines = function()
    local lines = {"*.js @js-owner"}
    local i = 0
    return function()
      i = i + 1
      return lines[i]
    end
  end
  
  local result = CO.matchFilesToCodeowner({"app.js", "utils.js"})
  lu.assertEquals(result, {"@js-owner"})
end

function TestCO:testGoPattern() -- luacheck: ignore 212
  -- Test *.go pattern matches Go files
  self.FS.openCodeownersFileAsLines = function()
    local lines = {"*.go docs@example.com"}
    local i = 0
    return function()
      i = i + 1
      return lines[i]
    end
  end
  
  local result = CO.matchFilesToCodeowner({"main.go", "server.go"})
  lu.assertEquals(result, {"docs@example.com"})
end

function TestCO:testTxtPattern() -- luacheck: ignore 212
  -- Test *.txt pattern matches text files with team owner
  self.FS.openCodeownersFileAsLines = function()
    local lines = {"*.txt @octo-org/octocats"}
    local i = 0
    return function()
      i = i + 1
      return lines[i]
    end
  end
  
  local result = CO.matchFilesToCodeowner({"README.txt", "notes.txt"})
  lu.assertEquals(result, {"@octo-org/octocats"})
end

function TestCO:testBuildLogsDirectoryPattern() -- luacheck: ignore 212
  -- Test /build/logs/ pattern matches files in specific directory
  self.FS.openCodeownersFileAsLines = function()
    local lines = {"/build/logs/ @doctocat"}
    local i = 0
    return function()
      i = i + 1
      return lines[i]
    end
  end
  
  local result = CO.matchFilesToCodeowner({"/build/logs/app.log", "/build/logs/error.log"})
  lu.assertEquals(result, {"@doctocat"})
end

os.exit(lu.LuaUnit.run())
