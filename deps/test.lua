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

local inspect = require("./inspect")
local scope = {}
import("./utils.misc.lua", nil, scope)

local function run(msg, fn)
  local index = 0
  local function assert(result)
    index = index + 1
    if not result then
      print("[xx]", msg, index)
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
      print(inspect(a))
      print(inspect(b))
      return false
    end
    return true
  end
end

run("#1", function(assert)
  local t, fn = nil, scope.write3
  scope.clean(scope.pool)

  t = fn(t, "PRIEST", true)
  assert(t.PRIEST == true)
  assert(compare(t, { PRIEST = true }))

  t = fn(t, "PRIEST", 1, "F1", 1, "SPELL")
  assert(compare(t, { PRIEST = { { F1 = { "SPELL" }}}}))

  t = fn(t, "PRIEST", 1, "F1", 2, "ID")
  assert(compare(t, { PRIEST = { { F1 = { "SPELL", "ID" }}}}))

  t = fn(t, "PRIEST", 1, "F1", 1, nil)
  t = fn(t, "PRIEST", 1, "F1", 2, "DI")
  assert(compare(t, { PRIEST = { { F1 = { nil, "DI" }}}}))

  t = fn(t, "PRIEST", 1, "F1", 2, nil)
  assert(t == nil)
  assert(#scope.pool == 4)
end)

run("#2", function(assert)
  local t, fn = nil, scope.write3
  scope.clean(scope.pool)

  t = fn(t, "PRIEST", 1, "F1", 1, "SPELL")
  t = fn(t, "PRIEST", 1, "F1", 2, "ID")
  assert(compare(t, { PRIEST = { { F1 = { "SPELL", "ID" }}}}))

  t = fn(t, nil)
  assert(#scope.pool == 4)

  local copies = {table.unpack(scope.pool)}
  t = fn(t, "PRIEST", 1, "F1", 1, "SPELL")
  t = fn(t, "PRIEST", 1, "F1", 2, "ID")

  assert(#scope.pool == 0)
  assert(scope.match(t, table.unpack(copies)))
  assert(scope.match(t.PRIEST, table.unpack(copies)))
  assert(scope.match(t.PRIEST[1], table.unpack(copies)))
  assert(scope.match(t.PRIEST[1].F1, table.unpack(copies)))

  t = fn(t, nil)
  assert(t == nil)
  assert(#scope.pool == 4)
end)

--[[
run("#3", function(assert)
  scope.clean(scope.pool)
  t = nil
  t = fn(t, "GUI", "open", true)
  t = fn(t, "GUI", "open", "replace", true)
  assert(t.GUI.open.replace == true)
end)

run("#4", function(assert)
  scope.clean(scope.pool)
  t = fn(nil, scope.push, 1, 2, 3)
  assert(#scope.pool == 0)
  assert(#t == 3)
  assert(t[1] == 1)
  assert(t[2] == 2)
  assert(t[3] == 3)
end)

run("#5", function(assert)
  scope.clean(scope.pool)
  t = fn(nil, "one", "two", scope.push, 1, 2, 3)
  assert(#scope.pool == 0, "nt")
  assert(#t.one.two == 3, "nt")
  assert(t.one.two[1] == 1, "nt")
  assert(t.one.two[2] == 2, "nt")
  assert(t.one.two[3] == 3, "nt")
  assert(compare(t, { one = { two = { 1, 2, 3 }}}))
end)

run("#6", function(assert)
  local tbl
  local function nilfn(a, b, c)
    tbl = a
    return nil
  end
  scope.clean(scope.pool)
  t = fn(nil, "one", "two", nilfn, 1, 2, 3)
  assert(#scope.pool == 1)
  assert(tbl == scope.pool[1])
  assert(compare(t, nil))

  t = fn(t, "one", "two", nilfn)
  assert(#scope.pool == 1)
  assert(tbl == scope.pool[1])
  assert(compare(t, nil))
end)

run("#7", function(assert)
  local function ident(tbl, ...)
    scope.push(tbl, ...)
    return tbl
  end
  scope.clean(scope.pool)
  t = fn(nil, "one", "two", ident, 1, 2, 3)
  assert(compare(t, { one = { two = { 1, 2, 3 }}}))

  local function ident2(tbl, ...)
    scope.push(tbl, "ok")
    return tbl
  end
  t = fn(t, "one", "two", ident2)
  assert(compare(t, { one = { two = { 1, 2, 3, "ok" }}}))

  for i = 1, 10 do
    t = fn(t, "one", "two", scope.push, 1, 2, 3)
    t = fn(t, "one", nil)
    assert(compare(t, nil))
    assert(#scope.pool == 3)
  end

  t = fn(t, "one", "two", 4)
  t = fn(t, nil)
  assert(compare(t, nil))
  assert(#scope.pool == 3)
end)
]]
