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
local function word_from_index(self, word_index)
  local starts = self.starts
  local start_pos = starts[word_index]
  local end_pos = starts[word_index+1]
  return sub(self.merged, start_pos, end_pos and end_pos-1)
end

function StringIndexer:word_from_pos(pos)
  assert(pos >= 1 and pos <= #self.merged)
  local index = binsearch(self.starts, pos)
  return word_from_index(self, index)
end

local function new(strings)
  local self = setmetatable({}, { __index = StringIndexer })
  local pos = 1
  local list = {}
  self.starts = {}
  for _, str in pairs(strings) do
    list[#list+1] = str
    self.starts[#self.starts+1] = pos
    pos = pos + #str
  end
  self.merged = table.concat(list)
  return self
end

return {
  new = new,
}