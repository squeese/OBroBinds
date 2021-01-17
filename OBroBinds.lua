local _, addon = ...
local next, _, rpush, _, _, subscribe, dispatch, unsubscribe, dbWrite, dbRead, _, match = unpack(addon)

BINDING_HEADER_OBROBINDS = 'OBroBinds'
BINDING_NAME_TOGGLE_CONFIG = 'Toggle Config Panel'
function OBroBinds_Toggle()
  local frame = CreateFrame("frame", nil, UIParent, "BackdropTemplate")
  dispatch("INITIALIZE", frame, UnitClass("player"))
  dispatch("LAYOUT_CHANGED", addon.DEFAULT_KEYBOARD_LAYOUT)
  local open = false
  OBroBinds_Toggle = function()
    if not open then
      frame:Show()
      dispatch("PLAYER_SPECIALIZATION_CHANGED")
    else
      frame:Hide()
    end
    open = not open
    C_Timer.After(1, addon.REPORT)
  end
  OBroBinds_Toggle()
end

do -- TMP, open on loading
  local frame = CreateFrame("frame")
  frame:RegisterEvent("VARIABLES_LOADED")
  frame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("VARIABLES_LOADED")
    self:SetScript("OnEvent", nil)
    addon.REPORT()
    OBroBinds_Toggle()
  end)
end

subscribe("INITIALIZE", addon, function(self, frame)
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

  frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  frame:SetScript("OnEvent", function(_, ...)
    print("event", ...)
    dispatch(...)
  end)

  do -- dev
    local reset = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
    reset:SetSize(100, 32)
    reset:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0)
    reset:SetText("reset")
    reset:RegisterForClicks("AnyUp")
    reset:SetScript("OnClick", function()
      OBroBindsDB = nil
      ReloadUI()
    end)
  end

  -- addon.CreateStanceButtons(frame)
  -- addon.CreateStanceButtons = nil



  -- create the action buttons
  --[[
  do
  ]]

  unsubscribe("INITIALIZE", self, true)
end)

addon.REF("addon.INITIALIZE", addon.INITIALIZE)
