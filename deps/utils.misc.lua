local scope = select(2, ...)
local tinsert = table.insert
local tremove = table.remove
scope.empty = {}
scope.pool = {}

function scope.poolPush(tbl, ...)
  tinsert(scope.pool, setmetatable(scope.clean(tbl), nil))
  return ...
end

function scope.read(tbl, key, ...)
  if not tbl then return nil end
  if not key then return tbl end
  return scope.read(tbl[key], ...)
end

function scope.write(tbl, key, ...)
  if not tbl then
    return scope.write({}, key, ...)
  elseif type(key) == 'function' then
    tbl = key(tbl, ...)
  elseif select("#", ...) > 0 then
    tbl[key] = scope.write(tbl[key], ...)
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

function scope.dbRead(...)
  return scope.read(OBroBindsDB, ...)
end

function scope.dbWrite(...)
  OBroBindsDB = scope.write(OBroBindsDB, ...)
end

function scope.call(fn, ...)
  if fn and type(fn) == 'function' then
    return fn(...)
  end
  return fn, ...
end

function scope.next(self, fn, ...)
  if type(fn) == 'function' then
    return fn(self, ...)
  end
  return self, fn, ...
end

function scope.match(val, arg, ...)
  if val == arg then return true end
  return select("#", ...) > 0 and scope.match(val, ...) or false
end

function scope.splice(self, index, ...)
  tremove(self, index)
  return self, ...
end

function scope.shift(self, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    tinsert(self, i, arg)
  end
  return self
end

function scope.push(self, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    tinsert(self, arg)
  end
  return self
end

function scope.clean(self, ...)
  for k in next, self do
    self[k] = nil
  end
  return scope.next(self, ...)
end

function scope.enqueue(key, fn)
  if fn and not scope.match(fn, unpack(scope.read(scope, key) or scope.empty)) then
    scope.write(scope, key, scope.push, fn)
    if #scope.read(scope, key) == 1 and strsub(key, 1, 5) ~= "ADDON" then
      scope.root:RegisterEvent(key)
    end
  end
end

function scope.dequeue(key, fn)
  for index, entry in next, scope.read(scope, key) or scope.empty do
    if fn == entry then
      scope.write(scope, key, scope.splice, index)
      break
    end
  end
  if not scope.read(scope, key) and strsub(key, 1, 5) ~= "ADDON" then
    scope.root:UnregisterEvent(key)
  end
end


scope.EVENT = {}
scope.EVENT.__call = function(self, ...)
  if #self > 0 then
    return tremove(self, 1)(self, ...)
  end
  return ...
end

function scope:dispatch(key, ...)
  local subs = scope.read(scope, key)
  if not subs then return end
  local event = scope.push(setmetatable(tremove(scope.pool) or {}, scope.EVENT), unpack(subs))
  event.key = key
  return scope.poolPush(event, event(...))
end

scope.STACK = {}
scope.STACK.__index = scope.STACK
function scope.STACK:__call(...)
  return scope.next(scope.push(self, ...), scope.clean, unpack(self))
end
do
  local function fold(key, self, event, ...)
    scope.dequeue(event.key, self)
    if key then
      scope.enqueue(key, self)
      scope.shift(self, self.fold, event.key)
    end
    return event(...)
  end
  function scope.STACK.fold(self, key, ...)
    return fold(key, scope.next(self, ...))
  end
end
do
  local function skip(self, fn, arg, ...)
    return scope.next(scope.shift(self, fn, arg), ...)
  end
  local function call(fn, self, event, ...)
    scope.shift(event, fn)
    return self, event, ...
  end
  function scope.STACK.call(self, fn, ...)
    return call(fn, scope.next(scope.shift(self, skip, self.call, fn), ...))
  end
  function scope.STACK.init(self, fn, ...)
    return call(fn, scope.next(self, ...))
  end
  function scope.STACK.both(self, fn, ...)
    return call(fn, scope.next(scope.shift(self, self.both, fn), ...))
  end
end
function scope.STACK.dequeue(self, event, fn, ...)
  scope.dequeue(event, fn)
  return scope.next(scope.shift(self, self.enqueue, event, fn), ...)
end
function scope.STACK.enqueue(self, event, fn, ...)
  scope.enqueue(event, fn)
  return scope.next(scope.shift(self, self.dequeue, event, fn), ...)
end
