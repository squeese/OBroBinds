local _, addon = ...
local tinsert = table.insert
local tremove = table.remove

local function next(self, fn, ...)
  if self and fn then
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
do
  local subscriptions = {}

  local function subscribe(key, tbl, func)
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
    local subs = subscriptions[key]
    if not subs then return end
    for i = #subs, 1, -1 do
      local tbl = subs[i]
      next(tbl, tbl[key], ...)
    end
  end
  tinsert(addon, dispatch) -- 7

  local function unsubscribe(key, tbl)
    local subs = subscriptions[key]
    if not subs then return end
    for i = #subs, 1, -1 do
      if subs[i] == tbl then
        tremove(subs, i)
        return
      end
    end
  end
  tinsert(addon, unsubscribe) -- 8
end

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
do
  local function write(tbl, key, ...)
    if not tbl then
      return write({}, key, ...)
    elseif type(key) == 'function' then
      tbl = key(tbl, ...)
    elseif select("#", ...) > 1 then
      tbl[key] = write(tbl[key], ...)
    else
      tbl[key] = select(1, ...)
    end
    if tbl then
      for _ in pairs(tbl) do
        return tbl
      end
    end
    return nil
  end
  tinsert(addon, function(...)
    OBroBindsDB = write(OBroBindsDB, ...) -- 9
  end)
end

-- helper function to read from the OBroBindsDB (savedvariables table)
do
  function read(tbl, key, ...)
    if not tbl then return nil end
    if not key then return tbl end
    return dbRead(tbl[key], ...)
  end
  tinsert(addon, function(...)
    return read(OBroBindsDB, ...) -- 10
  end)
end

-- helper function to create a binary representation of the pressed modifier keys
-- left to right, 0001, alt, ctrl, shift
-- first bit is always one, since we store the modifer in tables, no modifier pressed
-- would be the value 1, and since lua tables are not zero index, 'lowest' value must be 1
do
  local bbor = bit.bor
  local function ModifierFlag()
    return bbor(
      1,
      (IsShiftKeyDown() and 2 or 0),
      (IsControlKeyDown() and 4 or 0),
      (IsAltKeyDown() and 8 or 0))
  end
  tinsert(addon, ModifierFlag) -- 11
end
