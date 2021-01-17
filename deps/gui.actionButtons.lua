local _, addon = ...
local next, _, rpush, clean, _, subscribe, dispatch, unsubscribe, write, read, dbWrite, dbRead, getModifier, match = unpack(addon)
local tinsert = table.insert
local tremove = table.remove
local mmax = math.max
local mmin = math.min
local SPELL, MACRO, ITEM = 1, 2, 3

subscribe("INITIALIZE", function(self, parent)
  --self.modifier = getModifier()
  --self.offset = dbRead(nil, 'offset')
  --subscribe("MODIFIER_CHANGED", self, function(_, modifier)
    --self = write(self, 'modifier', modifier)
    --print("status", self.modifier, self.offset)
  --end)
  --subscribe("OFFSET_CHANGED", self, function(_, offset)
    --self = write(self, 'offset', offset)
    --print("status", self.modifier, self.offset)
  --end)


  local function increment(value)
    return type(value) == 'number' and (value + 1) or 1
  end

  local function decrement(value)
    if type(value) == 'number' and value > 1 then
      return value - 1
    end
  end

  subscribe("CREATE_BIND", self, function(_, button, kind, id)
    local current = dbRead(nil, button.key, button.modifier, button.offset)
    if not current then
      dbWrite(nil, button.key, 'binds', increment)
      subscribe("MODIFIER_CHANGED", button)
    end
    dbWrite(nil, button.key, button.modifier, button.offset, { kind, id })
    button:Update()
  end)

  subscribe("DELETE_BIND", self, function(_, button)
    dbWrite(nil, button.key, button.modifier, button.offset, nil)
    dbWrite(nil, button.key, 'binds', decrement)
    if not dbRead(nil, button.key, 'binds') then
      unsubscribe("MODIFIER_CHANGED", button)
      unsubscribe("OFFSET_CHANGED", button)
    end
    button:Update()
  end)

  subscribe("TOGGLE_STANCE", self, function(_, button)
    --dbWrite(nil, button.__key, getModifier(), 'index', 1)
    ---- dbWrite(nil, button.__key, )
    --dbWrite(nil, button.__key, 'binds', decrement)
    --print("value", dbRead(nil, button.__key, 'binds'))
  end)

  unsubscribe("INITIALIZE", self, true)
end)

