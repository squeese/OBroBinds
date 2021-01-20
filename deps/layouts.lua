local _, addon = ...
local next = addon:get("next")
local mmax = math.max

local function col(self, _, y, s, x, fn, ...)
  return next(fn, self, mmax(0, x * s), y, s, ...)
end

local function row(self, x, _, s, y, fn, ...)
  return next(fn, self, x, mmax(0, y * s), s, ...)
end

local function move(self, x, y, s, X, Y, fn, ...)
  return next(fn, self, mmax(0, x+X*s), mmax(0, y+Y*s), s, ...)
end

local function key(self, x, y, s, char, fn, ...)
  tinsert(self, strupper(char))
  tinsert(self, x)
  tinsert(self, y)
  return next(fn, self, x, y, s, ...)
end

local keys
do
  local tmp = {}
  local function clean(self, x, y, s, fn, ...)
    for i = 1, #tmp do
      tmp[i] = nil
    end
    return next(fn, self, x, y, s, ...)
  end
  function keys(self, x, y, s, X, Y, keystring, ...)
    for char in string.gmatch(keystring, "[^ ]+") do
      tinsert(tmp, key)
      tinsert(tmp, char)
      tinsert(tmp, move)
      tinsert(tmp, X or 1)
      tinsert(tmp, Y or 0)
    end
    for i = 1, select("#", ...) do
      local val = select(i, ...)
      tinsert(tmp, val)
    end
    return next(clean, self, x, y, s, unpack(tmp))
  end
end

local function layout(size, fn, ...)
  return select(2, next(fn, {}, 0, 0, 40, ...))
end

addon.DEFAULT_KEYBOARD_LAYOUT = layout(40,
  col, 1,               keys, 1, 0, "F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 PRINT PAUSE DEL",
  col, 0,   move, 0, 1, keys, 1, 0, "` 1 2 3 4 5 6 7 8 9 0 - =",
  col, 1.3, move, 0, 1, keys, 1, 0, "q w e r t y u i o p [ ]",
  col, 1.6, move, 0, 1, keys, 1, 0, "a s d f g h j k l ; ' \\",
  col, 1,   move, 0, 1, keys, 1, 0, "\\ z x c v b n m , . /")
