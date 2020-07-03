---@module SAIS
---An implementation of the Suffix Array by Induced Sorting method of
---constructing a suffix array for a text in O(n) time.
---Translated directly from the canonical C implementation from Appendix I of:
---https://www.researchgate.net/publication/224176324_Two_Efficient_Algorithms_for_Linear_Time_Suffix_Array_Construction
---For a more accessible explanation of the algorithm, see here:
---https://zork.net/~st/jottings/sais.html

local byte = string.byte
local function create_stringarray(str)
  local meta = {
    __index = function(_, key)
      return byte(str, key + 1)
    end,
  }
  return setmetatable({}, meta)
end

local function create_intarray(base, offset)
  local meta = {
    __index = function(_, key)
      return base[key + offset]
    end,
    __newindex = function(_, key, value)
      base[key + offset] = value
    end,
  }
  return setmetatable({}, meta)
end

local function is_LMS(types, i)
  return i > 0 and types[i] and not types[i-1]
end

-- find the start or end of each bucket
local function get_buckets(s, bkt, n, K, is_end)
  for i=0,K do bkt[i] = 0 end
  for i=0,n-1 do
    local ch = s[i]
    bkt[ch] = bkt[ch] + 1
  end
  local sum = 0
  if is_end then
    for i=0,K do
      sum = sum + bkt[i]
      bkt[i] = sum
    end
  else
    for i=0,K do
      sum = sum + bkt[i]
      bkt[i] = sum - bkt[i]
    end
  end
end

local function induce_SAl(t, SA, s, bkt, n, K, is_end)
  get_buckets(s, bkt, n, K, is_end)
  for i=0,n-1 do
    local j = SA[i] - 1
    if j >= 0 and not t[j] then
      local ch = s[j]
      SA[bkt[ch]] = j
      bkt[ch] = bkt[ch] + 1
    end
  end
end

local function induce_SAs(t, SA, s, bkt, n, K, is_end)
  get_buckets(s, bkt, n, K, is_end)
  for i=n-1,0,-1 do
    local j = SA[i] - 1
    if j >= 0 and t[j] then
      local ch = s[j]
      bkt[ch] = bkt[ch] - 1
      SA[bkt[ch]] = j
    end
  end
end


-- find the suffix array SA of s[0..n-1] in {1..K}^n
-- require s[n-1]=0 (the sentinel!), n>=2
-- use a working space (excluding s and SA) of at most 2.25n+O(1) for a constant alphabet
local function sa_is(s, SA, n, K)
  local t = {}
  -- Classify the type of each character
  -- the sentinel must be in s1, important!!!
  t[n-2] = false
  t[n-1] = true
  for i=n-3,0,-1 do
    local chi = s[i]
    local chi_1 = s[i+1]
    t[i] = chi < chi_1 or (chi == chi_1 and t[i+1])
  end

  -- stage 1: reduce the problem by at least 1/2
  -- sort all the S-substrings
  local bkt = {}
  get_buckets(s, bkt, n, K, true)
  for i=0,n-1 do SA[i] = -1 end
  for i=1,n-1 do
    if is_LMS(t, i) then
      local ch = s[i]
      bkt[ch] = bkt[ch] - 1
      SA[bkt[ch]] = i
    end
  end

  induce_SAl(t, SA, s, bkt, n, K, false)
  induce_SAs(t, SA, s, bkt, n, K, true)

  -- compact all the sorted substrings into the first n1 items of SA
  -- 2*n1 must be not larger than n (proveable)
  local n1 = 0
  for i=0,n-1 do
    if is_LMS(t, SA[i]) then
      SA[n1] = SA[i]
      n1 = n1 + 1
    end
  end

  -- find the lexicographic names of all substrings
  for i=n1,n-1 do SA[i] = -1 end
  local name, prev = 0, -1
  for i=0,n1-1 do
    local pos = SA[i]
    local diff = false
    for d=0,n-1 do
      if prev == -1
        or s[pos+d] ~= s[prev+d]
        or t[pos+d] ~= t[prev+d] then
        diff = true
        break
      elseif d > 0 and (is_LMS(t, pos+d) or is_LMS(t, prev+d)) then
        break
      end
    end
    if diff then
      name = name + 1
      prev = pos
    end
    pos = (pos % 2 == 0) and pos / 2 or (pos - 1) / 2
    SA[n1+pos] = name - 1
  end

  local j = n - 1
  for i=n-1,n1,-1 do
    if SA[i] >= 0 then
      SA[j] = SA[i]
      j = j - 1
    end
  end

  -- stage 2: solve the reduced problem
  -- recurse if names are not yet unique
  local SA1 = SA
  local s1 = create_intarray(SA, n - n1)
  if name < n1 then
    sa_is(s1, SA1, n1, name - 1)
  else
    -- generate the suffix array of s1 directly
    for i=0,n1-1 do SA1[s1[i]] = i end
  end

  -- stage 3: induce the result for the original problem
  get_buckets(s, bkt, n, K, true)
  j = 0
  for i=1,n-1 do
    if is_LMS(t, i) then
      s1[j] = i
      j = j + 1
    end
  end
  for i=0,n1-1 do
    SA1[i] = s1[SA1[i]]
  end
  for i=n1,n-1 do
    SA[i] = -1
  end
  for i=n1-1,0,-1 do
    j = SA[i]
    SA[i] = -1
    local ch = s[j]
    bkt[ch] = bkt[ch] - 1
    SA[bkt[ch]] = j
  end
  induce_SAl(t, SA, s, bkt, n, K, false)
  induce_SAs(t, SA, s, bkt, n, K, true)
end

local function new(str)
  local SA = {}
  sa_is(create_stringarray(str), SA, #str, 256)
  -- reorganize to 1-indexed
  for i=#SA+1,0,-1 do SA[i] = SA[i-1] end
  SA[0] = nil
  return SA
end

return {
  new = new,
}