local Rope = require "Rope"

---@class SuffixTree
---@field rope Rope
local SuffixTree = {}

-- A common concept throughout is the use of s, (k, p) to represent a range
-- of the input that still remains to be processed. s is a node, k is the
-- (inclusive) starting position in the input, and p is the inclusive
-- ending position in the input. If the current active point is a node
-- without having proceeded along any of its outgoing edges, p is k-1 giving
-- an empty range.

---@param self SuffixTree
---@param s number the reference node index of a range
---@param k number the start position of a range
---@param p number the end position of a range
---@return number, number the new reference node index and start position of the range
---                     using the closest node prior to the start position
local function canonize(self, s, k, p)
  local nodes = self.nodes
  local rope = self.rope
  if p < k then return s, k end
  local edge = nodes[s][rope:get_char(k)]
  local sp = edge[3]
  local kp = edge[1]
  local pp = edge[2]
  while pp - kp <= p - k do
    k = k + (pp - kp) + 1
    s = sp
    if k <= p then
      local edge = nodes[s][rope:get_char(k)]
      sp = edge[3]
      kp = edge[1]
      pp = edge[2]
    end
  end
  return s, k
end

---@param self SuffixTree
---@param s number the reference node index of the active point
---@param k number the start position of the active range
---@param p number the end position of the active range
---@param t string the next character in the input
---@return boolean, number
---   true and the original node node if s is the end point
---   of the boundary path traversal.
---   false and the node index where a new outgoing edge needs
---   to be created. The returned node could be a preexisting
---   node, or a new node created by splitting an existing
---   edge, i.e. promoting an implicit node to be an explicit
---   node.
local function test_and_split(self, s, k, p, t)
  local nodes = self.nodes
  if k > p then
    -- range is empty, check if the node already has an outgoing edge for the
    -- character. If so, we are done with the update.
    local edge = nodes[s][t]
    return edge ~= nil, s
  end
    local tk = self.rope:get_char(k)
    local edge = nodes[s][tk]
    local sp = edge[3]
    local kp = edge[1]
    local pp = edge[2]
    local split_pos = kp + p - k + 1
    local split_char = self.rope:get_char(split_pos)
    if t == split_char then
      return true, s
    end
    local new_node = {
      [split_char] = {split_pos, pp, sp}
    }
    nodes[#nodes+1] = new_node
    nodes[s][tk][2] = split_pos - 1
    nodes[s][tk][3] = #nodes
    return false, #nodes
end

---@param self SuffixTree
---@param s number the node index of the active point
---@param k number the input position of the active point
---@param i number the current input position
---@return Node, number the new active point reference node and input position
local function update(self, s, k, i)
  local nodes = self.nodes
  local oldr = self.root
  local ch = self.rope:get_char(i)
  local end_point, r = test_and_split(self, s, k, i - 1, ch)
  while not end_point do
    nodes[r][ch] = { i, math.huge, {suffix_link = nil} }
    if oldr ~= self.root then
      nodes[oldr].suffix_link = r
    end
    oldr = r
    s, k = canonize(self, nodes[s].suffix_link, k, i - 1)
    end_point, r = test_and_split(self, s, k, i - 1, ch)
  end
  if oldr ~= self.root then
    nodes[oldr].suffix_link = s
  end
  return s, k
end

---@return boolean true if the entire input to this point has been processed
function SuffixTree:run_once()
  if self.i >= self.rope:get_length() then return true end
  self.i = self.i + 1
  self.s, self.k = update(self, self.s, self.k, self.i)
  self.s, self.k = canonize(self, self.s, self.k, self.i)
  return false
end

local sub = string.sub

---@param needle string
---@return number[]
function SuffixTree:positions_with_substring(needle)
  local nodes = self.nodes
  local m = self.rope:get_length()
  local l = #needle
  if l <= 0 then return {} end
  local edge = nodes[self.root][sub(needle, 1, 1)]
  if not edge then return {} end
  local i = 1
  local path_length = 0
  while i <= l do
    for pos=edge[1],edge[2] do
      if i > l then
        goto matched
      end
      if pos > m then return {} end
      if self.rope:get_char(pos) ~= sub(needle, i, i) then
        return {}
      end
      i = i + 1
    end
    -- reached end of edge without mismatch
    path_length = path_length + (edge[2] - edge[1] + 1)
    if i <= l then
      local node = nodes[edge[3]]
      if not node then return {} end
      edge = node[sub(needle, i, i)]
      if not edge then return {} end
    end
  end
  ::matched::

  -- DFS to find all leaves
  local stack = {edge}
  local path_lengths = {path_length}
  local out = {}
  while next(stack) do
    local edge = stack[#stack]
    local path_length = path_lengths[#path_lengths]
    stack[#stack] = nil
    path_lengths[#path_lengths] = nil

    if edge[2] >= math.huge then
      -- found a leaf
      out[#out+1] = edge[1] - path_length
    end

    for ch, new_edge in pairs(nodes[edge[3]] or {}) do
      if #ch > 1 then goto continue end
      stack[#stack+1] = new_edge
      if new_edge[2] < math.huge then
        path_lengths[#path_lengths+1] = path_length + (new_edge[2] - new_edge[1] + 1)
      else
        path_lengths[#path_lengths+1] = path_length
      end
      ::continue::
    end
  end

  return out
end

---@param needle string
---@return table<string, true>
function SuffixTree:segments_with_substring(needle)
  local out = {}
  local positions = self:positions_with_substring(needle)
  for k, match_start in pairs(positions) do
    out[self.rope:get_segment(match_start)] = true
  end
  return out
end

local meta = { __index = SuffixTree }

---@return SuffixTree
local function restore(self)
  Rope.restore(self.rope)
  setmetatable(self.nodes[self.empty], {__index = function()
    return { -9e15, -9e15, self.root, }
  end})
  return setmetatable(self, meta)
end

---@param rope Rope
local function new(rope)
  local self = {
    rope = rope or Rope.new(),
    nodes = { {}, {} },
    k = 1,
    i = 0,
  }
  self.empty = 1
  self.root = 2
  self.s = 2
  self.nodes[self.root].suffix_link = 1
  return restore(self)
end

return {
  new = new,
  restore = restore,
}