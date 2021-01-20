local _, addon = ...
local subscribe, dispatch, getModifier = addon:get("subscribe", "dispatch", "getModifier")

subscribe("VARIABLES_LOADED", function(event, frame, ...)
  print(event.key, "frame.class")
  print(event.key, "frame.spec")
  frame.class = select(2, UnitClass("player"))
  frame.spec = GetSpecialization()
  frame.offset = 1
  return event:unsub():next(frame, ...)
end)

subscribe("PLAYER_SPECIALIZATION_CHANGED", function(event, frame, ...)
  print(event.key, "frame.spec")
  frame.spec = GetSpecialization()
  return event:next(frame, ...)
end)

subscribe("STANCE_OFFSET_CHANGED", function(event, frame, offset)
  frame.offset = offset ~= frame.offset and offset or 1
  print(event.key, "stance.offset", frame.offset)
  return event:next(frame, offset)
end)

subscribe("TOGGLE_GUI", function(event, frame)
  print(event.key, "frame.onshow")
  print(event.key, "frame.onhide")
  frame:Hide()
  frame:SetFrameStrata("DIALOG")
  frame:SetSize(1, 1)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 32)
  frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
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
  print(event.key, "root")
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
