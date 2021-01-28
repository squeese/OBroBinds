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
  local SUBS
  local function listen(key, fn)
    if not fn then return nil end
    for _, entry in map(ipairs, SUBS, key) do
      if fn == entry then
        return fn
      end
    end
    SUBS = write(SUBS, key, shift, fn)
    return fn
  end
  _A.listen = listen

  local function release(key, fn)
    for index, entry in map(ipairs, SUBS, key) do
      if fn == entry then
        SUBS = write(SUBS, key, splice, index)
        return
      end
    end
  end
  _A.release = release

  do
    local Q = {}
    Q.__index = Q
    function Q:next(...)
      if #self > 0 then
        self.fn = tremove(self)
        return self.fn(self, ...)
      end
      return ...
    end
    function Q:release()
      release(self.key, self.fn)
      return self
    end
    function Q:once(...)
      return self:release():next(...)
    end

    local pool = {}
    local function reuse(q, ...)
      for key in pairs(q) do
        q[key] = nil
      end
      tinsert(pool, q)
      return ...
    end
    local function dispatch(self, key, ...)
      local subs = read(SUBS, key)
      if not subs then return end
      local q = push(tremove(pool) or setmetatable({}, Q), unpack(subs))
      q.key = key
      return reuse(q, q:next(self, ...))
    end
    _A.dispatch = dispatch
  end

end

do
  local function walk(self, fn, ...)
    if type(fn) == 'function' then
      return fn(self, ...)
    end
    return self
  end
  local function clean(self, ...)
    for i = #self, 1, -1 do
      self[i] = nil
    end
    return walk(self, ...)
  end
  local STATE = {}
  STATE.__index = STATE
  function STATE.skip(self, arg1, arg2, ...)
    return walk(shift(self, arg1, arg2), ...)
  end
  function STATE.push(self, fn, ...)
    if not fn then
      return walk(self, ...)
    end
    tinsert(self:args(...), self.__numcalls, fn)
    return walk(shift(self, self.skip, self.push, fn), ...)
  end
  function STATE.call(self, fn, ...)
    fn(self:args(...))
    return walk(shift(self, self.skip, self.call, fn), ...)
  end
  function STATE.init(self, fn, ...)
    if fn then
      tinsert(self:args(...), self.__numcalls, fn)
    end
    return walk(self, ...)
  end
  function STATE.unregister(self, event, ...)
    local _, frame = self:args(...)
    frame:UnregisterEvent(event)
    return walk(shift(self, self.register, event), ...)
  end
  function STATE.register(self, event, ...)
    local _, frame = self:args(...)
    frame:RegisterEvent(event)
    return walk(shift(self, self.unregister, event), ...)
  end
  local release = _A.release
  function STATE.release(self, event, fn, ...)
    release(event, fn)
    return walk(shift(self, self.listen, event, fn), ...) end
  local listen = _A.listen
  function STATE.listen(self, event, fn, ...)
    listen(event, fn)
    return walk(shift(self, self.release, event, fn), ...)
  end
  function STATE.final(self, fn1, fn2, ...)
    return fn1(push(self, self.final, fn2, fn1), ...)
  end
  function STATE.bounce(self, key, e, ...)
    listen(key, push(self, self.arf, e.key))
    return e:once(...)
    --return fn(push(self, self.arf, fn), ...)
  end
  function STATE.toggle(self, e, ...)
    --push(push(tmp, ...), push(self, self.toggle))
    --return e:next(next(tmp, clean, unpack(tmp)))
    push(self, self.toggle)
    return e:next(...)
  end
  function STATE:__call(e, frame, ...)
    self.__numargs = 2+select("#", ...)
    self.__numcalls = #e+1
    return walk(push(self, e, frame, ...), clean, unpack(self))
  end
  function STATE:args(...)
    return select(select("#", ...)-self.__numargs+1, ...)
  end
  _A.STATE = STATE
end
