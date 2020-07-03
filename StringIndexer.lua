local SAIS = require "SAIS"

local StringIndexer = {}

local floor = math.floor
local function binsearch(a, x)
  local left = 1
  local right = #a
  local mid = 1
  while left <= right do
    mid = floor((left + right) / 2)
    if x < a[mid] then
      right = mid - 1
    else
      left = mid + 1
    end
  end
  if mid > #a or a[mid] > x then
    mid = mid - 1
  end
  if mid < 1 then
    mid = 1
  end
  return mid
end

local sub = string.sub
local function segment_from_index(self, word_index)
  local starts = self.starts
  local start_pos = starts[word_index]
  local end_pos = starts[word_index+1]
  return sub(self.merged, start_pos, end_pos and end_pos-1)
end

function StringIndexer:segment_from_pos(pos)
  assert(pos >= 1 and pos <= #self.merged)
  local index = binsearch(self.starts, pos)
  return segment_from_index(self, index)
end

local byte = string.byte
local char = string.char
function StringIndexer:segments_with_substring(needle)
  -- abc -> abc\0
  local start = binsearch(self.sa_proxy, needle .. "\0")
  if sub(self.sa_proxy[start], 1, #needle) ~= needle then
    start = start + 1
  end

  -- abc -> abd\0
  local last_str = sub(needle, 1, -2) .. char(byte(sub(needle, -1)) + 1, 0)
  local last = binsearch(self.sa_proxy, last_str)
  if sub(self.sa_proxy[last], 1, #last_str) == last_str then
    last = last - 1
  end

  local words = {}
  for i = start, last do
    words[self:segment_from_pos(self.suffix_array[i])] = true
  end
  return words
end

local function create_suffix_array(text)
  return SAIS.new(text)
end

local proxy_meta = {
  __index = function(self, index)
    return sub(self.merged, self.suffix_array[index])
  end,
  __len = function(self)
    return #self.suffix_array
  end,
}

local function new(strings)
  local self = setmetatable({}, { __index = StringIndexer })
  self.merged = table.concat(strings)

  local pos = 1
  self.starts = {}
  for _, str in pairs(strings) do
    self.starts[#self.starts+1] = pos
    pos = pos + #str
  end

  self.suffix_array = create_suffix_array(self.merged)
  -- fake table that can be indexed to get the nth suffix in lexicographic order
  -- of the merged list
  self.sa_proxy = setmetatable({
    merged = self.merged,
    suffix_array = self.suffix_array,
  }, proxy_meta)

  return self
end

return {
  new = new,
}