subscribe("INITIALIZE", function(self, parent)
  local function OnActionButtonDragStart(self)
    self.pickup(self.id)
    dispatch("DELETE_BIND", self)
  end

  local function OnActionButtonReceiveDrag(self)
    local kind, id, _, arg1, arg2 = GetCursorInfo()
    ClearCursor()
    if kind == "spell" then
      dispatch("CREATE_BIND", self, SPELL, arg2 or arg1)
    elseif kind == "macro" then
      dispatch("CREATE_BIND", self, MACRO, id)
    elseif kind == "item" then
      dispatch("CREATE_BIND", self, ITEM, id)
    elseif kind then
      assert(false, 'uncatched type: '..kind)
    end
  end

  --[[
    local identifier = self.__key .. "-" .. modifier

    dbWrite(nil, self.__key, modifier, )
    dbWrite(nil, self.__key, modifier, function(entry, ...)
      if entry.main then
        write(entry, offset or 1, 1, kind)
        write(entry, offset or 1, 2, id)
      else
        write(entry, 1, kind)
        write(entry, 2, id)
      end
      return entry
    end)
    OnActionButtonUpdate(self)
  end
  ]]

  local OnActionButtonClick
  do
    --[[
    local function remove(keys, key, modifier)
      print("before", unpack(keys))
      for i = (#keys-1), 1, -2 do
        if keys[i] == key and keys[i+1] == modifier then
          tremove(keys, i)
          tremove(keys, i)
        end
      end
      return keys
    end
    local function mainbarEntryPromotion(entry)
      if #entry > 0 then
        write(entry, 1, {unpack(entry)})
        for i = 2, #entry do
          entry[i] = nil
        end
      end
      return entry
    end
    local function mainbarEntryDemotion(entry)
      for key, val in pairs(entry) do
        if type(key) ~= 'number' then
          write(entry, 1, key, val)
        end
      end
      return entry[1]
    end

    local function mainbarOrderUpdate(indices, index)
    end
    ]]

    function OnActionButtonClick(self, button)
      if button == "RightButton" then
        dispatch("TOGGLE_STANCE", self)
      elseif button == "LeftButton" then
        OnActionButtonReceiveDrag(self)
      end

        --[[
        local mainbarIndex = dbRead(nil, self.__key, modifier, 'mainbarIndex')
        if not mainbarIndex then
          dbWrite(nil, 'mainbarOrder', rpush, {self.__key, modifier})
          mainbarIndex = #dbRead(nil, 'mainbarOrder')
          dbWrite(nil, self.__key, 'mainbarIndices', rpush, mainbarIndex)
          dbWrite(nil, self.__key, modifier, 'mainbarIndex', mainbarIndex)
          -- dbWrite(nil, self.__key, modifier, mainbarEntryPromotion)
          subscribe("MAIN_CHANGED", self)
          subscribe("OFFSET_CHANGED", self)
          OnActionButtonUpdate(self)
        else
          dbWrite(nil, self.__key, 'mainbarIndices', nil)
          dbWrite(nil, self.__key, modifier, 'mainbarIndex', nil)
          dbWrite(nil, self.__key, modifier, mainbarEntryDemotion)
          dbWrite(nil, 'mainbarOrder', mainbarOrderUpdate, mainbarIndex)
          unsubscribe("MAIN_CHANGED", self)
          unsubscribe("OFFSET_CHANGED", self)
          OnActionButtonUpdate(self)
        end
        ]]

        --reorderMainbarButtons()
        --local function reorderMainbarButtons()
          --local entries = dbRead(nil, 'mainbarButtonOrder')
          --if not entries then return end
          --for index = 1, (#entries - 1), 2 do
            --local key, modifier = select(index, unpack(entries))
            --dbWrite(nil, key, modifier, 'mainbarButtonOrder', (index+1)/2)
          --end
          --dispatch("MAIN_CHANGED")
        --end

        --if keys then
        --end
    end
  end

  local function OnActionButtonUpdate(self)
    local kind, id = next(dbRead(nil, self.key, self.modifier, self.offset), unpack)
    if kind then
      if kind == SPELL then
        self.icon:SetTexture(select(3, GetSpellInfo(id)))
        self.pickup = PickupSpell
      elseif kind == MACRO then
        self.icon:SetTexture(select(2, GetMacroInfo(id)))
        self.pickup = PickupMacro
      elseif kind == ITEM then
        self.pickup = PickupItem
        self.icon:SetTexture(select(10, GetItemInfo(id)))
      end
      self.id = id
      self:SetScript("OnDragStart", OnActionButtonDragStart)
    else
      self.pickup = nil
      self.id = nil
      self.icon:SetTexture(nil)
      self:SetScript("OnDragStart", nil)
    end
    --[[
    if read(entry, 'main') then
      kind, id = next(read(entry, offset or 1), unpack)
      self.Border:Show()
      self.Border:SetAlpha(1)
      self.Name:SetText(entry.main)
    else
      kind, id = next(entry, unpack)
      if dbRead(nil, self.__key, 'main') then
        self.Border:Show()
        self.Border:SetAlpha(0.5)
        self.Name:SetText()
      else
        self.Border:Hide()
        self.Name:SetText("")
      end
    end
    ]]
  end


  local function OnModifierChanged(self, modifier)
    self.modifier = modifier
    self:Update()
  end

  local function OnOffsetChanged(self, offset)
    self.offset = offset
    self:Update()
  end

  local function CreateActionButton(self, key)
    self.index = self.index + 1
    local button
    if self.index > #self then
      button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
      button:SetScript("OnReceiveDrag", OnActionButtonReceiveDrag)
      button:SetScript("OnClick", OnActionButtonClick)
      button:RegisterForDrag("LeftButton")
      button:RegisterForClicks("AnyUp")
      button.MODIFIER_CHANGED = OnModifierChanged
      button.OFFSET_CHANGED = OnModifierChanged
      button.Update = OnActionButtonUpdate
      tinsert(self, button)
    else
      button = self[self.index]
    end

    button:SetPoint("TOPLEFT", 16 + self.x, -self.y - 16)
    button.Border:Hide()
    button.Border:SetAlpha(1)
    button.HotKey:SetText(key)
    button.Name:SetText()

    self.xmin = mmin(self.xmin, button:GetLeft())
    self.xmax = mmax(self.xmax, button:GetRight())
    self.ymin = mmin(self.ymin, button:GetBottom())
    self.ymax = mmax(self.ymax, button:GetTop())

    button.key = key
    button.modifier = self.modifier
    local index = dbRead(nil, key, self.modifier, 'index')
    button.offset = index and dbRead(nil, 'offset') or 1
    if dbRead(nil, key, 'binds') then
      subscribe("MODIFIER_CHANGED", button)
      print("mod sub", key)
      if index then
        print("off sub", key)
        subscribe("OFFSET_CHANGED", button)
      end
      button:Update()
    end
  end

  subscribe("LAYOUT_CHANGED", self, function(_, layout)
    if self.layout == layout then return end
    self.layout = layout
    -- self.modifier = getModifier()
    -- self.offset = dbRead(nil, offset)
    self.index = 0 -- index of the next button to use
    self.size = 40 -- size of the button
    self.x, self.xmin, self.xmax = 0, UIParent:GetRight(), UIParent:GetLeft()
    self.y, self.ymin, self.ymax = 0, UIParent:GetTop(), UIParent:GetBottom()
    self.modifier = getModifier()
    subscribe("CREATE_ACTION_BUTTON", self, CreateActionButton)
    next(self, unpack(layout))
    unsubscribe("CREATE_ACTION_BUTTON", self)
    local width = self.xmax - self.xmin + 32
    local height = self.ymax - self.ymin + 32
    parent:SetSize(width, height)
    self.size, self.x, self.y, self.xmin, self.xmax, self.ymin, self.ymax, self.modifier = nil
    for i = self.index+1, #self do
      local button = self[i]
      button:Hide()
      unsubscribe("MODIFIER_CHANGED", button)
      unsubscribe("OFFSET_CHANGED", button)
      button.pickup, button.id = nil
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
    dispatch("CREATE_ACTION_BUTTON", key)
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
