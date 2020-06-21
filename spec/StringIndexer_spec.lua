local serpent = require "serpent"
local StringIndexer = require "StringIndexer"

describe("A StringIndexer should", function()
  it("extract words based on position in the input", function()
    local input = {
      "foo",
      "bar",
      "baz",
      "zot",
    }
    local uut = StringIndexer.new(input)
    assert.are.same("foo", uut:word_from_pos(1))
    assert.are.same("foo", uut:word_from_pos(2))
    assert.are.same("foo", uut:word_from_pos(3))
    assert.are.same("bar", uut:word_from_pos(4))
    assert.are.same("bar", uut:word_from_pos(5))
    assert.are.same("bar", uut:word_from_pos(6))
    assert.are.same("baz", uut:word_from_pos(7))
    assert.are.same("baz", uut:word_from_pos(8))
    assert.are.same("baz", uut:word_from_pos(9))
    assert.are.same("zot", uut:word_from_pos(10))
    assert.are.same("zot", uut:word_from_pos(11))
    assert.are.same("zot", uut:word_from_pos(12))
  end)
end)