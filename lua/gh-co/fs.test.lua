-- Test suite for FS module CODEOWNERS file location logic
--
-- luacheck: ignore 631
-- GitHub CODEOWNERS Standard (https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners#codeowners-file-location):
-- Valid locations in priority order:
--   1. .github/CODEOWNERS (highest priority)
--   2. CODEOWNERS (root directory)
--   3. docs/CODEOWNERS (lowest priority)
--
-- When multiple files exist, GitHub uses the first one found in priority order.

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local lu = require("luaunit")

-- Helper function to create mock vim.fs based on scenario
local function createMockVimFs(scenario)
  return {
    dirname = function(path)
      if path and #path > 0 then
        return scenario.rootPath
      end
      return nil
    end,

    find = function(_names, _opts)
      -- Return root path if any of the search targets exist
      if scenario.hasGithubDir or scenario.hasDocsDir or scenario.rootHasCodeowners then
        return {scenario.rootPath .. "/.github"}  -- any child path works
      end
      return {}
    end,

    dir = function(path)
      if path == scenario.rootPath then
        -- Root directory contents
        local items = {}
        if scenario.hasGithubDir then
          table.insert(items, {".github", "directory"})
        end
        if scenario.hasDocsDir then
          table.insert(items, {"docs", "directory"})
        end
        if scenario.rootHasCodeowners then
          table.insert(items, {"CODEOWNERS", "file"})
        end

        local i = 0
        return function()
          i = i + 1
          if items[i] then
            return items[i][1], items[i][2]
          end
          return nil
        end
      elseif path == scenario.rootPath .. "/.github" then
        -- .github directory contents
        if scenario.githubHasCodeowners then
          local called = false
          return function()
            if not called then
              called = true
              return "CODEOWNERS", "file"
            end
            return nil
          end
        end
        return function() return nil end
      elseif path == scenario.rootPath .. "/docs" then
        -- docs directory contents
        if scenario.docsHasCodeowners then
          local called = false
          return function()
            if not called then
              called = true
              return "CODEOWNERS", "file"
            end
            return nil
          end
        end
        return function() return nil end
      end

      return function() return nil end
    end
  }
end

-- Test class
TestFS = {}

function TestFS:setUp()
  self.FS = require("gh-co.fs")
  -- Clear cached path
  self.FS.cachedCodeownersFilePath = nil

  -- Save original vim global
  self.originalVim = _G.vim

  -- Mock minimal vim APIs needed for FS module
  _G.vim = {
    api = {
      nvim_buf_get_name = function() return "/test/file.txt" end
    },
    loop = {
      cwd = function() return "/test" end
    },
    fs = {}  -- Will be replaced per test
  }
end

function TestFS:tearDown()
  -- Restore original vim global
  _G.vim = self.originalVim

  -- Clear module cache to reload fresh for next test
  package.loaded["gh-co.fs"] = nil
end

-- =============================================================================
-- Priority Tests: Verify GitHub's priority order when multiple files exist
-- =============================================================================

-- Priority #1 > #2: When both .github/CODEOWNERS and root/CODEOWNERS exist,
-- .github/CODEOWNERS should be selected (highest priority)
function TestFS:testPriorityGithubOverRoot() -- luacheck: ignore 212
  local scenario = {
    rootPath = "/test",
    hasGithubDir = true,
    hasDocsDir = false,
    githubHasCodeowners = true,
    docsHasCodeowners = false,
    rootHasCodeowners = true
  }

  _G.vim.fs = createMockVimFs(scenario)
  package.loaded["gh-co.fs"] = nil
  local FS = require("gh-co.fs")

  local result = FS.getCodeownersFilePath()
  lu.assertEquals(result, "/test/.github/CODEOWNERS")
end

-- Priority #2 > #3: When both root/CODEOWNERS and docs/CODEOWNERS exist,
-- root/CODEOWNERS should be selected (priority 2 over 3)
function TestFS:testPriorityRootOverDocs() -- luacheck: ignore 212
  local scenario = {
    rootPath = "/test",
    hasGithubDir = false,
    hasDocsDir = true,
    githubHasCodeowners = false,
    docsHasCodeowners = true,
    rootHasCodeowners = true
  }

  _G.vim.fs = createMockVimFs(scenario)
  package.loaded["gh-co.fs"] = nil
  local FS = require("gh-co.fs")

  local result = FS.getCodeownersFilePath()
  lu.assertEquals(result, "/test/CODEOWNERS")
end

-- Priority #1 > #2 > #3: When all three standard locations have CODEOWNERS,
-- .github/CODEOWNERS should be selected (highest priority)
function TestFS:testPriorityAllThreeLocations() -- luacheck: ignore 212
  local scenario = {
    rootPath = "/test",
    hasGithubDir = true,
    hasDocsDir = true,
    githubHasCodeowners = true,
    docsHasCodeowners = true,
    rootHasCodeowners = true
  }

  _G.vim.fs = createMockVimFs(scenario)
  package.loaded["gh-co.fs"] = nil
  local FS = require("gh-co.fs")

  local result = FS.getCodeownersFilePath()
  lu.assertEquals(result, "/test/.github/CODEOWNERS")
end

-- =============================================================================
-- Standard Location Tests: Single CODEOWNERS file in valid location
-- =============================================================================

-- Standard location #2: CODEOWNERS in repository root (most common simple setup)
function TestFS:testRootCodeownersWithoutGithubDocsDir() -- luacheck: ignore 212
  local scenario = {
    rootPath = "/test",
    hasGithubDir = false,
    hasDocsDir = false,
    githubHasCodeowners = false,
    docsHasCodeowners = false,
    rootHasCodeowners = true
  }

  _G.vim.fs = createMockVimFs(scenario)
  package.loaded["gh-co.fs"] = nil
  local FS = require("gh-co.fs")

  local result = FS.getCodeownersFilePath()
  lu.assertEquals(result, "/test/CODEOWNERS")
end

-- =============================================================================
-- Fallback Scenarios: Directories exist but lack CODEOWNERS files
-- =============================================================================

-- Fallback when .github directory exists but has no CODEOWNERS file,
-- should fall back to root/CODEOWNERS (priority #2)
function TestFS:testGithubDirWithoutCodeownersFile() -- luacheck: ignore 212
  local scenario = {
    rootPath = "/test",
    hasGithubDir = true,
    hasDocsDir = false,
    githubHasCodeowners = false,
    docsHasCodeowners = false,
    rootHasCodeowners = true
  }

  _G.vim.fs = createMockVimFs(scenario)
  package.loaded["gh-co.fs"] = nil
  local FS = require("gh-co.fs")

  local result = FS.getCodeownersFilePath()
  lu.assertEquals(result, "/test/CODEOWNERS")
end

-- Fallback when docs directory exists but has no CODEOWNERS file,
-- should fall back to root/CODEOWNERS (priority #2)
function TestFS:testDocsDirWithoutCodeownersFile() -- luacheck: ignore 212
  local scenario = {
    rootPath = "/test",
    hasGithubDir = false,
    hasDocsDir = true,
    githubHasCodeowners = false,
    docsHasCodeowners = false,
    rootHasCodeowners = true
  }

  _G.vim.fs = createMockVimFs(scenario)
  package.loaded["gh-co.fs"] = nil
  local FS = require("gh-co.fs")

  local result = FS.getCodeownersFilePath()
  lu.assertEquals(result, "/test/CODEOWNERS")
end

-- Fallback when both .github and docs directories exist but neither has CODEOWNERS,
-- should fall back to root/CODEOWNERS (priority #2)
function TestFS:testBothDirsWithoutCodeownersFiles() -- luacheck: ignore 212
  local scenario = {
    rootPath = "/test",
    hasGithubDir = true,
    hasDocsDir = true,
    githubHasCodeowners = false,
    docsHasCodeowners = false,
    rootHasCodeowners = true
  }

  _G.vim.fs = createMockVimFs(scenario)
  package.loaded["gh-co.fs"] = nil
  local FS = require("gh-co.fs")

  local result = FS.getCodeownersFilePath()
  lu.assertEquals(result, "/test/CODEOWNERS")
end

-- =============================================================================
-- Edge Cases: Scenarios where no CODEOWNERS file can be found
-- =============================================================================

-- No CODEOWNERS file exists in any of the three standard locations
function TestFS:testNoCodeownersAnywhere() -- luacheck: ignore 212
  local scenario = {
    rootPath = "/test",
    hasGithubDir = true,
    hasDocsDir = true,
    githubHasCodeowners = false,
    docsHasCodeowners = false,
    rootHasCodeowners = false
  }

  _G.vim.fs = createMockVimFs(scenario)
  package.loaded["gh-co.fs"] = nil
  local FS = require("gh-co.fs")

  local result = FS.getCodeownersFilePath()
  lu.assertEquals(result, nil)
end

-- Repository root directory cannot be detected (no .github, docs, or CODEOWNERS markers found)
function TestFS:testNoRootDetection() -- luacheck: ignore 212
  local scenario = {
    rootPath = "/test",
    hasGithubDir = false,
    hasDocsDir = false,
    githubHasCodeowners = false,
    docsHasCodeowners = false,
    rootHasCodeowners = false
  }

  -- Override find to return empty array (no root found)
  _G.vim.fs = createMockVimFs(scenario)
  _G.vim.fs.find = function() return {} end

  package.loaded["gh-co.fs"] = nil
  local FS = require("gh-co.fs")

  local result = FS.getCodeownersFilePath()
  lu.assertEquals(result, nil)
end

os.exit(lu.LuaUnit.run())
