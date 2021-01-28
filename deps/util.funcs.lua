local _A = select(2, ...)
local tinsert = _G.table.insert
local tremove = _G.table.remove

local function splice(tbl, index)
  tremove(tbl, index)
  return tbl
end
_A.splice = splice

local function shift(tbl, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    tinsert(tbl, i, arg)
  end
  return tbl
end
_A.shift = shift

local function push(tbl, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    tinsert(tbl, arg)
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

    --local __NAMES
    local pool = {}
    local function reuse(q, ...)
      --__NAMES = write(__NAMES, tostring(q), nil)
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
      --__NAMES = write(__NAMES, tostring(q), true)
      q.key = key
      return reuse(q, q:next(self, ...))
    end
    _A.dispatch = dispatch

    local once = true
    local t = {}
    function _A.REPORT()
      print("----REPORT-subs")
      if SUBS then
        for k, v in pairs(SUBS) do
          print(">>", k, #v)
        end
      end
      if once then
        for k, v in pairs(_A) do
          t[k] = true
        end
        setmetatable(_A, {__mode = 'v'})
        once = false
      end
      collectgarbage("collect")
      for k, v in pairs(_A) do
        t[k] = nil
      end
      print("----REPORT-refs")
      for k in pairs(t) do
        print("<<", k)
      end
      for k, v in pairs(_A) do
        t[k] = true
      end
    end
  end
end
