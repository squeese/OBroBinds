local scope = select(2, ...)
local tinsert = table.insert
local tremove = table.remove
local unpack = table.unpack

scope.empty = {}

function scope.next(self, fn, ...)
  if type(fn) == 'function' then
    return fn(self, ...)
  end
  return self, fn, ...
end

do
  local function match(val, arg, ...)
    if val == arg then return true end
    return select("#", ...) > 0 and match(val, ...) or false
  end
  scope.match = match
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

do
  local next = scope.next
  function scope.clean(self, ...)
    for k in pairs(self) do
      self[k] = nil
    end
    return next(self, ...)
  end
end

---------------------------------------------------------------- POOL
do
  local pool, push, clean = {}, scope.push, scope.clean
  scope.pool = pool
  function scope.poolAcquire(mt, ...)
    return push(setmetatable(tremove(pool) or {}, mt), ...)
  end
  function scope.poolRelease(tbl, ...)
    tinsert(pool, setmetatable(clean(tbl), nil))
    return ...
  end
end

---------------------------------------------------------------- CHAIN
scope.CHAIN = {}
function scope.CHAIN:__call(...)
  if #self > 0 then
    return tremove(self, 1)(self, ...)
  end
  return ...
end

---------------------------------------------------------------- DB READ/WRITE
do
  local function read(tbl, key, ...)
    if not tbl then return nil end
    if not key then return tbl end
    if type(key) == 'function' then
      return key(tbl, ...)
    end
    return read(tbl[key], ...)
  end
  scope.read = read
end

do
  local function write(tbl, key, ...)
    if not tbl then
      print("#1", tbl, key)
      return write({}, key, ...)
    elseif type(key) == 'function' then
      tbl = key(tbl, ...)
    elseif select("#", ...) > 0 then
      print("#2", tbl, key)
      tbl[key] = write(tbl[key], ...)
    else
      print("#3", key)
      return key
    end
    if type(tbl) ~= 'table' then
      print("#4", tbl, key)
      return tbl
    end
    for _ in pairs(tbl) do
      return tbl
    end
    return nil
  end
  scope.write = write



  local poolRelease = scope.poolRelease
  local poolAcquire, next = scope.poolAcquire, scope.next

  local function cleanup(tbl)
    if type(tbl) ~= 'table' then return end
    for key, val in pairs(tbl) do
      tbl[key] = cleanup(val)
    end
    return poolRelease(tbl, nil)
  end

  local function write3(src, arg, ...)
    if type(arg) == 'function' then
      local old = src or poolAcquire(nil)
      local new = next(old, arg, ...)
      if old ~= new then
        cleanup(old)
      end
      if type(new) == 'table' then
        for _ in pairs(new) do
          return new
        end
        return cleanup(new)
      end
      return new
    elseif select("#", ...) == 0 then
      cleanup(src)
      return arg
    end
    local old = type(src) == 'table' and src[arg] or nil
    local new = write3(type(old) == "table" and old or nil, ...)
    if not src then
      if new then
        src = poolAcquire(nil)
        src[arg] = new
      end
      return src
    end
    src[arg] = new
    for _ in pairs(src) do
      return src
    end
    return poolRelease(src, nil)
  end
  scope.write3 = write3
end

--function scope.dbRead(...)
  --return scope.read(OBroBindsDB, ...)
--end

--function scope.dbWrite(...)
  --OBroBindsDB = scope.write(OBroBindsDB, ...)
--end

---------------------------------------------------------------- enqueue, dequeue, dispatch
--function scope.enqueue(key, fn)
  --if fn and not scope.match(fn, unpack(scope.read(scope, key) or scope.empty)) then
    --scope.write(scope, key, scope.push, fn)
    --if #scope.read(scope, key) == 1 and strsub(key, 1, 5) ~= "ADDON" then
      --scope.root:RegisterEvent(key)
    --end
  --end
--end

--function scope.dequeue(key, fn)
  --for index, entry in next, scope.read(scope, key) or scope.empty do
    --if fn == entry then
      --scope.write(scope, key, scope.splice, index)
      --break
    --end
  --end
  --if not scope.read(scope, key) and strsub(key, 1, 5) ~= "ADDON" then
    --scope.root:UnregisterEvent(key)
  --end
--end

--function scope:dispatch(key, ...)
  --local subs = scope.read(scope, key)
  --if not subs then return end
  --local chain = scope.poolAcquire(scope.CHAIN, unpack(subs))
  --return scope.poolRelease(chain, chain(key, ...))
--end

------------------------------------------------------------------ STACK
--scope.STACK = {}
--scope.STACK.__index = STACK
--function scope.STACK:__call(...)
  --return scope.next(scope.push(self, ...), scope.clean, unpack(self))
--end

--do
  --local function fold(key, self, event, ...)
    --scope.dequeue(event.key, self)
    --if key then
      --scope.enqueue(key, self)
      --scope.shift(self, self.fold, event.key)
    --end
    --return event(...)
  --end
  --function scope.STACK.fold(self, key, ...)
    --return fold(key, scope.next(self, ...))
  --end
--end
--do
  --local function skip(self, fn, arg, ...)
    --return scope.next(scope.shift(self, fn, arg), ...)
  --end
  --local function call(fn, self, event, ...)
    --scope.shift(event, fn)
    --return self, event, ...
  --end
  --function scope.STACK.once(self, fn, ...)
    --return call(fn, scope.next(self, ...))
  --end
  --function scope.STACK.setup(self, fn, ...)
    --return call(fn, scope.next(scope.shift(self, skip, self.call, fn), ...))
  --end
  --function scope.STACK.clean(self, fn, ...)
    --return scope.next(scope.shift(self, self.call, fn), ...)
  --end
  --function scope.STACK.both(self, fn, ...)
    --return call(fn, scope.next(scope.shift(self, self.both, fn), ...))
  --end
--end
--function scope.STACK.dequeue(self, event, fn, ...)
  --scope.dequeue(event, fn)
  --return scope.next(scope.shift(self, self.enqueue, event, fn), ...)
--end
--function scope.STACK.enqueue(self, event, fn, ...)
  --scope.enqueue(event, fn)
  --return scope.next(scope.shift(self, self.dequeue, event, fn), ...)
--end

----do
  ----local mt = {}
  ----function mt:__call(e, ...)
    ----scope.next(SafeUnpack(self))
    ----return e(...)
  ----end
  ----function scope.STACK.apply(...)
    ----return setmetatable(SafePack(...), mt)
  ----end
----end
