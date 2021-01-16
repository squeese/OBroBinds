local _, addon = ...
local next = unpack(addon)
local InitializeGUI, UpdateStanceButtons, UpdateActionButtons

BINDING_HEADER_OBROBINDS = 'OBroBinds'
BINDING_NAME_TOGGLE_CONFIG = 'Toggle Config Panel'
function OBroBinds_Toggle()
  local root = InitializeGUI()
  local open = false
  OBroBinds_Toggle = function()
    if not open then
      root:Show()
      next(addon, UpdateStanceButtons)
      next(addon, UpdateActionButtons, addon.DEFAULT_KEYBOARD_LAYOUT)
    else
      root:Hide()
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

function InitializeGUI()
  local subscribe, dispatch, unsubscribe = select(6, unpack(addon))

  -- create and style the main window
  local frame = CreateFrame("frame", nil, UIParent, "BackdropTemplate")
  frame:SetFrameStrata("DIALOG")
  frame:SetSize(750, 290)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 32)
  frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })

  -- create the stance buttons and an update handler for when the player changes specc
  do
    local class = select(2, UnitClass("player"))
    if class == "ROGUE" then
      CreateStanceButton(frame, 72, "ability_stealth", nil)
      addon.CreateStanceButton = nil

    elseif class == "DRUID" then
      local stanceButtonBear = addon.CreateStanceButton(frame, 97, 'ability_racial_bearform', nil)
      local stanceButtonCat = addon.CreateStanceButton(frame, 72, 'ability_druid_catform', stanceButtonBear)
      local stanceButtonBoom = nil
      function UpdateStanceButtons()
        if GetSpecialization() == 1 then
          if not stanceButtonBoom then
            stanceButtonBoom = addon.CreateStanceButton(frame, 109, 'spell_nature_forceofnature', stanceButtonCat)
            addon.CreateStanceButton = nil -- no need to this one, let GC collect it
          else
            stanceButtonBoom:Show()
            subscribe("STANCE_OFFSET", stanceButtonBoom)
          end
        elseif stanceButtonBoom then
          if stanceButtonBoom.Border:IsVisible() then
            dispatch("STANCE_OFFSET", 1)
          end
          unsubscribe("STANCE_OFFSET", stanceButtonBoom)
          stanceButtonBoom:Hide()
        end
      end
    else
      addon.CreateStanceButton = nil
    end
  end

  -- create the action buttons
  do
    local current, buttons
    local rcat, _, _, _, _, _, _, init, cleanup = select(5, unpack(addon))
    function UpdateActionButtons(_, layout)
      if current == layout then return end
      current = layout
      buttons = next(buttons or {}, init, frame, rcat, layout, cleanup)
    end
  end

  -- remove refence to this function and let the GC collect it, since it's only run once
  InitializeGUI = nil

  return frame
end

addon.REF("InitializeGUI", InitializeGUI)
