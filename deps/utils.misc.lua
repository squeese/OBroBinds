local scope = select(2, ...)
local tinsert = table.insert
local tremove = table.remove
local tunpack = unpack or table.unpack
scope.NIL = {}

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

function scope.push(self, ...)
  local l, n = select("#", ...)
  if self.n then
    n, self.n = self.n, self.n + l
  else
    n = #self
  end
  for i = 1, l do
    self[n+i] = select(i, ...)
  end
  return self
end

function scope.shift(self, ...)
  local l, n = select("#", ...)
  if self.n then
    n, self.n = self.n, self.n + l
  else
    n = #self
  end
  for i = n+l, 1, -1 do
    self[i] = self[i-l]
  end
  for i = l, 1, -1 do
    self[i] = select(i, ...)
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

---------------------------------------------------------------- DB READ/WRITE
do
  local function read(src, key, ...)
    if not src then return nil end
    if not key then return src end
    if type(key) == 'function' then
      return key(src, ...)
    end
    return read(src[key], ...)
  end
  scope.read = read
end

do
  local poolRelease = scope.poolRelease
  local function cleanup(tbl)
    for key, val in pairs(tbl) do
      if type(val) == 'table' then
        cleanup(val)
      end
      tbl[key] = nil
    end
    return poolRelease(tbl, nil)
  end

  local poolAcquire, next = scope.poolAcquire, scope.next
  local function write(src, key, ...)
    if type(key) == 'function' then
      local old = src or poolAcquire(nil)
      local new = next(old, key, ...)
      local diff = src ~= new
      if old ~= new and type(old) == 'table' then
        cleanup(old)
      end
      if type(new) == 'table' then
        for _ in pairs(new) do
          return new, diff
        end
        return cleanup(new), diff
      end
      return new, diff
    elseif select("#", ...) == 0 then
      if src and type(src) == 'table' then
        cleanup(src)
      end
      return key
    end
    local old = type(src) == 'table' and src[key] or nil
    local new, diff = write(type(old) == "table" and old or nil, ...)
    diff = diff or old ~= new
    if not src then
      if new then
        src = poolAcquire(nil)
        diff = true
        src[key] = new
      end
      return src, diff
    end
    src[key] = new
    for _ in pairs(src) do
      return src, diff
    end
    return poolRelease(src, nil), diff
  end
  scope.write = write
end

---------------------------------------------------------------- CHAIN
scope.CHAIN = {}
function scope.CHAIN:__call(...)
  if #self > 0 then
    return tremove(self, 1)(self, ...)
  end
  return self, ...
end

---------------------------------------------------------------- enqueue, dequeue, dispatch
do
  local strsub, NIL = strsub or string.sub, scope.NIL
  local match, read, write, push = scope.match, scope.read, scope.write, scope.push
  function scope.enqueue(key, fn)
    if fn and not match(fn, tunpack(read(scope, key) or NIL)) then
      write(scope, key, push, fn)
      if #read(scope, key) == 1 and strsub(key, 1, 5) ~= "ADDON" then
        scope.ROOT:RegisterEvent(key)
      end
    end
    return fn
  end
end

do
  local strsub = strsub or string.sub
  local read, write, splice = scope.read, scope.write, scope.splice
  function scope.dequeue(key, fn)
    local subs = read(scope, key)
    if fn and subs then
      for index, entry in next, subs do
        if fn == entry then
          write(scope, key, splice, index)
          break
        end
      end
      if not read(scope, key) and strsub(key, 1, 5) ~= "ADDON" then
        scope.ROOT:UnregisterEvent(key)
      end
    end
  end
end

do
  local read, push, CHAIN = scope.read, scope.push, scope.CHAIN
  local poolAcquire, poolRelease = scope.poolAcquire, scope.poolRelease
  function scope:dispatch(key, ...)
    local subs = read(scope, key)
    if subs then
      local chain = push(poolAcquire(CHAIN), tunpack(subs))
      return poolRelease(chain(key, ...))
    end
    return key, ...
  end
end

