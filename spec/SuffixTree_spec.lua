if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end
local Rope = require "Rope"
local SuffixTree = require "SuffixTree"
local serpent = require "serpent"

local function build_st(...)
  local input = Rope.new()
  for _, str in pairs{...} do
    input:append_segment(str)
    input:append_segment("\0")
  end
  local st = SuffixTree.new(input)
  while not st:run_once() do end
  return st
end

local function to_set(list)
  local out = {}
  for _, v in pairs(list) do
    assert.is_nil(out[v])
    out[v] = true
  end
  return out
end

describe("A SuffixTree should", function()
  it("be constructible from a string with no repeats", function()
    local input = Rope.new()
    input:append_segment("abc")
    local st = SuffixTree.new(input)
    st:run_once()
    st:run_once()
    st:run_once()
    assert.is.not_nil(st.root.edges['a'])
    assert.is_not_nil(st.root.edges['b'])
    assert.is_not_nil(st.root.edges['c'])
  end)
  it("be constructible from a string with no repeats", function()
    local input = Rope.new()
    input:append_segment("cacao")
    local st = SuffixTree.new(input)
    st:run_once()
    st:run_once()
    st:run_once()
    st:run_once()
    st:run_once()
  end)
  it("should decide if a substring is present", function()
    local input = Rope.new()
    input:append_segment("cacao")
    local st = SuffixTree.new(input)
    while not st:run_once() do end
    assert.is.truthy(next(st:segments_with_substring("ca")))
    assert.is.truthy(next(st:segments_with_substring("o")))
    assert.is.falsy(next(st:segments_with_substring("oa")))
    assert.is.falsy(next(st:segments_with_substring("z")))
  end)
  describe("should return a set of sugments where a substring is present", function()
    local function check(segments, queries)
      local st = build_st(table.unpack(segments))
      for _, query in pairs(queries) do
        local result = st:segments_with_substring(query)
        for _, segment in pairs(segments) do
          if segment:find(query, 1, true) then
            assert.is.truthy(result[segment])
          else
            assert.is.falsy(result[segment])
          end
        end
      end
    end
    it("for abcabxabcd", function()
      check({"abcabxabcd"}, {"ab", "abc", "c", "xab", "d", "cd"})
    end)
    it("for segments with some overlap", function()
      check({"abc", "def", "ghi", "efg"}, {"b", "bc", "ef", "fg"})
    end)
  end)

  describe("support searching for matches yielding position", function()
    it("for a known string", function()
      local st = build_st("abcabxabcd\0")
      assert.are.same(to_set{2,5,8}, to_set(st:positions_with_substring("b")))
    end)
  end)

  describe("should create the expected output for known input", function()
    local function assert_pos(st, path, expected_pos)
      local edge = st.root.suffix_link.edges[""]
      for i=1,#path do
        edge = edge.next.edges[string.sub(path, i, i)]
      end
      assert.are.same(expected_pos, edge.start_pos)
    end

    it("ban", function()
      local input = Rope.new()
      input:append_segment("ban")
      local st = SuffixTree.new(input)
      while not st:run_once() do end
      assert_pos(st, "b", 1)
      assert_pos(st, "a", 2)
      assert_pos(st, "n", 3)
    end)
    it("book", function()
      local input = Rope.new()
      input:append_segment("book")
      local st = SuffixTree.new(input)
      while not st:run_once() do end
      assert_pos(st, "b", 1)
      assert_pos(st, "k", 4)
      assert_pos(st, "o", 2)
      assert_pos(st, "ok", 4)
      assert_pos(st, "oo", 3)
    end)
    it("bookk", function()
      local input = Rope.new()
      input:append_segment("bookk")
      local st = SuffixTree.new(input)
      while not st:run_once() do end
      assert_pos(st, "b", 1)
      assert_pos(st, "k", 4)
      assert_pos(st, "o", 2)
      assert_pos(st, "ok", 4)
      assert_pos(st, "oo", 3)
    end)
    it("bookke", function()
      local input = Rope.new()
      input:append_segment("bookke")
      local st = SuffixTree.new(input)
      while not st:run_once() do end
      assert_pos(st, "b", 1)
      assert_pos(st, "k", 4)
      assert_pos(st, "o", 2)
      assert_pos(st, "kk", 5)
      assert_pos(st, "ke", 6)
      assert_pos(st, "ok", 4)
      assert_pos(st, "oo", 3)
      assert_pos(st, "e", 6)
    end)
    it("cacao", function()
      local input = Rope.new()
      input:append_segment("cacao")
      local st = SuffixTree.new(input)
      while not st:run_once() do end
      assert_pos(st, "c", 1)
      assert_pos(st, "a", 2)
      assert_pos(st, "o", 5)
      assert_pos(st, "cc", 3)
      assert_pos(st, "co", 5)
      assert_pos(st, "ac", 3)
      assert_pos(st, "ao", 5)
    end)
  end)
end)