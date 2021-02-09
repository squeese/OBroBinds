local inspect = require("./inspect")
local unpack = table.unpack

--[[G
local function import(file, ...)
  local fp = io.open(file, "r")
  local body = fp:read("*a")
  fp:close()
  local fn, err = load(body)
  if err then
    print("error", err)
    os.exit()
  end
  return fn(...)
end

local scope = {}
import("./utils.misc.lua", nil, scope)

local function keys(tbl)
  local arr = {}
  for key in next, tbl do
    table.insert(arr, key)
  end
  return arr
end

local function run(msg, fn)
  local index = 0
  local function assert(result, msg2)
      index = index + 1
      if not result then
      --local level = 1
      --while true do
        --local info = debug.getinfo(level, "Sl")
        --if not info then break end
        --if info.what ~= "C" then
          --print(info, level, info.source, info.currentline)
        --end
        --level = level + 1
      --end
      local info = debug.getinfo(2, "Sl")
      print("[xx]", msg, index, info.currentline)
      os.exit()
    end
  end
  local ok, err = pcall(fn, assert)
  if not ok then
    print(err)
  end
end

local compare
do
  local function walk(a, b)
    local at, bt = type(a), type(b)
    if at ~= bt then return false end
    if at == 'table' then
      if #a ~= #b then return false end
      local keys = {}
      for k in pairs(a) do
        keys[k] = true
      end
      for k in pairs(b) do
        if not keys[k] then return false end
        keys[k] = nil
      end
      for _ in pairs(keys) do
        return false
      end
      for k in pairs(a) do
        if not walk(a[k], b[k]) then
          return false
        end
      end
      return true
    end
    if a ~= b then
      return false
    end
    return true
  end
  function compare(a, b)
    if not walk(a, b) then
      --print(inspect(a))
      --print(inspect(b))
      return false
    end
    return true
  end
end

run("#1 write", function(assert)
  local t = nil 
  scope.clean(scope.pool)

  t = scope.write(t, "PRIEST", true)
  assert(t.PRIEST == true)
  assert(compare(t, { PRIEST = true }))

  t = scope.write(t, "PRIEST", 1, "F1", 1, "SPELL")
  assert(compare(t, { PRIEST = { { F1 = { "SPELL" }}}}))

  t = scope.write(t, "PRIEST", 1, "F1", 2, "ID")
  assert(compare(t, { PRIEST = { { F1 = { "SPELL", "ID" }}}}))

  t = scope.write(t, "PRIEST", 1, "F1", 1, nil)
  t = scope.write(t, "PRIEST", 1, "F1", 2, "DI")
  assert(compare(t, { PRIEST = { { F1 = { nil, "DI" }}}}))

  t = scope.write(t, "PRIEST", 1, "F1", 2, nil)
  assert(t == nil)
  assert(#scope.pool == 4)
end)

run("#2 write", function(assert)
  local t = nil
  scope.clean(scope.pool)

  t = scope.write(t, "PRIEST", 1, "F1", 1, "SPELL")
  t = scope.write(t, "PRIEST", 1, "F1", 2, "ID")
  assert(compare(t, { PRIEST = { { F1 = { "SPELL", "ID" }}}}))

  t = scope.write(t, nil)
  assert(#scope.pool == 4)

  local copies = {table.unpack(scope.pool)}
  t = scope.write(t, "PRIEST", 1, "F1", 1, "SPELL")
  t = scope.write(t, "PRIEST", 1, "F1", 2, "ID")

  assert(#scope.pool == 0)
  assert(scope.match(t, table.unpack(copies)))
  assert(scope.match(t.PRIEST, table.unpack(copies)))
  assert(scope.match(t.PRIEST[1], table.unpack(copies)))
  assert(scope.match(t.PRIEST[1].F1, table.unpack(copies)))

  t = scope.write(t, nil)
  assert(t == nil)
  assert(#scope.pool == 4)
end)

run("#3 write", function(assert)
  scope.clean(scope.pool)
  t = nil
  t = scope.write(t, "GUI", "open", true)
  t = scope.write(t, "GUI", "open", "replace", true)
  assert(t.GUI.open.replace == true)
end)

run("#4 write", function(assert)
  scope.clean(scope.pool)
  t = scope.write(nil, scope.push, 1, nil, 3)
  assert(#scope.pool == 0)
  assert(compare(t, { 1, [3] = 3 }))
end)

run("#5 write", function(assert)
  scope.clean(scope.pool)
  t = scope.write(nil, "one", "two", scope.push, 1, 2, 3)
  assert(#scope.pool == 0, "nt")
  assert(#t.one.two == 3, "nt")
  assert(t.one.two[1] == 1, "nt")
  assert(t.one.two[2] == 2, "nt")
  assert(t.one.two[3] == 3, "nt")
  assert(compare(t, { one = { two = { 1, 2, 3 }}}))
end)

run("#6 write", function(assert)
  local tbl
  local function nilfn(a, b, c)
    tbl = a
    return nil
  end
  scope.clean(scope.pool)
  t = scope.write(nil, "one", "two", nilfn, 1, 2, 3)
  assert(#scope.pool == 1)
  assert(tbl == scope.pool[1])
  assert(compare(t, nil))

  t = scope.write(t, "one", "two", nilfn)
  assert(#scope.pool == 1)
  assert(tbl == scope.pool[1])
  assert(compare(t, nil))
end)

run("#7 write", function(assert)
  local function ident(tbl, ...)
    scope.push(tbl, ...)
    return tbl
  end
  scope.clean(scope.pool)
  t = scope.write(nil, "one", "two", ident, 1, 2, 3)
  assert(compare(t, { one = { two = { 1, 2, 3 }}}))

  local function ident2(tbl, ...)
    scope.push(tbl, "ok")
    return tbl
  end
  t = scope.write(t, "one", "two", ident2)
  assert(compare(t, { one = { two = { 1, 2, 3, "ok" }}}))

  for i = 1, 10 do
    t = scope.write(t, "one", "two", scope.push, 1, 2, 3)
    t = scope.write(t, "one", nil)
    assert(compare(t, nil))
    assert(#scope.pool == 3)
  end

  t = scope.write(t, "one", "two", 4)
  t = scope.write(t, nil)
  assert(compare(t, nil))
  assert(#scope.pool == 3)
end)

run("#8 enqueue/dequeue", function(assert)
  scope.clean(scope.pool)
  scope.root = {}
  local native = {}
  function scope.root:RegisterEvent(key)
    assert(native[key] == nil)
    native[key] = true
  end
  function scope.root:UnregisterEvent(key)
    assert(native[key] ~= nil)
    native[key] = nil
  end

  local UpdateTooltip                = function() end
  local RefreshTooltip               = function() end
  local UpdateDropdown               = function() end
  local UpdateUnknownSpells          = function() end
  local UpdateKeyboardLayout         = function() end
  local UpdateAllKeyboardButtons     = function() end
  local UpdateKeyboardMainbarSlots   = function() end
  local UpdateKeyboardStanceButtons  = function() end
  local UpdateKeyboardMainbarIndices = function() end
  local UpdateKeyboardMainbarOffsets = function() end

  scope.enqueue("ADDON_SHOW_TOOLTIP",             UpdateTooltip)
  scope.enqueue("ADDON_SHOW_DROPDOWN",            UpdateDropdown)
  scope.enqueue("ADDON_UPDATE_LAYOUT",            UpdateKeyboardLayout)
  scope.enqueue("ADDON_OFFSET_CHANGED",           UpdateKeyboardStanceButtons)
  scope.enqueue("ADDON_OFFSET_CHANGED",           UpdateKeyboardMainbarOffsets)
  scope.enqueue("ADDON_OFFSET_CHANGED",           RefreshTooltip)
  scope.enqueue("ADDON_MODIFIER_CHANGED",         UpdateAllKeyboardButtons)
  scope.enqueue("ADDON_MODIFIER_CHANGED",         RefreshTooltip)
  scope.enqueue("UPDATE_MACROS",                  UpdateAllKeyboardButtons)
  scope.enqueue("UPDATE_BINDINGS",                UpdateKeyboardMainbarIndices)
  scope.enqueue("UPDATE_BINDINGS",                RefreshTooltip)
  scope.enqueue("PLAYER_TALENT_UPDATE",           RefreshTooltip)
  scope.enqueue("PLAYER_TALENT_UPDATE",           UpdateUnknownSpells)
  scope.enqueue("PLAYER_TALENT_UPDATE",           UpdateAllKeyboardButtons)
  scope.enqueue("ACTIONBAR_SLOT_CHANGED",         UpdateKeyboardMainbarSlots)
  scope.enqueue("PLAYER_SPECIALIZATION_CHANGED",  UpdateKeyboardStanceButtons)
  scope.enqueue("PLAYER_SPECIALIZATION_CHANGED",  UpdateAllKeyboardButtons)
  scope.enqueue("PLAYER_SPECIALIZATION_CHANGED",  RefreshTooltip)
  scope.enqueue("PLAYER_SPECIALIZATION_CHANGED",  UpdateUnknownSpells)

  assert(#scope.ADDON_SHOW_TOOLTIP == 1)
  assert(#scope.ADDON_SHOW_DROPDOWN == 1)
  assert(#scope.ADDON_UPDATE_LAYOUT == 1)
  assert(#scope.ADDON_OFFSET_CHANGED == 3)
  assert(#scope.ADDON_MODIFIER_CHANGED == 2)
  assert(#scope.UPDATE_MACROS == 1)
  assert(#scope.UPDATE_BINDINGS == 2)
  assert(#scope.PLAYER_TALENT_UPDATE == 3)
  assert(#scope.ACTIONBAR_SLOT_CHANGED == 1)
  assert(#scope.PLAYER_SPECIALIZATION_CHANGED == 4)

  assert(compare(scope.ADDON_SHOW_TOOLTIP,            { UpdateTooltip }))
  assert(compare(scope.ADDON_SHOW_DROPDOWN,           { UpdateDropdown }))
  assert(compare(scope.ADDON_UPDATE_LAYOUT,           { UpdateKeyboardLayout }))
  assert(compare(scope.ADDON_OFFSET_CHANGED,          { UpdateKeyboardStanceButtons, UpdateKeyboardMainbarOffsets, RefreshTooltip }))
  assert(compare(scope.ADDON_MODIFIER_CHANGED,        { UpdateAllKeyboardButtons, RefreshTooltip }))
  assert(compare(scope.UPDATE_MACROS,                 { UpdateAllKeyboardButtons }))
  assert(compare(scope.UPDATE_BINDINGS,               { UpdateKeyboardMainbarIndices, RefreshTooltip }))
  assert(compare(scope.PLAYER_TALENT_UPDATE,          { RefreshTooltip, UpdateUnknownSpells, UpdateAllKeyboardButtons }))
  assert(compare(scope.ACTIONBAR_SLOT_CHANGED,        { UpdateKeyboardMainbarSlots }))
  assert(compare(scope.PLAYER_SPECIALIZATION_CHANGED, { UpdateKeyboardStanceButtons, UpdateAllKeyboardButtons, RefreshTooltip, UpdateUnknownSpells }))

  scope.enqueue("PLAYER_TALENT_UPDATE",           RefreshTooltip)
  scope.enqueue("PLAYER_TALENT_UPDATE",           UpdateAllKeyboardButtons)
  scope.enqueue("PLAYER_TALENT_UPDATE",           UpdateUnknownSpells)
  assert(compare(scope.PLAYER_TALENT_UPDATE,      { RefreshTooltip, UpdateUnknownSpells, UpdateAllKeyboardButtons }))
  assert(#scope.PLAYER_TALENT_UPDATE == 3)

  scope.dequeue("ADDON_OFFSET_CHANGED",           UpdateKeyboardMainbarOffsets)
  assert(compare(scope.ADDON_OFFSET_CHANGED,      { UpdateKeyboardStanceButtons, RefreshTooltip }))

  scope.dequeue("ADDON_OFFSET_CHANGED",           nil)
  scope.dequeue("ADDON_OFFSET_CHANGED",           UpdateKeyboardMainbarOffsets)
  assert(compare(scope.ADDON_OFFSET_CHANGED,      { UpdateKeyboardStanceButtons, RefreshTooltip }))

  scope.dequeue("ADDON_SHOW_TOOLTIP",             UpdateTooltip)
  scope.dequeue("ADDON_SHOW_DROPDOWN",            UpdateDropdown)
  scope.dequeue("ADDON_UPDATE_LAYOUT",            UpdateKeyboardLayout)
  scope.dequeue("ADDON_OFFSET_CHANGED",           UpdateKeyboardStanceButtons)
  scope.dequeue("ADDON_OFFSET_CHANGED",           RefreshTooltip)
  scope.dequeue("ADDON_MODIFIER_CHANGED",         UpdateAllKeyboardButtons)
  scope.dequeue("ADDON_MODIFIER_CHANGED",         RefreshTooltip)
  scope.dequeue("UPDATE_MACROS",                  UpdateAllKeyboardButtons)
  scope.dequeue("UPDATE_BINDINGS",                UpdateKeyboardMainbarIndices)
  scope.dequeue("UPDATE_BINDINGS",                RefreshTooltip)
  scope.dequeue("PLAYER_TALENT_UPDATE",           RefreshTooltip)
  scope.dequeue("PLAYER_TALENT_UPDATE",           UpdateUnknownSpells)
  scope.dequeue("PLAYER_TALENT_UPDATE",           UpdateAllKeyboardButtons)
  scope.dequeue("ACTIONBAR_SLOT_CHANGED",         UpdateKeyboardMainbarSlots)
  scope.dequeue("PLAYER_SPECIALIZATION_CHANGED",  UpdateKeyboardStanceButtons)
  scope.dequeue("PLAYER_SPECIALIZATION_CHANGED",  UpdateAllKeyboardButtons)
  scope.dequeue("PLAYER_SPECIALIZATION_CHANGED",  RefreshTooltip)
  scope.dequeue("PLAYER_SPECIALIZATION_CHANGED",  UpdateUnknownSpells)

  assert(scope.ADDON_SHOW_TOOLTIP == nil)
  assert(scope.ADDON_SHOW_DROPDOWN == nil)
  assert(scope.ADDON_UPDATE_LAYOUT == nil)
  assert(scope.ADDON_OFFSET_CHANGED == nil)
  assert(scope.ADDON_MODIFIER_CHANGED == nil)
  assert(scope.UPDATE_MACROS == nil)
  assert(scope.UPDATE_BINDINGS == nil)
  assert(scope.PLAYER_TALENT_UPDATE == nil)
  assert(scope.ACTIONBAR_SLOT_CHANGED == nil)
  assert(scope.PLAYER_SPECIALIZATION_CHANGED == nil)
  assert(#keys(native) == 0)
  assert(#scope.pool == 10)
end)

run("#9 chain", function(assert)
  scope.clean(scope.pool)
  local order = ""
  local function first(next, ...)
    order = order.."first"
    return next(...)
  end
  local function second(next, ...)
    order = order.."second"
    return next(...)
  end
  local function third(next, ...)
    order = order.."third"
    return next(...)
  end

  local chain = scope.poolAcquire(scope.CHAIN, first, second, third)
  assert(compare({ 1, 2, 3 }, {scope.poolRelease(chain(1, 2, 3))}))
  assert(order == "firstsecondthird")
  assert(#scope.pool == 1)
  assert(scope.pool[1] == chain)
  assert(getmetatable(scope.pool[1]) == nil)
end)

run("#10 chain, shift/push", function(assert)
  scope.clean(scope.pool)
  local order = ""
  local function first(next, ...)
    order = order.."first"

    scope.shift(next, function(next, ...)
      order = order.."middle"
      return next(...)
    end)

    scope.push(next, function(next, ...)
      order = order.."after"
      return next(...)
    end)

    return next(...)
  end
  local function second(next, ...)
    order = order.."second"
    return next(...)
  end

  local chain = scope.poolAcquire(scope.CHAIN, first, second)
  local result = {scope.poolRelease(chain(1, 2, 3))}

  assert(compare(result, { 1, 2, 3 }))
  assert(order == "firstmiddlesecondafter")
  assert(#scope.pool == 1)
  assert(scope.pool[1] == chain)
  assert(getmetatable(scope.pool[1]) == nil)
end)

run("#10 chain, return early", function(assert)
  scope.clean(scope.pool)

  for i = 3, 1, -1 do
    local calls = 0
    local function first(next, a, b, c, num)
      calls = calls + 1
      if num == 1 then
        return next, num
      end
      return next(a, b, c, num)
    end
    local function second(next, a, b, c, num)
      calls = calls + 1
      if num == 2 then
        return next, num
      end
      return next(a, b, c, num)
    end
    local function third(next, a, b, c, num)
      calls = calls + 1
      if num == 3 then
        return next, num
      end
      return next(a, b, c, num)
    end

    local chain = scope.poolAcquire(scope.CHAIN, first, second, third)
    local result = {scope.poolRelease(chain("a", "b", "c", i))}

    assert(compare(result, { i }))
    assert(calls == i)
    assert(scope.pool[1] == chain)
    assert(getmetatable(scope.pool[1]) == nil)
  end
  assert(#scope.pool == 1)
end)

run("#11 dispatch", function(assert)
  scope.clean(scope.pool)
  local A = "PLAYER_SPECIALIZATION_CHANGED"
  local B = "ACTIONBAR_SLOT_CHANGED"
  local acalls = 0
  local bcalls = 0

  local a1 = scope.enqueue(A,  function(next, event, num, ...)
    assert(event == A)
    acalls = acalls + 1
    return next(event, num + 1, ...)
  end)

  local b1 = scope.enqueue(B,  function(next, event, num, ...)
    assert(event == B)
    bcalls = bcalls + 1
    return next(event, num + 1, ...)
  end)

  local a2 = scope.enqueue(A, function(next, event, num, ...)
    assert(event == A)
    acalls = acalls + 1
    return next(event, num + 1, ...)
  end)

  local b2 = scope.enqueue(B,  function(next, event, num, ...)
    assert(event == B)
    bcalls = bcalls + 1
    return next(event, num + 1, ...)
  end)

  local a3 = scope.enqueue(A, function(next, event, num, ...)
    assert(event == A)
    acalls = acalls + 1
    return next(event, num + 1, ...)
  end)

  local b3 = scope.enqueue(B,  function(next, event, num, ...)
    assert(event == B)
    bcalls = bcalls + 1
    return next(event, num + 1, ...)
  end)

  assert(compare({A, 4}, {scope:dispatch(A, 1)}))
  assert(compare({B, 4}, {scope:dispatch(B, 1)}))
  assert(acalls == 3)
  assert(bcalls == 3)

  scope.dequeue(A, a2)
  scope.dequeue(B, b2)

  assert(compare({A, 3}, {scope:dispatch(A, 1)}))
  assert(compare({B, 3}, {scope:dispatch(B, 1)}))
  assert(acalls == 5)
  assert(bcalls == 5)

  scope.dequeue(A, a1)
  scope.dequeue(A, a3)
  scope.dequeue(B, b1)
  scope.dequeue(B, b3)

  assert(scope[A] == nil)
  assert(scope[B] == nil)

  assert(compare({A, 1}, {scope:dispatch(A, 1)}))
  assert(compare({B, 1}, {scope:dispatch(B, 1)}))
  assert(acalls == 5)
  assert(bcalls == 5)
end)

run("#12 STACK.enqueue", function(assert)
  scope.clean(scope.pool)
  local A = "PLAYER_SPECIALIZATION_CHANGED"
  local B = "ACTIONBAR_SLOT_CHANGED"

  local a1 = function(next, event, num, ...)
    assert(event == A)
    return next(event, num + 1, ...)
  end
  local b1 = function(next, event, num, ...)
    assert(event == B)
    return next(event, num + 1, ...)
  end
  local a2 = function(next, event, num, ...)
    assert(event == A)
    return next(event, num + 1, ...)
  end
  local b2 = function(next, event, num, ...)
    assert(event == B)
    return next(event, num + 1, ...)
  end
  local a3 = function(next, event, num, ...)
    assert(event == A)
    return next(event, num + 1, ...)
  end
  local b3 = function(next, event, num, ...)
    assert(event == B)
    return next(event, num + 1, ...)
  end

  local stack = scope.poolAcquire(scope.STACK,
    scope.STACK.enqueue, A, a1,
    scope.STACK.enqueue, B, b1,
    scope.STACK.enqueue, A, a2,
    scope.STACK.enqueue, B, b2,
    scope.STACK.enqueue, A, a3,
    scope.STACK.enqueue, B, b3)
  local chain = scope.poolAcquire(scope.CHAIN)

  assert(compare({A, 1}, {scope:dispatch(A, 1)}))
  assert(compare({B, 1}, {scope:dispatch(B, 1)}))
  assert(scope[A] == nil)
  assert(scope[B] == nil)

  scope.push(chain, stack)
  assert(compare({1, 2, 3}, {select(2, chain(1, 2, 3))}))

  assert(#scope[A] == 3)
  assert(#scope[B] == 3)
  assert(compare({A, 4}, {scope:dispatch(A, 1)}))
  assert(compare({B, 4}, {scope:dispatch(B, 1)}))

  scope.push(chain, stack)
  assert(compare({3, 2, 1}, {select(2, chain(3, 2, 1))}))

  assert(scope[A] == nil)
  assert(scope[B] == nil)
  assert(compare({A, 1}, {scope:dispatch(A, 1)}))
  assert(compare({B, 1}, {scope:dispatch(B, 1)}))
end)

run("#12 STACK.fold", function(assert)
  scope.clean(scope.pool)
  local A = "PLAYER_SPECIALIZATION_CHANGED"
  local B = "ACTIONBAR_SLOT_CHANGED"
  local BEG = "ADDON_BEG"
  local END = "ADDON_END"

  local a1 = function(next, event, num, ...)
    assert(event == A)
    return next(event, num + 1, ...)
  end
  local b1 = function(next, event, num, ...)
    assert(event == B)
    return next(event, num + 1, ...)
  end
  local a2 = function(next, event, num, ...)
    assert(event == A)
    return next(event, num + 1, ...)
  end
  local b2 = function(next, event, num, ...)
    assert(event == B)
    return next(event, num + 1, ...)
  end
  local a3 = function(next, event, num, ...)
    assert(event == A)
    return next(event, num + 1, ...)
  end
  local b3 = function(next, event, num, ...)
    assert(event == B)
    return next(event, num + 1, ...)
  end

  local stack = scope.enqueue(BEG, scope.poolAcquire(scope.STACK,
    scope.STACK.fold, END,
    scope.STACK.enqueue, A, a1,
    scope.STACK.enqueue, B, b1,
    scope.STACK.enqueue, A, a2,
    scope.STACK.enqueue, B, b2,
    scope.STACK.enqueue, A, a3,
    scope.STACK.enqueue, B, b3
  ))

  assert(compare({END, 3, 2, 1}, {scope:dispatch(END, 3, 2, 1)}))
  assert(compare({A, 1}, {scope:dispatch(A, 1)}))
  assert(compare({B, 1}, {scope:dispatch(B, 1)}))

  assert(#scope[BEG] == 1)
  assert(scope[A] == nil)
  assert(scope[B] == nil)
  assert(scope[END] == nil)

  assert(compare({BEG, 3, 2, 1}, {scope:dispatch(BEG, 3, 2, 1)}))

  assert(compare({A, 4}, {scope:dispatch(A, 1)}))
  assert(compare({B, 4}, {scope:dispatch(B, 1)}))

  assert(scope[BEG] == nil)
  assert(#scope[A] == 3)
  assert(#scope[B] == 3)
  assert(#scope[END] == 1)

  assert(compare({END, 3, 2, 1}, {scope:dispatch(END, 3, 2, 1)}))
  assert(compare({A, 1}, {scope:dispatch(A, 1)}))
  assert(compare({B, 1}, {scope:dispatch(B, 1)}))

  assert(#scope[BEG] == 1)
  assert(scope[A] == nil)
  assert(scope[B] == nil)
  assert(scope[END] == nil) -- 27

  scope.dequeue(BEG, stack)
  assert(scope[BEG] == nil)
  assert(scope[A] == nil)
  assert(scope[B] == nil)
  assert(scope[END] == nil)
end)

run("#12 STACK.once/setup/clear", function(assert)
  scope.clean(scope.pool)
  local A = "PLAYER_SPECIALIZATION_CHANGED"
  local B = "ACTIONBAR_SLOT_CHANGED"

  local b1 = function(next, event, num, ...)
    assert(event == B)
    return next(event, num + 1, ...)
  end
  local b2 = function(next, event, num, ...)
    assert(event == B)
    return next(event, num + 1, ...)
  end
  local b3 = function(next, event, num, ...)
    assert(event == B)
    return next(event, num + 1, ...)
  end

  local called = false
  local setup
  local setupsCalled = 0
  local clearsCalled = 0
  local bothCalled = 0
  local stack = scope.enqueue(A, scope.poolAcquire(scope.STACK,
    scope.STACK.once, function(next, event, ...)
      assert(event == A)
      assert(called == false)
      called = true
      return next(event, ...)
    end,
    scope.STACK.setup, function(next, event, ...)
      assert(event == A)
      assert(setup == true)
      setupsCalled = setupsCalled + 1
      return next(event, ...)
    end,
    scope.STACK.clear, function(next, event, ...)
      assert(event == A)
      assert(setup == false)
      clearsCalled = clearsCalled + 1
      return next(event, ...)
    end,
    scope.STACK.both, function(next, event, ...)
      assert(event == A)
      bothCalled = bothCalled + 1
      return next(event, ...)
    end,
    scope.STACK.enqueue, B, b1,
    scope.STACK.enqueue, B, b2,
    scope.STACK.enqueue, B, b3
  ))

  assert(#scope[A] == 1)
  assert(scope[B] == nil)
  assert(called == false)

  assert(compare({B, 1}, {scope:dispatch(B, 1)}))
  assert(#scope[A] == 1)
  assert(scope[B] == nil)
  assert(called == false)

  for i = 1, 3 do
    setup = true
    assert(compare({B, 1}, {scope:dispatch(B, 1)}))
    assert(compare({A, 9}, {scope:dispatch(A, 9)}))
    assert(compare({B, 4}, {scope:dispatch(B, 1)}))
    assert(#scope[A] == 1)
    assert(#scope[B] == 3)
    assert(called == true)
    assert(setupsCalled == i)
    assert(clearsCalled == i-1)
    assert(bothCalled == i*2-1)

    setup = false
    assert(compare({A, 9}, {scope:dispatch(A, 9)}))
    assert(compare({B, 1}, {scope:dispatch(B, 1)}))
    assert(#scope[A] == 1)
    assert(scope[B] == nil)
    assert(setupsCalled == i)
    assert(clearsCalled == i)
    assert(bothCalled == i*2)
  end

  scope.dequeue(A, stack)
  assert(scope[A] == nil)
  assert(scope[B] == nil)
  assert(scope[BEG] == nil)
  assert(scope[END] == nil)
end)

run("#12 STACK.fold with nil", function(assert)
  scope.clean(scope.pool)
  local BEG = "ADDON_BEG"
  local END = "ADDON_END"

  assert(scope[BEG] == nil)
  assert(scope[END] == nil)

  local stack = scope.enqueue(BEG, scope.poolAcquire(scope.STACK,
    scope.STACK.fold, nil,
    scope.STACK.clear, function(next, ...)
      assert(false)
      return next(...)
    end
  ))

  assert(#scope[BEG] == 1)
  assert(scope[END] == nil)

  assert(compare({BEG}, {scope:dispatch(BEG)}))
  assert(compare({END}, {scope:dispatch(END)}))

  assert(scope[BEG] == nil)
  assert(scope[END] == nil)

  assert(compare({END}, {scope:dispatch(END)}))
  assert(compare({BEG}, {scope:dispatch(BEG)}))

  assert(scope[BEG] == nil)
  assert(scope[END] == nil)
end)

run("#13 savedvariables", function(assert)
  scope.class = "MAGE"
  scope.spec = 1
  OBroBindsDB = {}

  --local action
  --action = scope.GetAction("F5")
  --assert(action == scope.NIL)

  --scope.WriteAction("F5", scope.ACTION.kind, "SPELL", scope.ACTION.id, 1234, scope.ACTION.name, "name", scope.ACTION.icon, 123)
  --action = scope.GetAction("F5")

  --print(inspect(action))
  --print(action.SPELL, action.kind, action.id)

  local function test(expected, ti, ...)
    local tr, diff = scope.write(ti, ...)
    if diff ~= expected then
      print(...)
      print("input", inspect(ti))
      print("outpt", inspect(tr))
      assert(false)
    end
    return tr, diff
  end


  local t = nil
  t, diff = scope.write(t, scope.class, scope.spec, "F5", scope.ACTION.kind, "SPELL")
  t, diff = scope.write(t, scope.class, scope.spec, "F5", scope.ACTION.id, 123)
  --t, diff = scope.write(t, scope.class, scope.spec, "F5", scope.ACTION.id, nil)

  t, diff = test(false, t, scope.class, scope.spec, "F5", scope.ACTION.kind, "SPELL")
  t, diff = test(false, t, scope.class, scope.spec, "F5", scope.ACTION.id,   123)
  t, diff = test(true,  t, scope.class, scope.spec, "F5", scope.ACTION.name, "name")
  t, diff = test(true,  t, scope.class, scope.spec, "F5", scope.ACTION.icon, "icon")
  t, diff = test(true,  t, scope.class, scope.spec, "F5", scope.ACTION.lock, true)
  t, diff = test(true,  t, scope.class, nil)
  t, diff = test(false, t, scope.class, nil)
  t, diff = test(true,  t, scope.class, scope.spec, "F5", scope.ACTION.lock, true)
  t, diff = test(true,  t, scope.class, scope.spec, "F5", scope.ACTION.kind, "SPELL")
  t, diff = test(false, t, scope.class, scope.spec, "F5", scope.ACTION.lock, true)
  t, diff = test(false, t, scope.class, scope.spec, "F5", scope.ACTION.kind, "SPELL")

  --local a = scope.read(t, scope.class, scope.spec, "F5")
  --a, diff = test(true, a, scope.ACTION.icon, 123)
  --print(inspect(t, scope.class, scope.spec, "F5"))

  for i = 1, 1 do
    local diff = scope.UpdateActionSpell("F6", 123, "somename", nil)
    print(1, diff)
  end
  local action = scope.GetAction("F6")
  print(diff, inspect(action))
end)
]]
