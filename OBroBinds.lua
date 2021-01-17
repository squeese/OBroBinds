local _, addon = ...
local next, _, rpush, _, _, _, dispatch, _, dbWrite, dbRead = unpack(addon)
local InitializeGUI, UpdateStanceButtons, UpdateActionButtons

BINDING_HEADER_OBROBINDS = 'OBroBinds'
BINDING_NAME_TOGGLE_CONFIG = 'Toggle Config Panel'
function OBroBinds_Toggle()
  -- local class, stances = addon.FinalizeClass()
  local root = InitializeGUI()
  -- dispatch("SPEC_CHANGED", GetSpecialization())

  local open = false
  OBroBinds_Toggle = function()
    if not open then
      root:Show()
      -- dbWrite(class, "offset", nil)
      -- next(addon, UpdateStanceButtons, nil)
      -- next(addon, UpdateActionButtons, addon.DEFAULT_KEYBOARD_LAYOUT)
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

  do


    local stanceButtons = addon.CreateStanceButtons(frame, select(2, UnitClass("player")),
      {class = "ROGUE", offset = 72,  icon = 'ability_stealth',            1, 2, 3},
      {class = "DRUID", offset = 97,  icon = 'ability_racial_bearform',    1, 2, 3, 4},
      {class = "DRUID", offset = 72,  icon = 'ability_druid_catform',      1, 2, 3, 4},
      {class = "DRUID", offset = 109, icon = 'spell_nature_forceofnature', 1})

    local stanceButtons = next(nil, CreateStanceButton, class,

    if stanceButtons then

      local function match(val, arg, ...)
        if val == arg then return true end
        return select("#", ...) > 0 and next(val, match, ...) or false
      end

      local function reset(button, anchor)
        button:Show()
        button:ClearAllPoints()
        if not anchor then
          button:SetPoint("TOPLEFT", 16, 34)
        else
          button:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
        end
        return button
      end

      local offset = dbRead(nil, "offset")
      local spec, prev, valid = GetSpecialization()
      for _, button in ipairs(stanceButtons) do
        if match(spec, unpack(button)) then
          button:Show()
          prev = reset(button, prev)
          valid = valid or not offset or offset == button.__offset
        else
          button:Hide()
        end
      end

      print("offset", offset, "valid", valid)

      -- next(stanceButtons, filterSpec, )

      --[[
      local function reset(self)
        if not self then return end
        self.cursor = 0
        return self
      end
      local buttons
      --subscribe("SPECIALIZATON_CHANGED", function(spec)
        next(buttons, reset)
        local spec = GetSpecialization()

        --next(buttons, filter, specc)
      --end)
    ]]
    end
  end

  -- create the stance buttons and an update handler for when the player changes specc
  -- atm, only rogues and druid's have stance buttons
  --[[
  if class ~= "ROGUE" and class ~= "DRUID" then
    local CreateStanceButtons, current, buttons = addon.CreateStanceButtons
    function UpdateStanceButtons(_, specc)
      if specc == current then return end
      current = specc
      buttons = next(buttons, CreateStanceButtons, frame, class, specc)
    end

      function UpdateStanceButtons()
        local offset = dbRead(class, "stance")
        if offset and not (offset == 72) then
        end
      end

    if class == "ROGUE" then

    elseif class == "DRUID" then
      local stanceButtonBear = addon.CreateStanceButton(frame, 97, 'ability_racial_bearform', nil)
      local stanceButtonCat = addon.CreateStanceButton(frame, 72, 'ability_druid_catform', stanceButtonBear)
      local stanceButtonBoom = addon.CreateStanceButton(frame, 109, 'spell_nature_forceofnature', stanceButtonCat)
      addon.CreateStanceButton = nil

      function UpdateStanceButtons()
        local offset = dbRead(class, "stance")
        local specc = GetSpecialization()
        if offset and not (offset == 97 or offset == 72 or (specc == 1 and offset == 109)) then
          dbWrite(class, "offset", nil)
          dispatch("OFFSET_CHANGED", nil)
        end

        OnStanceButtonUpdate(stanceButtonBear, offset)
        OnStanceButtonUpdate(stanceButtonCat, offset)
        stanceButtonBear
        if GetSpecialization() == 1 then
          if not stanceButtonBoom then
            addon.CreateStanceButton = nil -- no need to this one, let GC collect it
          else
            stanceButtonBoom:Show()
            subscribe("OFFSET_CHANGED", stanceButtonBoom)
          end
        elseif stanceButtonBoom then
          if stanceButtonBoom.Border:IsVisible() then
            dispatch("OFFSET_CHANGED", nil)
          end
          unsubscribe("STANCE_OFFSET", stanceButtonBoom)
          stanceButtonBoom:Hide()
        end
      end
    end

    addon.CreateStanceButton = nil
  end
  addon.CreateStanceButtons = nil
  ]]

  -- create the action buttons
  --[[
  do
    local current, buttons
    local rcat, _, _, _, _, _, _, init, cleanup = select(5, unpack(addon))
    function UpdateActionButtons(_, layout)
      if current == layout then return end
      current = layout
      buttons = next(buttons or {}, init, frame, rcat, layout, cleanup)
    end
  end
  ]]

  -- remove refence to this function and let the GC collect it, since it's only run once
  InitializeGUI = nil

  return frame
end

addon.REF("InitializeGUI", InitializeGUI)
