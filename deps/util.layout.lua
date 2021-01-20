local _, addon = ...
local next, _, rpush, clean, _, subscribe, dispatch, unsubscribe, write, read, dbWrite, dbRead, getModifier, match = unpack(addon)
local tinsert = table.insert
local tremove = table.remove
local mmax = math.max
local mmin = math.min
local SPELL, MACRO, ITEM = 1, 2, 3

--[[
    self.index = 0 -- index of the next button to use
    self.size = 40 -- size of the button
    self.x, self.xmin, self.xmax = 0, UIParent:GetRight(), UIParent:GetLeft()
    self.y, self.ymin, self.ymax = 0, UIParent:GetTop(), UIParent:GetBottom()

    self.size, self.x, self.y, self.xmin, self.xmax, self.ymin, self.ymax = nil
    for i = self.index+1, #self do
      local button = self[i]
      button:Hide()
    end
]]

local function colSet(self, x, ...)
  self.x = mmax(0, self.size * x)
  return next(self, ...)
end
tinsert(addon, colSet)

local function colAdd(self, x, ...)
  self.x = mmax(0, self.x + self.size * x)
  return next(self, ...)
end
tinsert(addon, colAdd)

local function rowSet(self, y, ...)
  self.y = mmax(0, self.size * y)
  return next(self, ...)
end
tinsert(addon, rowSet)

local function rowAdd(self, y, ...)
  self.y = mmax(0, self.y + self.size * y)
  return next(self, ...)
end
tinsert(addon, rowAdd)

do
  local function button(self, key, ...)
    self:CreateActionButton(key)
    return next(self, ...)
  end
  tinsert(addon, button)

  do
    local __tmp = {}
    local function buttonRow(self, motion, amount, keys, ...)
      for key in string.gmatch(keys, "[^ ]+") do
        rpush(__tmp, button, strupper(key), motion or colAdd, amount or 1)
      end
      rpush(__tmp, ...)
      return next(self, clean, __tmp, unpack(__tmp))
    end
    tinsert(addon, buttonRow)
  end
end
