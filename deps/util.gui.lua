local _, addon = ...
local next, _, rpush, _, _, subscribe, dispatch, unsubscribe, dbWrite, dbRead, getModifier = unpack(addon)

do
  local function OnStanceButtonClick(self)
    dispatch("STANCE_OFFSET", self.Border:IsVisible() and 1 or self.__offset)
  end

  local function OnStanceButtonUpdate(self, offset)
    next(self.Border, self.__offset == offset and self.Border.Show or self.Border.Hide)
  end

  addon.CreateStanceButton = function(parent, offset, texture, anchor)
    local button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
    button.__offset = offset
    button.icon:SetTexture("Interface/Icons/"..texture)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", OnStanceButtonClick)
    subscribe("STANCE_OFFSET", button, OnStanceButtonUpdate)
    if not anchor then
      button:SetPoint("TOPLEFT", 16, 34)
    else
      button:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
    end
    return button
  end

  addon.REF("OnStanceButtonClick", OnStanceButtonClick)
  addon.REF("OnStanceButtonUpdate", OnStanceButtonUpdate)
  addon.REF("CreateStanceButton", addon.CreateStanceButton)
end

do
  local function OnActionButtonDragStart(self)
    local modifier = getModifier()
    local class = select(2, UnitClass("player"))
    local kind, id = next(dbRead(class, self.__key, modifier), unpack)
  end

  local function OnActionButtonReceiveDrag(self)
    local kind, arg1, _, arg2, arg3 = GetCursorInfo()
    local class = select(2, UnitClass("player"))
    ClearCursor()
    if kind == 'spell' then
      self.icon:SetTexture(select(3, GetSpellInfo(arg3 or arg2)))
      dbWrite(class, self.__key, getModifier(), { kind, arg3 or arg2 })
    elseif kind == 'macro' then
      self.icon:SetTexture(select(2, GetMacroInfo(arg1)))
      dbWrite(class, self.__key, getModifier(), { kind, arg1 })
    elseif kind == 'item' then
      self.icon:SetTexture(select(10, GetItemInfo(arg1)))
      dbWrite(class, self.__key, getModifier(), { kind, arg1 })
    end
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
    return button
  end
end