------------------------------------------------------------------ STACK
scope.STACK = {}
scope.STACK.__index = scope.STACK
scope.STACK.n = 0
do
  local next, push, clean = scope.next, scope.push, scope. clean
  function scope.STACK:__call(chain, ...)
    return select(2, next(push(self, chain, ...), clean, tunpack(self)))(...)
  end
end
do
  local shift = scope.shift
  local function call(fn, self, chain, ...)
    return self, shift(chain, fn), ...
  end
  local next = scope.next
  function scope.STACK.once(self, fn, ...)
    return call(fn, next(self, ...))
  end
  local function skip(self, fn, arg, ...)
    return next(shift(self, fn, arg), ...)
  end
  function scope.STACK.setup(self, fn, ...)
    return call(fn, next(shift(self, skip, self.setup, fn), ...))
  end
  function scope.STACK.clear(self, fn, ...)
    return next(shift(self, self.setup, fn), ...)
  end
  function scope.STACK.both(self, fn, ...)
    return call(fn, next(shift(self, self.both, fn), ...))
  end
  local dequeue, enqueue = scope.dequeue, scope.enqueue
  function scope.STACK.dequeue(self, event, fn, ...)
    dequeue(event, fn)
    return next(shift(self, self.enqueue, event, fn), ...)
  end
  function scope.STACK.enqueue(self, event, fn, ...)
    enqueue(event, fn)
    return next(shift(self, self.dequeue, event, fn), ...)
  end
  local function fold(self, chain, event, ...)
    dequeue(event, self)
    return shift(self, self.fold, event), chain, event, ...
  end
  function scope.STACK.fold(self, event, ...)
    if event then
      enqueue(event, self)
    end
    return fold(next(self, ...))
  end
  do
    local mt = {}
    function mt:__call(next, ...)
      scope.next(SafeUnpack(self))
      return next(...)
    end
    function scope.STACK.apply(...)
      return setmetatable(SafePack(...), mt)
    end
  end
end

do
  local strmatch, pattern = string.match, "^(.--?)([^-]*.)$"
  function scope.bindingModifiers(binding)
    return strmatch(binding, pattern)
  end
end

------------------------------------------------------------------ LAYOUT
scope.LAYOUT = { x = 0, y = 0, size = 40, n = 0 }
scope.LAYOUT.__index = scope.LAYOUT
do
  local mmax = math.max
  local next, push, clean = scope.next, scope.push, scope.clean
  function scope.LAYOUT.__call(self, ...)
    print("?", self.n)
    return next(self, clean, unpack(self, 1, self.n))
  end
  function scope.LAYOUT.col(self, x, ...) 
    print("col", self)
    self.x = mmax(0, x * self.size)
    return next(self, ...)
  end
  function scope.LAYOUT.row(self, y, ...)
    print("row", self)
    self.y = mmax(0, y * self.size)
    return next(self, ...)
  end
  function scope.LAYOUT.move(self, x, y, ...)
    print("move")
    self.x = mmax(0, self.x+x*self.size)
    self.y = mmax(0, self.y+y*self.size)
    return next(self, ...)
  end
  function scope.LAYOUT.key(self, char, ...)
    print("key")
    return next(push(self, strupper(char), self.x, self.y), ...)
  end
  local strgmatch = string.gmatch
  local poolAcquire = scope.poolAcquire
  local poolRelease = scope.poolRelease
  function scope.LAYOUT.keys(self, x, y, chars, ...)
    print("keys")
    local args = poolAcquire(nil)
    for char in strgmatch(chars, "[^ ]+") do
      push(args, self.key, char, self.move, x or 1, y or 0)
    end
    return next(self, poolRelease(push(args, ...), unpack(args)))
  end
end

------------------------------------------------------------------ ACTION
scope.ACTION = {}
scope.ACTION.kind  = 1
scope.ACTION.id    = 2
scope.ACTION.name  = 3
scope.ACTION.body  = 3
scope.ACTION.icon  = 4
scope.ACTION.lock  = 5
scope.ACTION.spell = "SPELL"
scope.ACTION.macro = "MACRO"
scope.ACTION.item  = "ITEM"
scope.ACTION.blob  = "BLOB"
scope.ACTION.SPELL = 1
scope.ACTION.MACRO = 1
scope.ACTION.ITEM  = 1
scope.ACTION.BLOB  = 1

