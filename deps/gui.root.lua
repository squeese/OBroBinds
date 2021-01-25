local _, addon = ...
local subscribe, dispatch, getModifier, dbRead = addon:get("subscribe", "dispatch", "getModifier", "dbRead")

subscribe("PLAYER_LOGIN", function(event, frame)
  frame.class = select(2, UnitClass("player"))
  frame.spec = GetSpecialization()
  frame.offset = 1
  dispatch("BIND_ACTIONS", frame.spec)
  return event:unsub():next(frame)
end)

subscribe("PLAYER_SPECIALIZATION_CHANGED", function(event, frame, ...)
  local spec = GetSpecialization()
  if spec ~= frame.spec then
    if frame.spec then
      local bindings = dbRead(nil, frame.spec)
      if bindings then
        for binding in pairs(bindings) do
          print("remove binding", binding)
          SetBinding(binding, nil)
        end
      end
    end
    frame.spec = spec
    frame.offset = 1
    dispatch("BIND_ACTIONS", frame.spec)
    return event:next(frame, ...)
  end
  print("stop")
  return event:stop()
end)

subscribe("OFFSET_CHANGED", function(event, frame, offset)
  frame.offset = offset ~= frame.offset and offset or 1
  return event:next(frame, offset)
end)

subscribe("BIND_ACTIONS", function(event, spec)
  local bindings = dbRead(nil, spec)
  if bindings then
    for binding, action in pairs(bindings) do
      dispatch("BIND_ACTION", binding, unpack(action))
    end
  end
  return event:next(spec)
end)

subscribe("BIND_ACTION", function(event, binding, kind, id)
  if kind == "spell" then
    local name = GetSpellInfo(id)
    SetBindingSpell(binding, name)
  elseif kind == "macro" then
    SetBindingMacro(binding, id)
  elseif kind == "item" then
    local name = GetItemInfo(id)
    SetBindingItem(binding, name)
  end
  return event:next(spec, kind, id)
end)

subscribe("TOGGLE_GUI", function(event, frame)
  frame:Hide()
  frame:SetFrameStrata("DIALOG")
  frame:SetSize(1, 1)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 270)
  frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    --edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16, -- 32,
    edgeSize = 16, -- 32,
    --insets = { left = 11, right = 12, top = 12, bottom = 11 }
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
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
  return event:unsub():next(frame)
end)

subscribe("TOGGLE_GUI", function(event, frame, ...)
  if frame:IsVisible() then
    frame:Hide()
  else
    frame:Show()
  end
  return event:next(frame, ...)
end)

subscribe("SHOW_GUI", function(event, frame)
  frame.offset = 1
  frame.modifier = getModifier()
  return event:next(frame)
end)

