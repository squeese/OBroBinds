local _, addon = ...
local next, _, rpush, _, _, subscribe, dispatch, unsubscribe, dbWrite, dbRead, getModifier = unpack(addon)

do
  function addon.FinalizeClass()
    class = select(2, UnitClass("player"))
    for i = #stances, 1, -1 do
      if class ~= stances[i].class then
        table.remove(stances, i)
      end
    end
    if #stances == 0 then
      stances = nil
    end
    addon.FinalizeClass = nil
    return class, stances
  end
end

do
  local function OnStanceButtonUpdate(self, offset)
    print("??", self.__offset, offset)
    next(self.Border, self.__offset == offset and self.Border.Show or self.Border.Hide)
  end

  local function OnStanceButtonClick(self)
    local current = dbRead(class, "offset")
    local offset = self.__offset == current and nil or self.__offset
    dbWrite(class, "offset", offset)
    dispatch("OFFSET_CHANGED", offset)
  end

  --[[
  addon.CreateStanceButton = function(parent, offset, texture, anchor)
    local button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
    button.__offset = offset
    button.icon:SetTexture("Interface/Icons/"..texture)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", OnStanceButtonClick)
    subscribe("OFFSET_CHANGED", button, OnStanceButtonUpdate)
    if not anchor then
      button:SetPoint("TOPLEFT", 16, 34)
    else
      button:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
    end
    return button
  end
  ]]

  do
    local stances = {
      {class = "ROGUE", offset = 72,  icon = 'ability_stealth',            1, 2, 3},
      {class = "DRUID", offset = 97,  icon = 'ability_racial_bearform',    1, 2, 3, 4},
      {class = "DRUID", offset = 72,  icon = 'ability_druid_catform',      1, 2, 3, 4},
      {class = "DRUID", offset = 109, icon = 'spell_nature_forceofnature', 1}
    }
    addon.CreateStanceButtons = function(parent, class, ...)
      local buttons
      for i = 1, select("#", ...) do
        local stance = select(i, ...)
        if class == stance.class then
          local button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
          button.offset = stance.offset
          button.icon:SetTexture("Interface/Icons/"..stance.icon)
          button:RegisterForClicks("AnyUp")
          button:SetScript("OnClick", OnStanceButtonClick)
          subscribe("OFFSET_CHANGED", button, OnStanceButtonUpdate)
          rpush(button, unpack(stance))
          rpush(buttons or {}, button)
        end
      end
      addon.CreateStanceButtons = nil
      return buttons
    end

    addon.REF("stances", stances)
    addon.REF("CreateStanceButton", addon.CreateStanceButtons)
  end

  addon.REF("OnStanceButtonClick", OnStanceButtonClick)
  addon.REF("OnStanceButtonUpdate", OnStanceButtonUpdate)
end

do
  local SPELL = 1
  local MACRO = 2
  local ITEM = 3
  local function OnActionButtonDragStart(self)
    local modifier = getModifier()
    local class = select(2, UnitClass("player"))
    local kind, id = next(dbRead(class, self.__key, modifier), unpack)
  end

  local function OnActionButtonUpdate(self, class, modifier)
    --[[
    local kind, id = next(dbRead(class, self.__key, modifier), unpack)
    if kind == SPELL then
      self.icon:SetTexture(select(3, GetSpellInfo(id)))
    elseif kind == MACRO then
      self.icon:SetTexture(select(2, GetMacroInfo(id)))
    elseif kind == ITEM then
      self.icon:SetTexture(select(10, GetItemInfo(id)))
    end
    ]]
  end

  local function OnActionButtonReceiveDrag(self)
    local kind, arg1, _, arg2, arg3 = GetCursorInfo()
    local class = select(2, UnitClass("player"))
    local modifier = getModifier()
    ClearCursor()
    if kind == 'spell' then
      dbWrite(class, self.__key, modifier, { SPELL, arg3 or arg2 })
    elseif kind == 'macro' then
      dbWrite(class, self.__key, modifier, { MACRO, arg1 })
    elseif kind == 'item' then
      dbWrite(class, self.__key, modifier, { ITEM, arg1 })
    end
    OnActionButtonUpdate(self, class, modifier)
  end

  local function OnActionButtonClick(self, button)
    if button == "RightButton" then
      local class = select(2, UnitClass("player"))
      local stance = dbRead(class, self.__key, 'stance')
      dbWrite(class, self.__key, 'stance', (not stance) and true or nil)
      --dbWrite(class, 'stance', nil)
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
    end
  end

  addon.CreateActionButton = function(parent)
    local button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
    button:SetScript("OnDragStart", OnActionButtonDragStart)
    button:SetScript("OnReceiveDrag", OnActionButtonReceiveDrag)
    button:SetScript("OnClick", OnActionButtonClick)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("AnyUp")
    --subscribe("MODIFIER_CHANGED", button, OnActionButtonUpdate)
    --subscribe("OFFSET_CHANGED", button, OnActionButtonUpdate)
    return button
  end
end

