local _, addon = ...
local next, _, rpush, clean = unpack(addon)
local tinsert = table.insert
local mmax = math.max

do
  local function init(self, parent, ...)
    self._p = parent
    self._c = 0 -- index of the next button to use
    self._s = 40 -- size of the button
    self._x, self._xmin, self._xmax = 0, UIParent:GetRight(), UIParent:GetLeft()
    self._y, self._ymin, self._ymax = 0, UIParent:GetTop(), UIParent:GetBottom()
    return next(self, ...)
  end
  tinsert(addon, init)
end

do
  local function cleanup(self, ...)
    self._p:SetSize(self._xmax - self._xmin + 32, self._ymax - self._ymin + 32)
    self._p, self._s, self._x, self._y, self._xmin, self._xmax, self._ymin, self._ymax = nil
    for i = self._c+1, #self do
      print("cleanup button", i, self[i])
    end
    return next(self, ...)
  end
  tinsert(addon, cleanup)
end

local function colSet(self, x, ...)
  self._x = mmax(0, self._s * x)
  return next(self, ...)
end
tinsert(addon, colSet)

local function colAdd(self, x, ...)
  self._x = mmax(0, self._x + self._s * x)
  return next(self, ...)
end
tinsert(addon, colAdd)

local function rowSet(self, y, ...)
  self._y = mmax(0, self._s * y)
  return next(self, ...)
end
tinsert(addon, rowSet)

local function rowAdd(self, y, ...)
  self._y = mmax(0, self._y + self._s * y)
  return next(self, ...)
end
tinsert(addon, rowAdd)

do
  local button
  do
    local mmin = math.min
    function button(self, key, ...)
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
      self._xmin = mmin(self._xmin, button:GetLeft())
      self._xmax = mmax(self._xmax, button:GetRight())
      self._ymin = mmin(self._ymin, button:GetBottom())
      self._ymax = mmax(self._ymax, button:GetTop())
      return next(self, ...)
    end
    tinsert(addon, button)
  end

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