do
  local NIL, ACTION = scope.NIL, scope.ACTION
  function ACTION:__index(key)
    if self == NIL then return end
    local index = ACTION[key]
    if type(index) ~= 'number' then
      return rawget(self, ACTION[index]) == index
    else
      return rawget(self, index)
    end
  end

  --setmetatable(ACTION, ACTION)
  --local action = setmetatable({ "SPELL" }, ACTION)
  --print("ACTION.spell", ACTION.spell)
  --print("ACTION.kind", ACTION.kind)
  --print("action.spell", action.spell)
  --print("action.kind", action.kind)
  --local t = setmetatable(NIL, ACTION)
  --print(t.spell)

  local read = scope.read
  local function dbRead(...)
    return read(OBroBindsDB, ...)
  end
  scope.dbRead = dbRead

  local write = scope.write
  local function dbWrite(...)
    local changed
    OBroBindsDB, changed = write(OBroBindsDB, ...)
    return changed
  end
  scope.dbWrite = dbWrite

  local CLASS, SPECC = nil, nil
  function scope.UpdatePlayerVariables(next, ...)
    write(scope, "CLASS", select(2, UnitClass("player")))
    write(scope, "SPECC", GetSpecialization())
    CLASS, SPECC = scope.CLASS, scope.SPECC
    return next(...)
  end

  local function dbReadAction(...)
    return read(OBroBindsDB, CLASS, SPECC, ...)
  end

  local function dbWriteAction(...)
    local changed
    OBroBindsDB, changed = write(OBroBindsDB, CLASS, SPECC, ...)
    return changed
  end

  function scope.GetAction(binding)
    return setmetatable(dbReadAction(binding) or NIL, ACTION)
  end

  local dispatch = scope.dispatch
  local bindingModifiers = scope.bindingModifiers
  function scope.DeleteAction(binding)
    if dbWriteAction(binding, nil) then
      dispatch(scope, "ADDON_ACTION_UPDATED", bindingModifiers(binding))
    end
  end

  do
    local function deleteAction(binding, kind)
      local action = scope.GetAction(binding)
      if action ~= NIL and action.kind ~= kind then
        scope.DeleteAction(binding)
      end
    end

    function scope.UpdateActionSpell(binding, id, name, icon)
      deleteAction(binding, ACTION.spell)
      if dbWriteAction(binding, ACTION.kind, ACTION.spell)
        or dbWriteAction(binding, ACTION.id,   id)
        or dbWriteAction(binding, ACTION.name, name)
        or dbWriteAction(binding, ACTION.icon, icon or 134400) then
        dispatch(scope, "ADDON_ACTION_UPDATED", bindingModifiers(binding))
      end
    end

    function scope.UpdateActionItem(binding, id, name, icon)
      deleteAction(binding, ACTION.item)
      if dbWriteAction(binding, ACTION.kind, ACTION.item)
        or dbWriteAction(binding, ACTION.id,   id)
        or dbWriteAction(binding, ACTION.name, name)
        or dbWriteAction(binding, ACTION.icon, icon or 134400) then
        dispatch(scope, "ADDON_ACTION_UPDATED", bindingModifiers(binding))
      end
    end

    function scope.UpdateActionMacro(binding, id, name, icon)
      deleteAction(binding, ACTION.macro)
      if dbWriteAction(binding, ACTION.kind, ACTION.macro)
        or dbWriteAction(binding, ACTION.id,   id)
        or dbWriteAction(binding, ACTION.name, name)
        or dbWriteAction(binding, ACTION.icon, icon or 134400) then
        dispatch(scope, "ADDON_ACTION_UPDATED", bindingModifiers(binding))
      end
    end
  end

  function scope.UpdateActionLock(binding)
    local value = not dbReadAction(binding, ACTION.lock) and true or nil
    if dbWriteAction(binding, ACTION.lock, value) then
      dispatch(scope, "ADDON_ACTION_UPDATED", bindingModifiers(binding))
    end
  end
end
