local _, addon = ...
local subscribe, dispatch = addon:get("subscribe", "dispatch")

local prev
local function panel(frame, text, func)
  local button = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
  button:SetSize(100, 32)
  button:SetText(text)
  button:RegisterForClicks("AnyUp")
  button:SetScript("OnClick", func)
  if not prev then
    button:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
  else
    button:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, 0)
  end
  prev = button
end

subscribe("TOGGLE_GUI", function(event, frame)
  panel(frame, "reset", function()
    print("RESET")
    OBroBindsDB = nil
    ReloadUI()
  end)
  panel(frame, "import", function()
    dispatch("IMPORT_BINDS", frame)
  end)
  panel(frame, "reload", ReloadUI)
  return event:unsub():next(frame)
end)

subscribe("VARIABLES_LOADED", function(event, ...)
  C_Timer.After(1, OBroBinds_Toggle)
  return event:unsub():next(...)
end)
