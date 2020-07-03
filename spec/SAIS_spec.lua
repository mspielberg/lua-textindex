if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end
local SAIS = require "SAIS"

describe("SAIS should", function()
  it("create a suffix array", function()
    local sa = SAIS.new("bca\0")
    assert.are.same({3,2,0,1}, sa)
  end)
end)