local _, addon = ...
local subscribe, dispatch = addon:get("subscribe", "dispatch")

subscribe("UPDATE_BINDINGS", function(event, frame, ...)
  print(event.key, "frame.bindings")
  return event:next(frame, ...)
end)

subscribe("VARIABLES_LOADED", function(event, frame, ...)
  print(event.key, "frame.class")
  print(event.key, "frame.spec")
  frame.class = select(2, UnitClass("player"))
  frame.spec = GetSpecialization()
  return event:unsub():next(frame, ...)
end)

subscribe("PLAYER_SPECIALIZATION_CHANGED", function(event, frame, ...)
  print(event.key, "frame.spec")
  frame.spec = GetSpecialization()
  return event:next(frame, ...)
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
  print(event.key, "root")
  return event:next(frame)
end)

subscribe("HIDE_GUI", function(event, frame)
  print(event.key, "root")
  return event:next(frame)
end)
