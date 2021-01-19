local _, addon = ...
local next, _, rpush, _, _, subscribe, dispatch, unsubscribe, write, read, dbWrite, dbRead, getModifier, match = unpack(addon)



BINDING_HEADER_OBROBINDS = 'OBroBinds'
BINDING_NAME_TOGGLE_CONFIG = 'Toggle Config Panel'
function OBroBinds_Toggle()
  local frame = CreateFrame("frame", nil, UIParent, "BackdropTemplate")
  dispatch("INITIALIZE", frame, UnitClass("player"))
  dispatch("LAYOUT_CHANGED", addon.DEFAULT_KEYBOARD_LAYOUT)

  print("?", GetBindingKey("SPELL Rejuvenation"))

  --C_Timer.After(2, function()
    --local spell = "Rejuvenation"
    ---- SetBindingSpell("5", spell)
    ---- SaveBindings(2)

    --print("GetCurrentBindingSet", GetCurrentBindingSet())
    --print(5, GetBindingAction("5", false))
    --print(5, GetBindingAction("5", true))

    --print(GetSpellInfo(spell))
  --end)

      -- print("?", )


  local elapsed, current = 0, getModifier()
  dispatch("MODIFIER_CHANGED", current)
  frame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed > 0.1 then
      elapsed = 0
      local modifier = getModifier()
      if current ~= modifier then
        current = modifier
        dispatch("MODIFIER_CHANGED", current)
      end
    end
  end)

  --C_Timer.After(2, function()
    --local mods = {}
    --if IsAltKeyDown() then rpush(mods, "ALT") end
    --if IsControlKeyDown() then rpush(mods, "CTRL") end
    --if IsShiftKeyDown() then rpush(mods, "SHIFT") end
    --rpush(mods, "1")
    --local binding = strjoin("-", unpack(mods))
    --print("binding", binding)
    --local action = GetBindingAction(binding)
    --print("action", action)
  --end)

  --frame:EnableKeyboard(true)
  --frame:SetScript("OnKeyDown", function(_, key)
    --frame:SetScript("OnKeyDown", nil)
    --frame:EnableKeyboard(false)
  --end)

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
