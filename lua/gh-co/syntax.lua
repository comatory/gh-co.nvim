local M = {}

local function setup_highlight_groups()
  -- Define highlight groups for CODEOWNERS syntax
  vim.api.nvim_set_hl(0, "CodeownersComment", { link = "Comment" })
  vim.api.nvim_set_hl(0, "CodeownersPath", { link = "Identifier" })
  vim.api.nvim_set_hl(0, "CodeownersGlobalPath", { link = "Special" })

  -- Try to use treesitter highlight groups for better theming
  local has_treesitter = pcall(require, 'nvim-treesitter')
  if has_treesitter and vim.fn.hlexists("@string.special") == 1 then
    vim.api.nvim_set_hl(0, "CodeownersOwner", { link = "@string.special" })
  else
    vim.api.nvim_set_hl(0, "CodeownersOwner", { link = "String" })
  end
end

local function highlight_line(bufnr, line_num, line_content)
  local ns_id = vim.api.nvim_create_namespace("codeowners_syntax")
  -- Clear existing highlights for this line
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_num, line_num + 1)

  -- Skip empty lines
  if line_content:match("^%s*$") then
    return
  end
  -- Highlight comments (lines starting with #)
  if line_content:match("^%s*#") then
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, 0, {
      end_col = #line_content,
      hl_group = "CodeownersComment"
    })
    return
  end

  -- Parse non-comment lines: path_pattern owner1 owner2 ...
  local parts = vim.split(line_content, "%s+")
  if #parts < 2 then
    return
  end

  local path_pattern = parts[1]
  local col_start = 0
  local col_end = #path_pattern

  -- Highlight path pattern
  if path_pattern == "*" then
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, col_start, {
      end_col = col_end,
      hl_group = "CodeownersGlobalPath"
    })
  else
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, col_start, {
      end_col = col_end,
      hl_group = "CodeownersPath"
    })
  end

  -- Find and highlight owners
  local remaining_line = line_content:sub(col_end + 1)
  local offset = col_end

  for i = 2, #parts do
    local owner = parts[i]
    local owner_start = remaining_line:find(owner, 1, true)

    if owner_start then
      local actual_start = offset + owner_start - 1
      local actual_end = actual_start + #owner

      -- Determine highlight group based on owner format
      if owner:find("@") then
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, actual_start, {
          end_col = actual_end,
          hl_group = "CodeownersOwner"
        })
      end

      -- Update offset for next owner
      remaining_line = remaining_line:sub(owner_start + #owner)
      offset = actual_end
    end
  end
end

local function highlight_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for line_num, line_content in ipairs(lines) do
    highlight_line(bufnr, line_num - 1, line_content)
  end
end

local function setup_autocmds(bufnr)
  local group = vim.api.nvim_create_augroup("CodeownersSyntax", { clear = false })

  -- Re-highlight on text changes
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      highlight_buffer(bufnr)
    end,
  })

  -- Initial highlighting
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    buffer = bufnr,
    callback = function()
      highlight_buffer(bufnr)
    end,
  })
end

M.setup_codeowners_syntax = function(bufnr)
  setup_highlight_groups()
  setup_autocmds(bufnr)
  highlight_buffer(bufnr)
end

return M
