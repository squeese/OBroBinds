local _, addon = ...
local next, _, rpush, _, _, subscribe, dispatch, unsubscribe, write, read, dbWrite, dbRead, getModifier, match = unpack(addon)

-- GetCurrentBindingSet
-- GetBindingKey
-- GetBindingAction("5")
-- SetBindingSpell("5", "Rejuvenation")
-- GetSpellInfo(spell)
-- GetKeyFromBinding(binding)

BINDING_HEADER_OBROBINDS = 'OBroBinds'
BINDING_NAME_TOGGLE_CONFIG = 'Toggle Config Panel'
function OBroBinds_Toggle()
  local frame = CreateFrame("frame", nil, UIParent, "BackdropTemplate")
  dispatch("INITIALIZE", frame, UnitClass("player"))
  dispatch("LAYOUT_CHANGED", addon.DEFAULT_KEYBOARD_LAYOUT)

  local open = false
  OBroBinds_Toggle = function()
    if not open then
      elapsed = 0
      frame:Show()
      dispatch("PLAYER_SPECIALIZATION_CHANGED")
    else
      frame:Hide()
      frame:SetScript("OnUpdate", nil)
    end
    open = not open
    addon.REPORT()
  end
  C_Timer.After(1, OBroBinds_Toggle)
end

do -- TMP, open on loading
  local frame = CreateFrame("frame")
  frame:RegisterEvent("VARIABLES_LOADED")
  frame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("VARIABLES_LOADED")
    self:SetScript("OnEvent", nil)
    OBroBinds_Toggle()
  end)
end

subscribe("INITIALIZE", addon, function(self, frame)
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
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  end)
  frame:SetScript("OnEvent", function(_, ...)
    print("event", ...)
    dispatch(...)
  end)
  frame:SetScript("OnHide", function(self)
    self:UnregisterAllEvents()
  end)

  do
    local elapsed, pAlt, pCtrl, pShift = 0
    dispatch("MODIFIER_CHANGED", (pAlt and "ALT-" or "")..(pCtrl and "CTRL-" or "")..(pShift and "SHIFT-" or ""))
    frame:SetScript("OnUpdate", function(_, delta)
      elapsed = elapsed + delta
      if elapsed > 0.1 then
        elapsed = 0
        local nAlt, nCtrl, nShift = IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
        if pAlt == nAlt and pCtrl == nCtrl and pShift == nShift then return end
        pAlt, pCtrl, pShift = nAlt, nCtrl, nShift
        dispatch("MODIFIER_CHANGED", (pAlt and "ALT-" or "")..(pCtrl and "CTRL-" or "")..(pShift and "SHIFT-" or ""))
      end
    end)
  end

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

    local reload = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
    reload:SetSize(100, 32)
    reload:SetPoint("RIGHT", reset, "LEFT", -16, 0)
    reload:SetText("reload")
    reload:RegisterForClicks("AnyUp")
    reload:SetScript("OnClick", function()
      ReloadUI()
    end)

    local scan = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
    scan:SetSize(100, 32)
    scan:SetPoint("RIGHT", reload, "LEFT", -16, 0)
    scan:SetText("scan")
    scan:RegisterForClicks("AnyUp")
    scan:SetScript("OnClick", function()
      dispatch("SCAN")
    end)
  end

  unsubscribe("INITIALIZE", self, true)
end)

addon.REF("addon.INITIALIZE", addon.INITIALIZE)
