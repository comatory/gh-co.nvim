local lu = require("luaunit")

local function TestCodeowners()
  lu.assertEquals(1, 1)
end

os.exit(lu.LuaUnit.run())
