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
    return next(self, clean, unpack(self, 1, self.n))
  end
  function scope.LAYOUT.col(self, x, ...) 
    self.x = mmax(0, x * self.size)
    return next(self, ...)
  end
  function scope.LAYOUT.row(self, y, ...)
    self.y = mmax(0, y * self.size)
    return next(self, ...)
  end
  function scope.LAYOUT.move(self, x, y, ...)
    self.x = mmax(0, self.x+x*self.size)
    self.y = mmax(0, self.y+y*self.size)
    return next(self, ...)
  end
  function scope.LAYOUT.key(self, char, ...)
    return next(push(self, strupper(char), self.x, self.y), ...)
  end
  local strgmatch = string.gmatch
  local poolAcquire = scope.poolAcquire
  local poolRelease = scope.poolRelease
  function scope.LAYOUT.keys(self, x, y, chars, ...)
    local args = poolAcquire(nil)
    for char in strgmatch(chars, "[^ ]+") do
      push(args, self.key, char, self.move, x or 1, y or 0)
    end
    return next(self, poolRelease(push(args, ...), unpack(args)))
  end
end

------------------------------------------------------------------ ACTION
scope.ACTION = {}
scope.ACTION.kind   = 1
scope.ACTION.id     = 2
scope.ACTION.name   = 3
scope.ACTION.body   = 3
scope.ACTION.icon   = 4
scope.ACTION.lock   = 5
scope.ACTION.script = 6
scope.ACTION.spell  = "SPELL"
scope.ACTION.macro  = "MACRO"
scope.ACTION.item   = "ITEM"
scope.ACTION.blob   = "BLOB"
scope.ACTION.SPELL  = 1
scope.ACTION.MACRO  = 1
scope.ACTION.ITEM   = 1
scope.ACTION.BLOB   = 1

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
    scope.CLASS = select(2, UnitClass("player"))
    scope.SPECC = GetSpecialization()
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
  scope.dbWriteAction = dbWriteAction

  function scope.GetAction(binding)
    return setmetatable(dbReadAction(binding) or NIL, ACTION)
  end

  do
    local function iter(...)
      local k, v = next(...)
      return k, setmetatable(v or NIL, ACTION)
    end
    function scope.GetActions()
      return iter, dbReadAction() or NIL
    end
  end

  local dispatch = scope.dispatch
  local bindingModifiers = scope.bindingModifiers
  function scope.DeleteAction(binding)
    if dbWriteAction(binding, nil) then
      dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
      return true
    end
  end

  do
    local function deleteAction(binding, kind)
      local action = scope.GetAction(binding)
      if action ~= NIL and action.kind ~= kind then
        return scope.DeleteAction(binding)
      end
    end

    function scope.UpdateActionSpell(binding, id, name, icon)
      deleteAction(binding, ACTION.spell)
      if scope.match(true,
        dbWriteAction(binding, ACTION.kind, ACTION.spell),
        dbWriteAction(binding, ACTION.id,   id),
        dbWriteAction(binding, ACTION.name, name),
        dbWriteAction(binding, ACTION.icon, icon or 134400)) then
        dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
        return true
      end
    end

    function scope.UpdateActionItem(binding, id, name, icon)
      deleteAction(binding, ACTION.item)
      if scope.match(true,
        dbWriteAction(binding, ACTION.kind, ACTION.item),
        dbWriteAction(binding, ACTION.id,   id),
        dbWriteAction(binding, ACTION.name, name),
        dbWriteAction(binding, ACTION.icon, icon or 134400)) then
        dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
        return true
      end
    end

    function scope.UpdateActionMacro(binding, id, name, icon)
      deleteAction(binding, ACTION.macro)
      if scope.match(true,
        dbWriteAction(binding, ACTION.kind, ACTION.macro),
        dbWriteAction(binding, ACTION.id,   id),
        dbWriteAction(binding, ACTION.name, name),
        dbWriteAction(binding, ACTION.icon, icon or 134400)) then
        dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
        return true
      end
    end

    function scope.UpdateActionBlob(binding, id, body, icon)
      deleteAction(binding, ACTION.blob)
      if scope.match(true,
        dbWriteAction(binding, ACTION.kind, ACTION.blob),
        dbWriteAction(binding, ACTION.id,   id),
        dbWriteAction(binding, ACTION.body, body),
        dbWriteAction(binding, ACTION.icon, icon or 134400)) then
        dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
        return true
      end
    end

    --function scropt.UpdateActiobBlobIcon(binding, )

    function scope.UpdateAction(binding, kind, ...)
      if kind == ACTION.spell then
        return scope.UpdateActionSpell(binding, ...)
      elseif kind == ACTION.item then
        return scope.UpdateActionItem(binding, ...)
      elseif kind == ACTION.macro then
        return scope.UpdateActionMacro(binding, ...)
      elseif kind == ACTION.blob then
        return scope.UpdateActionBlob(binding, ...)
      end
    end
  end

  function scope.UpdateActionLock(binding)
    local value = not dbReadAction(binding, ACTION.lock) and true or nil
    if dbWriteAction(binding, ACTION.lock, value) then
      dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
      return true
    end
  end

  function scope.ActionIcon(action)
    if action.spell then
      return select(3, GetSpellInfo(action.id)) or action.icon 
    elseif action.macro then
      return select(2, GetMacroInfo(action.name)) or action.icon
    elseif action.item then
      return select(10, GetItemInfo(action.id or 0)) or action.icon
    elseif action.blob then
      return action.icon or 441148
    end
    return action.icon or nil
  end

  do
    local function cleanup(e, ...)
      scope.__pickup = nil
      scope.dequeue("CURSOR_UPDATE", cleanup)
      return e(...)
    end
    function scope.PickupAction(binding)
      if scope.PORTAL_BUTTONS[binding] then
        PickupAction(scope.PORTAL_BUTTONS[binding] + scope.STANCE_OFFSET - 1)
        return true
      end
      local action = scope.GetAction(binding)
      if action.lock then
        return false
      elseif action.spell then
        PickupSpell(action.id)
        if not GetCursorInfo() then
          local macro = CreateMacro("__OBRO_TMP", scope.ActionIcon(action))
          PickupMacro(macro)
          DeleteMacro(macro)
          scope.__pickup = action
          scope.enqueue("CURSOR_UPDATE", cleanup)
        end
      elseif action.macro then
        PickupMacro(action.name)
      elseif action.item then
        PickupItem(action.id)
      elseif action.blob then
        local macro = CreateMacro("__OBRO_TMP", scope.ActionIcon(action))
        PickupMacro(macro)
        DeleteMacro(macro)
        scope.enqueue("CURSOR_UPDATE", cleanup)
        scope.__pickup = {unpack(action, 1, 6)}
      elseif action.kind then
        assert(false, "Unhandled pickup: "..action.kind)
      end
      return scope.DeleteAction(binding)
    end
  end

  function scope.ReceiveAction(binding)
    if scope.PORTAL_BUTTONS[binding] then
      PlaceAction(scope.PORTAL_BUTTONS[binding] + scope.STANCE_OFFSET - 1)
      return true
    elseif scope.GetAction(binding).locked then
      return false
    end
    local kind, id, link, arg1, arg2 = GetCursorInfo()
    if kind == "spell" then
      ClearCursor()
      local id = arg2 or arg1
      local name, _, icon = GetSpellInfo(id)
      assert(id ~= nil)
      assert(name ~= nil)
      assert(icon ~= nil)
      return scope.match(true,
        scope.PickupAction(binding),
        scope.UpdateActionSpell(binding, id, name, icon))

    elseif kind == "item" then
      ClearCursor()
      local name = select(3, string.match(link, "^|c%x+|H(%a+):(%d+).+|h%[([^%]]+)"))
      local icon = select(10, GetItemInfo(id))
      assert(link ~= nil)
      assert(name ~= nil)
      assert(icon ~= nil)
      return scope.match(true,
        scope.PickupAction(binding),
        scope.UpdateActionItem(binding, id, name, icon))

    elseif kind == "macro" and id == 0 then
      local action = scope.__pickup
      ClearCursor()
      assert(scope.__pickup == nil)
      if scope.match(true, scope.PickupAction(binding), scope.dbWriteAction(binding, action)) then
        dispatch(scope, "ADDON_ACTION_UPDATED", binding, scope.bindingModifiers(binding))
        return true
      end

    elseif kind == "macro" then
      ClearCursor()
      local name, icon = GetMacroInfo(id)
      assert(type(id) == "number")
      assert(id ~= nil)
      assert(name ~= nil)
      assert(icon ~= nil)
      return scope.match(true,
        scope.PickupAction(binding),
        scope.UpdateActionMacro(binding, id, name, icon))

    elseif kind then
      assert(false, "Unhandled receive: "..kind)
    end
  end

  function scope.PromoteToAction(binding)
    local kind, name = string.match(GetBindingAction(binding, false), "^(%w+) (.*)$")
    if kind == 'SPELL' then
      local icon, _, _, _, id = select(3, GetSpellInfo(name))
      assert(name ~= nil)
      return scope.UpdateActionSpell(binding, id, name, icon or 134400)
    elseif kind == 'MACRO' then
      local id = GetMacroIndexByName(name)
      local icon = select(2, GetMacroInfo(name))
      assert(name ~= nil)
      return scope.UpdateActionMacro(binding, id, name, icon or 134400)
    elseif kind == 'ITEM' then
      local link, _, _, _, _, _, _, _, icon = select(2, GetItemInfo(name))
      local id = link and select(4, string.find(link, "^|c%x+|H(%a+):(%d+)[|:]"))
      assert(name ~= nil)
      return scope.UpdateActionItem(binding, id, name, icon or 134400)
    end
  end

  function scope.PromoteToMacroBlob(binding)
    local _, name = string.match(GetBindingAction(binding, false), "^(%w+) (.*)$")
    local _, icon, body = GetMacroInfo(name)
    if icon and body then
      return scope.UpdateActionBlob(binding, name, body, icon)
    else
      print("Macro", name, "not found")
    end
  end
end
