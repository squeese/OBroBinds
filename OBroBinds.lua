local _A = select(2, ...)
local listen, release, map, read, write, push = _A.listen, _A.release, _A.map, _A.read, _A.write, _A.push
local frame = CreateFrame("frame", "OBroBindsFrame", UIParent, "OBroBindsFrameTemplate")
frame.dispatch = _A.dispatch
frame:RegisterEvent("PLAYER_LOGIN")

listen("PLAYER_LOGIN", function(e, frame)
  frame.offset = 1
  frame.class = select(2, UnitClass("player"))
  frame.spec = GetSpecialization()
  frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  for binding, action in map(nil, OBroBindsDB, frame.class, frame.spec) do
    frame:dispatch("OVERRIDE_SET", false, binding, action[1], action[2], action[3], action[4])
  end
  if read(OBroBindsDB, 'GUI', 'open') then
    frame:Show()
  end
  return e:once(frame)
end)

listen("PLAYER_SPECIALIZATION_CHANGED", function(e, frame)
  ClearOverrideBindings(frame)
  frame.spec = GetSpecialization()
  for binding, action in map(OBroBindsDB, frame.class, frame.spec) do
    frame:dispatch("OVERRIDE_SET", false, binding, action[1], action[2], action[3], action[4])
  end
  return e:next(frame)
end)

listen("OVERRIDE_SET", _A.SetOverrideHandler)

listen("GUI_TOGGLE", function(e, frame)
  OBroBindsDB = write(OBroBindsDB, 'GUI', 'open', not read(OBroBindsDB, 'GUI', 'open') and true or nil)
  frame[frame:IsVisible() and 'Hide' or 'Show'](frame)
  return e:next(frame)
end)

