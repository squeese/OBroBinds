local _, addon = ...
local tinsert = table.insert
local tremove = table.remove

do
  local funcs = setmetatable({}, {__mode = 'v'})
  local names = {}
  local active = {}
  local clean = {}

  function addon.REF(desc, func)
    local name = tostring(func)
    names[name] = desc
    active[name] = true
    tinsert(funcs, func)
  end

  function addon.REPORT()
    print("report")
    local tmp = {}
    for name in pairs(active) do
      tmp[name] = true
    end
    for _, func in pairs(funcs) do
      local name = tostring(func)
      tmp[name] = nil
      print("active", name, names[name])
    end
    for name in pairs(tmp) do
      tinsert(clean, name)
    end
    for _, name in pairs(clean) do
      print("clean", name, names[name])
    end
  end
end

local function next(fn, ...)
  if fn and type(fn) == 'function' then
    return fn(...)
  end
  return fn, ...
end
addon.next = next

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
addon.empty = empty

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
    addon.REF(key, func)
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

local function updateMainbarBindings(tbl)
  if tbl then
    for key in pairs(tbl) do
      tbl[key] = nil
    end
  end
  for index = 1, 12 do
    local binding = GetBindingKey("ACTIONBUTTON"..index)
    if binding then
      tbl = write(tbl, binding, index)
    end
  end
  return tbl
end
addon.updateMainbarBindings = updateMainbarBindings

for key, val in pairs(addon) do
  addon.REF("addon."..key, val)
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

--function clean(tbl, ...)
  --for i = 1, #tbl do
    --tbl[i] = nil
  --end
  --return next(...)
--end
--tinsert(addon, clean) -- 4

