local _, addon = ...
local subscribe, dispatch, getModifier, dbRead, dbWrite = addon:get("subscribe", "dispatch", "getModifier", "dbRead", "dbWrite")

subscribe("PLAYER_LOGIN", function(e, frame)
  dbWrite('GUI', 'open', true)
  frame.class = select(2, UnitClass("player"))
  frame.spec = GetSpecialization()
  frame.offset = 1
  frame.stances = dispatch("GET_CLASS_STANCES", frame)

  frame.stances = {
    {class = "ROGUE", offset = 73,  icon = 'ability_stealth',            1, 2, 3},
    {class = "DRUID", offset = 97,  icon = 'ability_racial_bearform',    1, 2, 3, 4},
    {class = "DRUID", offset = 73,  icon = 'ability_druid_catform',      1, 2, 3, 4},
    {class = "DRUID", offset = 109, icon = 'spell_nature_forceofnature', 1 }}
  for index = #frame.stances, 1, -1 do
    if frame.class ~= stances[index].class then
      table.remove(frame.stances, index)
    end
  end
  dispatch("SET_OVERRIDE_BINDINGS", frame)
  return e:unsub():next(frame)
end)

subscribe("PLAYER_LOGIN", addon:take(""))



subscribe("PLAYER_SPECIALIZATION_CHANGED", function(e, frame, ...)
  local spec = GetSpecialization()
  if spec ~= frame.spec then
    if frame.spec then
      ClearOverrideBindings(frame)
    end
    frame.spec = spec
    frame.offset = 1
    dispatch("SET_OVERRIDE_BINDINGS", frame)
    return e:next(frame, ...)
  end
  return e:stop()
end)

subscribe("OFFSET_CHANGED", function(e, frame, offset)
  frame.offset = offset ~= frame.offset and offset or 1
  return e:next(frame, offset)
end)

subscribe("SET_OVERRIDE_BINDINGS", function(e, frame)
  local bindings = dbRead(nil, frame.spec)
  if bindings then
    for binding, action in pairs(bindings) do
      dispatch("SET_OVERRIDE_BIND", frame, binding, unpack(action))
    end
  end
  return e:next(frame)
end)

subscribe("SET_OVERRIDE_BIND", function(e, frame, binding, kind, id)
  if kind == "spell" then
    local name = GetSpellInfo(id)
    SetOverrideBindingSpell(frame, false, binding, name)
    --print("SPELL", name)

  elseif kind == "macro" then
    SetOverrideBindingMacro(frame, false, binding, id)
    --print("MACRO", id)

  elseif kind == "item" then
    local name = GetItemInfo(id)
    SetOverrideBindingItem(frame, false, binding, name)

  end
  return e:next(frame, binding, kind, id)
end)

subscribe("TOGGLE_GUI", function(e, frame)
  frame:Hide()
  frame:SetFrameStrata("DIALOG")
  frame:SetSize(1, 1)
  frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16, -- 32,
    edgeSize = 16, -- 32,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.75)
  frame:SetScript("OnShow", function(self)
    dispatch("SHOW_GUI", self)
  end)
  frame:SetScript("OnHide", function(self)
    dispatch("HIDE_GUI", self)
  end)
  local elapsed = 0
  frame:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed < 0.1 then return end
    local modifier = getModifier()
    if modifier ~= self.modifier then
      self.modifier = modifier
      dispatch("MODIFIER_CHANGED", self)
    end
    elapsed = 0
  end)

  local header = CreateFrame("frame", nil, frame, "DialogHeaderTemplate")
  header:SetPoint("TOP", 0, 18)
  header.Text:SetText("OBroBinds")
  header:RegisterForDrag("LeftButton")
  header:EnableMouse(true)
  header:SetScript("OnDragStart", function(self)
    self:GetParent():StartMoving()
  end)
  header:SetScript("OnDragStop", function(self)
    self:GetParent():StopMovingOrSizing()
  end)

  return e:unsub():next(frame)
end)

subscribe("TOGGLE_GUI", function(e, frame, ...)
  if frame:IsVisible() then
    dbWrite('GUI', 'open', nil)
    frame:Hide()
  else
    dbWrite('GUI', 'open', true)
    frame:Show()
  end
  return e:next(frame, ...)
end)

subscribe("SHOW_GUI", function(e, frame)
  frame.offset = 1
  frame.modifier = getModifier()
  return e:next(frame)
end)

subscribe("SHOW_TOOLTIP", function(e, frame, button)
  print("showtooltip", button.key)
  return e:next(frame, button)
end)
