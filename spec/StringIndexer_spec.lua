if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end
local StringIndexer = require "StringIndexer"

local function to_set(list)
  local out = {}
  for _, v in pairs(list) do
    out[v] = true
  end
  return out
end

describe("A StringIndexer should", function()
  it("extract words based on position in the input", function()
    local input = {
      "foo",
      "bar",
      "baz",
      "zot",
    }
    local uut = StringIndexer.new(input)
    assert.are.same("foo", uut:segment_from_pos(1))
    assert.are.same("foo", uut:segment_from_pos(2))
    assert.are.same("foo", uut:segment_from_pos(3))
    assert.are.same("bar", uut:segment_from_pos(4))
    assert.are.same("bar", uut:segment_from_pos(5))
    assert.are.same("bar", uut:segment_from_pos(6))
    assert.are.same("baz", uut:segment_from_pos(7))
    assert.are.same("baz", uut:segment_from_pos(8))
    assert.are.same("baz", uut:segment_from_pos(9))
    assert.are.same("zot", uut:segment_from_pos(10))
    assert.are.same("zot", uut:segment_from_pos(11))
    assert.are.same("zot", uut:segment_from_pos(12))
  end)
  it("extract words based on substring match", function()
    local input = {
      "foo\0",
      "bar\0",
      "baz\0",
      "zot\0",
    }
    local uut = StringIndexer.new(input)
    assert.are.same(to_set{"foo\0"}, uut:segments_with_substring("oo"))
    assert.are.same(to_set{"foo\0","zot\0"}, uut:segments_with_substring("o"))
    assert.are.same(to_set{"bar\0","baz\0"}, uut:segments_with_substring("a"))
    assert.are.same(to_set{"baz\0","zot\0"}, uut:segments_with_substring("z"))
    assert.are.same(to_set{}, uut:segments_with_substring("rb"))
    assert.are.same(to_set{}, uut:segments_with_substring("zos"))
  end)
end)