local _, addon = ...
local next, _, rpush, clean, _, subscribe, dispatch, unsubscribe, dbWrite, dbRead, getModifier = unpack(addon)
local tinsert = table.insert
local mmax = math.max
local mmin = math.min
local SPELL, MACRO, ITEM = 1, 2, 3

local function OnActionButtonDragStart(self)
  local modifier = getModifier()
  local kind, id = next(dbRead(nil, self.__key, modifier), unpack)
end

local function OnActionButtonUpdate(self, modifier)
  local kind, id = next(dbRead(nil, self.__key, modifier), unpack)
  if kind == SPELL then
    self.icon:SetTexture(select(3, GetSpellInfo(id)))
  elseif kind == MACRO then
    self.icon:SetTexture(select(2, GetMacroInfo(id)))
  elseif kind == ITEM then
    self.icon:SetTexture(select(10, GetItemInfo(id)))
  end
end

local function OnActionButtonReceiveDrag(self)
  local kind, arg1, _, arg2, arg3 = GetCursorInfo()
  local modifier = getModifier()
  ClearCursor()
  if kind == 'spell' then
    dbWrite(nil, self.__key, modifier, { SPELL, arg3 or arg2 })
  elseif kind == 'macro' then
    dbWrite(nil, self.__key, modifier, { MACRO, arg1 })
  elseif kind == 'item' then
    dbWrite(nil, self.__key, modifier, { ITEM, arg1 })
  end
  OnActionButtonUpdate(self, modifier)
end

local function OnActionButtonClick(self, button)
  if button == "RightButton" then
    local stance = dbRead(nil, self.__key, 'stance')
    dbWrite(nil, self.__key, 'stance', (not stance) and true or nil)
    --[[
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
      dbWrite(class, 'stance', remove, self.__key)
    else
      print("append")
      dbWrite(class, 'stance', rpush, self.__key)
    end
    ]]
  end
end

subscribe("INITIALIZE", function(self, parent)
  local function CreateActionButton(self)
    self.index = self.index + 1
    if self.index > #self then
      local button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
      button:SetScript("OnDragStart", OnActionButtonDragStart)
      button:SetScript("OnReceiveDrag", OnActionButtonReceiveDrag)
      button:SetScript("OnClick", OnActionButtonClick)
      button:RegisterForDrag("LeftButton")
      button:RegisterForClicks("AnyUp")
      --subscribe("MODIFIER_CHANGED", button, OnActionButtonUpdate)
      --subscribe("OFFSET_CHANGED", button, OnActionButtonUpdate)
      tinsert(self, button)
    end
  end
  subscribe("LAYOUT_CHANGED", self, function(_, layout)
    if self.layout == layout then return end
    self.layout = layout
    self.index = 0 -- index of the next button to use
    self.size = 40 -- size of the button
    self.x, self.xmin, self.xmax = 0, UIParent:GetRight(), UIParent:GetLeft()
    self.y, self.ymin, self.ymax = 0, UIParent:GetTop(), UIParent:GetBottom()
    subscribe("CREATE_ACTION_BUTTON", self, CreateActionButton)
    next(self, unpack(layout))
    unsubscribe("CREATE_ACTION_BUTTON", self, true)
    local width = self.xmax - self.xmin + 32
    local height = self.ymax - self.ymin + 32
    parent:SetSize(width, height)
    self.size, self.x, self.y, self.xmin, self.xmax, self.ymin, self.ymax = nil
    for i = self.index+1, #self do
      print("cleanup button", i, self[i])
    end
  end)
  unsubscribe("INITIALIZE", self, true)
end)

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
    dispatch("CREATE_ACTION_BUTTON")
    local button = self[self.index]
    button.__key = key
    button.HotKey:SetText(key)
    button:SetPoint("TOPLEFT", 16 + self.x, -self.y - 16)
    self.xmin = mmin(self.xmin, button:GetLeft())
    self.xmax = mmax(self.xmax, button:GetRight())
    self.ymin = mmin(self.ymin, button:GetBottom())
    self.ymax = mmax(self.ymax, button:GetTop())
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
