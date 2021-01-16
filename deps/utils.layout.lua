local _, addon = ...
local _, next, _, rpush, clean = unpack(addon)
local tinsert = table.insert

local function init(self, parent, ...)
  self.__cursor, self.__parent, self.__size, self.__x, self.__y, self.__xmin, self.__xmax, self.__ymin, self.__ymax = 0, parent, 40, 0, 0, 0, 0, 0, 0
  return next(self, ...)
end
tinsert(addon, init)

local function cleanup(self, ...)
  local w = self.__xmax - self.__xmin + self.__size - 16
  local h = self.__ymax - self.__ymin + self.__size - 12
  self.__parent:SetSize(w, h)
  self.__parent, self.__size, self.__x, self.__y, self.__xmin, self.__xmax, self.__ymin, self.__ymax = nil
  for i = self.__cursor+1, #self do
    print("cleanup button", i, self[i])
  end
  return next(self, ...)
end
tinsert(addon, cleanup)

local function setMinMax(self, min, max, v)
  self[min] = math.min(self[min], v)
  self[max] = math.max(self[max], v)
  return v
end
local function colSet(self, x, ...)
  self.__x = setMinMax(self, '__xmin', '__xmax', self.__size * x)
  return next(self, ...)
end
tinsert(addon, colSet)

local function colAdd(self, x, ...)
  self.__x = setMinMax(self, '__xmin', '__xmax', self.__x + self.__size * x)
  return next(self, ...)
end
tinsert(addon, colAdd)

local function rowSet(self, y, ...)
  self.__y = setMinMax(self, '__ymin', '__ymax', self.__size * y)
  return next(self, ...)
end
tinsert(addon, rowSet)

local function rowAdd(self, y, ...)
  self.__y = setMinMax(self, '__ymin', '__ymax', self.__y + self.__size * y)
  return next(self, ...)
end
tinsert(addon, rowAdd)

do
  local GetModifier, _, _, _, _, _, _, _, _, dbWrite, dbRead = unpack(addon)
  local function OnReceiveDrag(self)
    local kind, arg1, _, arg2, arg3 = GetCursorInfo()
    local class = select(2, UnitClass("player"))
    ClearCursor()
    if kind == 'spell' then
      self.icon:SetTexture(select(3, GetSpellInfo(arg3 or arg2)))
      OBroBindsDB = dbWrite(OBroBindsDB, class, self.__key, GetModifier(), { kind, arg3 or arg2 })
    elseif kind == 'macro' then
      self.icon:SetTexture(select(2, GetMacroInfo(arg1)))
      OBroBindsDB = dbWrite(OBroBindsDB, class, self.__key, GetModifier(), { kind, arg1 })
    elseif kind == 'item' then
      self.icon:SetTexture(select(10, GetItemInfo(arg1)))
      OBroBindsDB = dbWrite(OBroBindsDB, class, self.__key, GetModifier(), { kind, arg1 })
    end
  end

  local function OnDragStart(self)
    local modifier = GetModifier()
    local class = select(2, UnitClass("player"))
    local kind, id = next(dbRead(OBroBindsDB, class, self.__key, modifier), unpack)
  end

  local function OnClick(self, button)
    if button == "RightButton" then
      local class = select(2, UnitClass("player"))
      local stance = dbRead(OBroBindsDB, class, self.__key, 'stance')
      OBroBindsDB = dbWrite(OBroBindsDB, class, self.__key, 'stance', (not stance) and true or nil)
      --OBroBindsDB = dbWrite(OBroBindsDB, class, 'stance', nil)
      if stance then
        print("remove")
        local function remove(tbl, key)
          for i = #tbl, 1, -1 do
            if tbl[i] == key then
              table.remove(tbl, i)
            end
          end
          return tbl
        end
        OBroBindsDB = dbWrite(OBroBindsDB, class, 'stance', remove, self.__key)
      else
        print("append")
        OBroBindsDB = dbWrite(OBroBindsDB, class, 'stance', rpush, self.__key)
      end
    end
  end

  local function buttonCreate(self, key, ...)
    self.__cursor = self.__cursor + 1
    local button
    if self.__cursor > #self then
      button = CreateFrame("button", nil, self.__parent, "ActionButtonTemplate")
      button:SetScript("OnReceiveDrag", OnReceiveDrag)
      button:SetScript("OnClick", OnClick)
      button:SetScript("OnDragStart", OnDragStart)
      button:RegisterForDrag("LeftButton")
      button:RegisterForClicks("AnyUp")
      tinsert(self, button)
    else
      button = self[self.__cursor]
    end
    button:SetPoint("TOPLEFT", 16 + self.__x, -self.__y - 16)
    button.HotKey:SetText(key)
    button.__key = key
    return next(self, ...)
  end
  tinsert(addon, buttonCreate)

  do
    local __tmp = {}
    local function buttonRow(self, motion, amount, keys, ...)
      for key in string.gmatch(keys, "[^ ]+") do
        rpush(__tmp, buttonCreate, key, motion or colAdd, amount or 1)
      end
      rpush(__tmp, ...)
      return next(self, clean, __tmp, unpack(__tmp))
    end
    tinsert(addon, buttonRow)
  end

end
