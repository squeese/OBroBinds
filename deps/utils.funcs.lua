local _A = select(2, ...)
local tinsert = _G.table.insert
local tremove = _G.table.remove

local function splice(tbl, index)
  tremove(tbl, index)
  return tbl
end
_A.splice = splice

local function shift(self, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    tinsert(self, i, arg)
  end
  return self
end
_A.shift = shift

local function push(tbl, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    if arg ~= nil then
      tinsert(tbl, arg)
    end
  end
  return tbl
end
_A.push = push

local function read(tbl, key, ...)
  if not tbl then return nil end
  if not key then return tbl end
  return read(tbl[key], ...)
end
_A.read = read

local function eof() end
local function map(iter, ...)
  local tbl = read(...)
  if not tbl then return eof end
  return (iter or pairs)(tbl)
end
_A.map = map

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
_A.write = write

local function next(fn, ...)
  if fn and type(fn) == 'function' then
    return fn(...)
  end
  return fn, ...
end
_A.next = next

local function match(val, arg, ...)
  if val == arg then return true end
  return select("#", ...) > 0 and next(val, match, ...) or false
end
_A.match = match


do
  local root = _G.OBroBindsRootFrame
  local SUBS
  local function listen(key, fn)
    if not fn then return nil end
    for _, entry in map(ipairs, SUBS, key) do
      if fn == entry then
        return fn
      end
    end
    SUBS = write(SUBS, key, push, fn)
    if #read(SUBS, key) == 1 and strsub(key, 1, 5) ~= "ADDON" then
      --print("register", key)
      root:RegisterEvent(key)
    end
    return fn
  end
  _A.listen = listen

  local function release(key, fn)
    for index, entry in map(ipairs, SUBS, key) do
      if fn == entry then
        SUBS = write(SUBS, key, splice, index)
        break
      end
    end
    if not read(SUBS, key) and strsub(key, 1, 5) ~= "ADDON" then
      --print("remove", key)
      root:UnregisterEvent(key)
    end
  end
  _A.release = release

  do
    local Q = {}
    Q.__index = Q
    function Q:__call(...)
      if #self > 0 then
        return tremove(self, 1)(self, ...)
      end
      return ...
    end
    local pool = {}
    local function reuse(q, ...)
      for key in pairs(q) do
        q[key] = nil
      end
      tinsert(pool, q)
      return ...
    end
    function root:dispatch(key, ...)
      local subs = read(SUBS, key)
      if not subs then return end
      local q = push(tremove(pool) or setmetatable({}, Q), unpack(subs))
      q.key = key
      return reuse(q, q(self, ...))
    end
  end
end


do
  local function walk(self, fn, ...)
    if type(fn) == 'function' then
      return fn(self, ...)
    end
    return self, fn, ...
  end
  local function clean(self, ...)
    for i = #self, 1, -1 do
      self[i] = nil
    end
    return walk(self, ...)
  end

  local STACK = {}
  STACK.__index = STACK


  local function skip(self, fn, arg, ...)
    return walk(shift(self, fn, arg), ...)
  end
  local function call(fn, self, event, ...)
    shift(event, fn)
    return self, event, ...
  end
  function STACK.call(self, fn, ...)
    return call(fn, walk(shift(self, skip, self.call, fn), ...))
  end
  function STACK.init(self, fn, ...)
    return call(fn, walk(self, ...))
  end
  function STACK.both(self, fn, ...)
    return call(fn, walk(shift(self, self.both, fn), ...))
  end
  local release = _A.release
  local listen = _A.listen
  function STACK.release(self, event, fn, ...)
    release(event, fn)
    return walk(shift(self, self.listen, event, fn), ...)
  end
  function STACK.listen(self, event, fn, ...)
    listen(event, fn)
    return walk(shift(self, self.release, event, fn), ...)
  end
  do
    local function fold(key, self, event, ...)
      _A.release(event.key, self)
      if key then
        _A.listen(key, self)
        shift(self, self.fold, event.key)
      end
      return event(...)
    end
    function STACK.fold(self, key, ...)
      return fold(key, walk(self, ...))
    end
  end
  function STACK:__call(...)
    return walk(push(self, ...), clean, unpack(self))
  end
  _A.STACK = STACK
end
