local G = {}

G.getAffectedFiles = function(sha)
  if sha == nil then error('Missing sha argument') end

  local tmpFile = assert(io.popen('git --no-pager show --pretty="format:" --name-only ' .. sha, 'r'))
  local out = assert(tmpFile:read('*a'))

  tmpFile:close()

  return vim.split(out, "\n")
end

return G
