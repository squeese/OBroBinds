local _, addon = ...
local tinsert = table.insert
local tremove = table.remove

do
  local ref = setmetatable({}, {__mode = 'v'})
  function addon.REF(name, fn)
    print("REF", fn, name)
    tinsert(ref, fn)
  end
  function addon.REPORT()
    collectgarbage("collect")
    print("REPORT BEG", #ref)
    for key, val in pairs(ref) do
      print(val, key)
    end
    --print("REPORT END")
  end
end

local function next(self, fn, ...)
  if self and fn then
  -- if fn then
    return fn(self, ...)
  end
  return self
end
tinsert(addon, next) -- 1

-- helper function to push arguments to the beginning of a table, shift i suppose
local function lpush(self, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    tinsert(self, i, arg)
  end
  return self
end
tinsert(addon, lpush) -- 2

-- helper function to push arguments to the end of a table
local function rpush(self, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    tinsert(self, arg)
  end
  return self
end
tinsert(addon, rpush) -- 3

-- helper function to clean a table of values
local function clean(self, tbl, ...)
  for i = 1, #tbl do
    tbl[i] = nil
  end
  return next(self, ...)
end
tinsert(addon, clean) -- 4

-- helper function to concat tbl with variadic arguments together and pass it along to next function
do
  local __tmp = {}
  local function rcat(self, tbl, ...)
    return next(self, clean, rpush(rpush(__tmp, unpack(tbl)), ...), unpack(__tmp))
  end
  tinsert(addon, rcat) -- 5
end

-- basic subscription/dispatch event system
-- subscribe(key, table, [handlerfunction])
-- dispatch(key, [...arguments)]
-- unsubscribe(key, table)
local subscribe, unsubscribe
do
  local subscriptions = {}

  function subscribe(key, tbl, func)
    --print("sub", key, tbl, func)
    if type(tbl) == 'function' then
      func, tbl = tbl, {}
      addon.REF("random sub func", func)
      addon.REF("random sub table", tbl)
    end
    tbl[key] = func or tbl[key] or next
    if not subscriptions[key] then
      subscriptions[key] = {}
    end
    local subs = subscriptions[key]
    for i = 1, #subs do
      if tbl == subs[i] then return end
    end
    tinsert(subs, 1, tbl)
  end
  tinsert(addon, subscribe) -- 6

  local function dispatch(key, ...)
    --print("DISPATCH", key, ...)
    local subs = subscriptions[key]
    if not subs then return end
    for i = #subs, 1, -1 do
      local tbl = subs[i]
      --print(">>", tbl, tbl[key], ...)
      next(tbl, tbl[key], ...)
    end
  end
  tinsert(addon, dispatch) -- 7

  function unsubscribe(key, tbl, removefn)
    local subs = subscriptions[key]
    if not subs then return end
    for i = #subs, 1, -1 do
      if subs[i] == tbl then
        tremove(subs, i)
        if removefn then
          tbl[key] = nil
        end
        return
      end
    end
  end
  tinsert(addon, unsubscribe) -- 8
end

--[[
do
  local function once(key, fn, tbl)
    subscribe(key, (tbl or {}), function(self, ...)
      fn(...)
      unsubscribe(key, self, true)
    end)
  end
end
]]

do
  -- helper function to write to the OBroBindsDB (savedvariables table)
  -- last argument is the value to write, and the preceding arguments are the path down the table.
  --   write("PRIEST", "F2", "enabled", true)
  -- the results would be:
  --   OBroBindsDB = { ["PRIEST"] = { ["F2"] = { ["enabled"] = true }}}
  -- it is safe to write to a table that doesnt exist yet, the tables will be created
  -- as it traverses along the path, and it will also remove empty tables as it traverses
  -- back, so if we call
  --   write("PRIEST", "F2", "enabled", nil)
  -- with nil as value, the result would be
  -- OBroBindsDB = nil
  -- because there would only be empty tables left
  local function write(tbl, key, ...)
    if not tbl then
      return write({}, key, ...)
    elseif type(key) == 'function' then
      tbl = key(tbl, ...)
    elseif select("#", ...) > 0 then
      tbl[key] = write(tbl[key], ...)
    else
      return key
    end
    if type(tbl) ~= 'table' then
      return tbl
    end
    for _ in pairs(tbl) do
      return tbl
    end
    return nil
  end
  tinsert(addon, write)

  -- helper function to read from the OBroBindsDB (savedvariables table)
  function read(tbl, key, ...)
    if not tbl then return nil end
    if not key then return tbl end
    return read(tbl[key], ...)
  end
  tinsert(addon, read)

  local class
  subscribe("INITIALIZE", {}, function(self, ...)
    class = select(3, ...)
    unsubscribe("INITIALIZE", self, true)
  end)

  tinsert(addon, function(arg1, ...)
    print("dbWrite", arg1, ...)
    OBroBindsDB = write(OBroBindsDB, (arg1 or class), ...) -- 9
  end)
  tinsert(addon, function(arg1, ...)
    return read(OBroBindsDB, (arg1 or class), ...) -- 10
  end)
end

-- helper function to create a binary representation of the pressed modifier keys
-- left to right, 0001, alt, ctrl, shift
-- first bit is always one, since we store the modifer in tables, no modifier pressed
-- would be the value 1, and since lua tables are not zero index, 'lowest' value must be 1
do
  local bbor = bit.bor
  local function getModifier()
    return bbor(1,
      (IsShiftKeyDown() and 2 or 0),
      (IsControlKeyDown() and 4 or 0),
      (IsAltKeyDown() and 8 or 0))
  end
  tinsert(addon, getModifier) -- 11
end

do
  local function match(val, arg, ...)
    if val == arg then return true end
    return select("#", ...) > 0 and next(val, match, ...) or false
  end
  tinsert(addon, match)
end

--[[
do
  local function filter(self, fn, arg1, ...)
    if not arg1 then return self end
    return next(fn(arg1) and rpush(self or {}, arg1) or self, filter, fn, ...)
  end
  --tinsert(addon, filter) 
  local function validStances(self, stance, ...)
    if not stance then return self end
    return next(stance.class == class and rpush(self or {}, stance) or self, validStances, ...)
  end
end
]]
