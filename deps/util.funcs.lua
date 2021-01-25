local _, addon = ...
local tinsert = table.insert
local tremove = table.remove

local function next(fn, ...)
  if fn and type(fn) == 'function' then
    return fn(...)
  end
  return fn, ...
end
addon.next = next

local function spread(tbl, ...)
  if tbl then
    return unpack(tbl)
  end
  return nil
end
addon.spread = spread

local function rpush(tbl, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    tinsert(tbl, arg)
  end
  return tbl
end
addon.rpush = rpush

local function empty(tbl, ...)
  if tbl then
    for i = 1, #tbl do
      tbl[i] = nil
    end
  end
  return ...
end
addon.empty = empty

local function match(val, arg, ...)
  if val == arg then return true end
  return select("#", ...) > 0 and next(val, match, ...) or false
end
addon.match = match

do
  local subscriptions = {}

  local function subscribe(key, func)
    if not subscriptions[key] then
      subscriptions[key] = {}
    end
    local subs = subscriptions[key]
    for i = 1, #subs do
      if func == subs[i] then return end
    end
    tinsert(subs, 1, func)
  end
  addon.subscribe = subscribe

  local function unsubscribe(key, func)
    local subs = subscriptions[key]
    if not subs then return end
    for i = 1, #subs do
      if subs[i] == func then
        tremove(subs, i)
        return
      end
    end
  end
  addon.unsubscribe = unsubscribe

  local queue = {}
  local QUEUE = {}
  QUEUE.__index = QUEUE
  function QUEUE:unsub()
    unsubscribe(self.key, self.fn)
    return self
  end
  function QUEUE:next(...)
    if #self > 0 then
      self.fn = tremove(self)
      if type(self.fn) == 'table' then
        return self.fn[self.key](self.fn, self, ...)
      end
      return self.fn(self, ...)
    end
    self.fn = nil
    tinsert(queue, self)
    return ...
  end

  local function dispatch(key, ...)
    local subs = subscriptions[key]
    if not subs then return end
    local event = tremove(queue) or setmetatable({}, QUEUE)
    assert(#event == 0, event.key)
    assert(event.fn == nil, event.key)
    event.key = key
    rpush(event, unpack(subs))
    return event:next(...)
  end
  addon.dispatch = dispatch
end

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
addon.write = write

local function read(tbl, key, ...)
  if not tbl then return nil end
  if not key then return tbl end
  return read(tbl[key], ...)
end
addon.read = read

do
  local class
  addon.subscribe("PLAYER_LOGIN", function(event, frame, ...)
    class = select(2, UnitClass("player"))
    return event:unsub():next(frame, ...)
  end)
  function addon.dbWrite(arg1, ...)
    OBroBindsDB = write(OBroBindsDB, (arg1 or class), ...)
  end
  function addon.dbRead(arg1, ...)
    return read(OBroBindsDB, (arg1 or class), ...)
  end
end

do
  local fns = {}
  local function empty(...)
    while #fns > 0 do
      tremove(fns)
    end
    return ...
  end
  function addon:get(...)
    for i = 1, select("#", ...) do
      fns[i] = self[select(i, ...)]
    end
    return empty(unpack(fns))
  end
end

do
  local pAlt, pCtrl, pShift, modifier
  local function getModifier()
    local nAlt, nCtrl, nShift = IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
    if not (pAlt == nAlt and pCtrl == nCtrl and pShift == nShift) then
      pAlt, pCtrl, pShift = nAlt, nCtrl, nShift
      modifier = (pAlt and "ALT-" or "")..(pCtrl and "CTRL-" or "")..(pShift and "SHIFT-" or "")
    end
    return modifier
  end
  addon.getModifier = getModifier
end
