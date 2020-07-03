local Rope = require "Rope"
local serpent = require "serpent"
local StringIndexer = require "StringIndexer"
local SuffixTree = require "SuffixTree"

local function to_set(list)
  local out = {}
  for _,v in pairs(list) do
    out[v] = true
  end
  return out
end

local function to_list(set)
  local out = {}
  for k in pairs(set) do
    out[#out+1] = k
  end
  table.sort(out)
  return out
end

local function uniq(list)
  return to_list(to_set(list))
end

local function table_size(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
  end
  return i
end

local function set_diff(s1, s2)
  local only_in_s1 = {}
  for k in pairs(s1) do
    if not s2[k] then only_in_s1[#only_in_s1+1] = k end
  end
  local only_in_s2 = {}
  for k in pairs(s2) do
    if not s1[k] then only_in_s2[#only_in_s2+1] = k end
  end
  return only_in_s1, only_in_s2
end

local function list_diff(l1, l2)
  local out = {}
  for i=1,#l1 do
    if l1[i] ~= l2[i] then
      out[i] = {l1[i], l2[i]}
    end
  end
  for i=#l1+1,#l2 do
    out[i] = {nil, l2[i]}
  end
  return out
end

local function bench(name, f, n)
  n = n or 10
  local clock = os.clock
  local start = clock()
  for _=1,n do
    f(n)
  end
  local elapsed = clock() - start
  print(name,n,elapsed,elapsed/n)
end

package.path="spec/?.lua;"..package.path
local corpus = require "masc_500k"
for i=1,#corpus do corpus[i] = corpus[i]:lower() end
corpus = uniq(corpus)
--print(serpent.block(corpus))

local reverse = {}
for i, str in ipairs(corpus) do
  if reverse[str] then error("duplicates in corpus") end
  reverse[str] = i
end

local rope = Rope.new(corpus)
io.write("Building rope")
io.flush()
for i, seg in ipairs(corpus) do
  rope:append_segment(seg.."\0")
  if i % 1000 == 0 then io.write(".") io.output():flush() end
end
rope:compact()
print("done")

io.write("Building string indexer")
io.flush()
local suffixed = {}
for i, seg in ipairs(corpus) do
  suffixed[#suffixed+1] = seg.."\0"
end
local indexer = StringIndexer.new(suffixed)
print("done")

--[[
local st = SuffixTree.new(rope)
io.write("Building SuffixTree")
local i = 0
repeat
  i = i + 1
  if i % 1000 == 0 then io.write(".") io.output():flush() end
until st:run_once()
print("done after "..i.." cycles")
--]]

--[[
for i=0,25 do
  local let = string.char(string.byte('a')+i)
  local rope_results = uniq(rope:segments_with_substring(let))
  local st_results = to_list(st:segments_with_substring(let))
  assert(table_size(rope_results) == table_size(st_results))
end
--]]

local function random_string(len)
  local letters = {}
  for i=1,len do
    local let = string.char(string.byte('a')+math.random(0,25))
    letters[#letters+1] = let
  end
  return table.concat(letters)
end

local test_strings = {
  "a",
  "of",
  "the",
  "test",
  "faced",
  "borrow",
}

for _, str in ipairs(test_strings) do
  print("matches = "..#rope:segments_with_substring(str))
  bench("rope-"..str, function(reps)
    for _=1,reps do
      rope:segments_with_substring(str)
    end
  end)

  bench("idxr-"..str, function(reps)
    for _=1,reps do
      indexer:segments_with_substring(str)
    end
  end)

  --[[
  bench("st  -"..str, function(reps)
    for _=1,reps do
      st:segments_with_substring(str)
    end
  end)
  --]]
end