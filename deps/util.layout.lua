local _, addon = ...
local next, _, rpush, clean = unpack(addon)
local tinsert = table.insert

do
  local function init(self, parent, ...)
    self._p = parent
    self._c = 0 -- index of the next button to use
    self._s = 40 -- size of the button
    self._x, self._xmin, self._xmax = 0, 0, 0 -- current x position
    self._y, self._ymin, self._ymax = 0, 0, 0 -- current y position
    return next(self, ...)
  end
  print("init", init)
  tinsert(addon, init)
end

do
  local function cleanup(self, ...)
    local w = self._xmax - self._xmin + self._s - 16
    local h = self._ymax - self._ymin + self._s - 12
    self._p:SetSize(w, h)
    self._p, self._s, self._x, self._y, self._xmin, self._xmax, self._ymin, self._ymax = nil
    for i = self._c+1, #self do
      print("cleanup button", i, self[i])
    end
    return next(self, ...)
  end
  tinsert(addon, cleanup)
end

local colSet, colAdd, rowSet, rowAdd
do
  local mmin = math.min
  local mmax = math.max
  local function setMinMax(self, min, max, v)
    self[min] = mmin(self[min], v)
    self[max] = mmax(self[max], v)
    return v
  end

  function colSet(self, x, ...)
    print("colSet", x, self._x, self._y, self._xmin, self._xmax, self._y, self._ymin, self._ymax)
    self._x = setMinMax(self, '_xmin', '_xmax', self._s * x)
    return next(self, ...)
  end
  print("colSet!", colSet)
  tinsert(addon, colSet)

  function colAdd(self, x, ...)
    self._x = setMinMax(self, '_xmin', '_xmax', self._x + self._s * x)
    return next(self, ...)
  end
  tinsert(addon, colAdd)

  function rowSet(self, y, ...)
    self._y = setMinMax(self, '_ymin', '_ymax', self._s * y)
    return next(self, ...)
  end
  tinsert(addon, rowSet)

  function rowAdd(self, y, ...)
    self._y = setMinMax(self, '_ymin', '_ymax', self._y + self._s * y)
    return next(self, ...)
  end
  tinsert(addon, rowAdd)
end

do
  local function button(self, key, ...)
    self._c = self._c + 1
    local button
    if self._c > #self then
      button = addon.CreateActionButton(self._p)
      tinsert(self, button)
    else
      button = self[self._c]
    end
    button.__key = key
    button.HotKey:SetText(key)
    button:SetPoint("TOPLEFT", 16 + self._x, -self._y - 16)
    return next(self, ...)
  end
  tinsert(addon, button)

  do
    local __tmp = {}
    local function buttonRow(self, motion, amount, keys, ...)
      for key in string.gmatch(keys, "[^ ]+") do
        rpush(__tmp, button, key, motion or colAdd, amount or 1)
      end
      rpush(__tmp, ...)
      return next(self, clean, __tmp, unpack(__tmp))
    end
    tinsert(addon, buttonRow)
  end
end