do
  local OnUpdate = _A.OnUpdateModifierHandler
  local GetOverride = _A.GetOverrideHandler
  local DelOverride = _A.DelOverrideHandler
  local PickupOverride = _A.PickupOverrideHandler
  local ReceiveOverride = _A.ReceiveOverrideHandler
  local PromoteOverride = _A.PromoteOverrideHandler
  local LockOverride = _A.LockOverrideHandler
  local ActionBarSlotChanged = _A.ActionBarSlotChangedHandler
  local UpdateTooltip = _A.UpdateTooltipHandler
  local RefreshTooltip = _A.RefreshTooltipHandler
  local OnHide
  local function OnShow(e, frame)
    frame.modifier = (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")
    frame:SetScript("OnUpdate", OnUpdate)
    frame:RegisterEvent("UPDATE_BINDINGS")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("UPDATE_MACROS")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    listen("OVERRIDE_GET", GetOverride)
    listen("OVERRIDE_DEL", DelOverride)
    listen("OVERRIDE_PICKUP", PickupOverride)
    listen("OVERRIDE_RECEIVE", ReceiveOverride)
    listen("OVERRIDE_PROMOTE", PromoteOverride)
    listen("OVERRIDE_LOCK", LockOverride)
    listen("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
    listen("SHOW_TOOLTIP", UpdateTooltip)
    listen("OFFSET_CHANGED", RefreshTooltip)
    listen("UPDATE_BINDINGS", RefreshTooltip)
    listen("MODIFIER_CHANGED", RefreshTooltip)
    listen("PLAYER_TALENT_UPDATE", RefreshTooltip)
    listen("PLAYER_SPECIALIZATION_CHANGED", RefreshTooltip)
    listen("GUI_HIDE", OnHide)
    return e:once(frame)
  end
  function OnHide(e, frame)
    frame:SetScript("OnUpdate", nil)
    frame:UnregisterEvent("UPDATE_BINDINGS")
    frame:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:UnregisterEvent("UPDATE_MACROS")
    frame:UnregisterEvent("PLAYER_TALENT_UPDATE")
    frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    release("OVERRIDE_GET", GetOverride)
    release("OVERRIDE_DEL", DelOverride)
    release("OVERRIDE_PICKUP", PickupOverride)
    release("OVERRIDE_RECEIVE", ReceiveOverride)
    release("OVERRIDE_PROMOTE", PromoteOverride)
    release("OVERRIDE_LOCK", LockOverride)
    release("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
    release("SHOW_TOOLTIP", UpdateTooltip)
    release("OFFSET_CHANGED", RefreshTooltip)
    release("UPDATE_BINDINGS", RefreshTooltip)
    release("MODIFIER_CHANGED", RefreshTooltip)
    release("PLAYER_TALENT_UPDATE", RefreshTooltip)
    release("PLAYER_SPECIALIZATION_CHANGED", RefreshTooltip)
    listen("GUI_SHOW", OnShow)
    return e:once(frame)
  end
  listen("GUI_SHOW", OnShow)
end

do
  local CreateButton = _A.CreateStanceButton
  local UpdateButtons = _A.UpdateStanceButtonsHandler
  listen("GUI_SHOW", function(e, frame)
    frame.offset = 1
    frame.stances = nil 
    if frame.class == "ROGUE" then
      write(frame, 'stances', push, CreateButton(frame, 73, 'ability_stealth', 1, 2, 3))
    elseif true or frame.class == "DRUID" then
      write(frame, 'stances', push, CreateButton(frame, 97,  'ability_racial_bearform',    1, 2, 3, 4))
      write(frame, 'stances', push, CreateButton(frame, 73,  'ability_druid_catform',      1, 2, 3, 4))
      write(frame, 'stances', push, CreateButton(frame, 109, 'spell_nature_forceofnature', 1))
    end
    if frame.stances ~= nil then
      local OnHide
      local function OnShow(e, frame)
        listen("GUI_HIDE", OnHide)
        listen("OFFSET_CHANGED", UpdateButtons)
        listen("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
        return push(e, UpdateButtons):once(frame, frame.offset)
      end
      function OnHide(e, frame)
        release("OFFSET_CHANGED", UpdateButtons)
        release("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
        listen("GUI_SHOW", OnShow)
        return e:once(frame)
      end
      push(e, OnShow)
    end
    return e:once(frame)
  end)
end

do
  local UpdateLayout = _A.UpdateOverrideLayoutHandler
  local UpdateBindings = _A.UpdateOverrideBindingsHandler
  local UpdateButtons = _A.UpdateOverrideButtonsHandler
  local layout = _A.DEFAULT_KEYBOARD_LAYOUT
  listen("GUI_SHOW", function(e, frame)
    frame.mainbar = {}
    frame.buttons = {}
    local OnHide
    local function OnShow(e, frame)
      listen("UPDATE_LAYOUT", UpdateLayout)
      listen("UPDATE_BINDINGS", UpdateBindings)
      listen("UPDATE_BINDINGS", UpdateButtons)
      listen("UPDATE_MACROS", UpdateButtons)
      listen("OFFSET_CHANGED", UpdateButtons)
      listen("MODIFIER_CHANGED", UpdateButtons)
      listen("PLAYER_TALENT_UPDATE", UpdateButtons)
      listen("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
      listen("GUI_HIDE", OnHide)
      return push(e, UpdateButtons, UpdateBindings):once(frame)
    end
    function OnHide(e, frame)
      release("UPDATE_LAYOUT", UpdateLayout)
      release("UPDATE_BINDINGS", UpdateBindings)
      release("UPDATE_BINDINGS", UpdateButtons)
      release("UPDATE_MACROS", UpdateButtons)
      release("OFFSET_CHANGED", UpdateButtons)
      release("MODIFIER_CHANGED", UpdateButtons)
      release("PLAYER_TALENT_UPDATE", UpdateButtons)
      release("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
      listen("GUI_SHOW", OnShow)
      return e:once(frame)
    end
    return push(e, OnShow, UpdateLayout):once(frame, layout)
  end)
end

do
  local initialize, dropdown = _A.InitializeDropdownHandler
  local function UpdateDropdown(e, frame, button)
    dropdown.info.arg1 = button
    ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0, "root")
    return e:next(frame, button)
  end
  listen("GUI_SHOW", function(e, frame)
    dropdown = CreateFrame("frame", nil, UIParent, "UIDropDownMenuTemplate")
    dropdown.info = UIDropDownMenu_CreateInfo()
    dropdown.displayMode = "MENU"
    dropdown.initialize = initialize
    local OnHide
    local function OnShow(e, frame)
      listen("SHOW_DROPDOWN", UpdateDropdown)
      listen("GUI_HIDE", OnHide)
      return e:once(frame)
    end
    function OnHide(e, frame)
      release("SHOW_DROPDOWN", UpdateDropdown)
      listen("GUI_SHOW", OnShow)
      return e:once(frame)
    end
    return push(e, OnShow):once(frame)
  end)
end
