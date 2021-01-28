local _A = select(2, ...)
local listen, release, read, write, push = _A.listen, _A.release, _A.read, _A.write, _A.push
local frame = CreateFrame("frame", "OBroBindsFrame", UIParent, "OBroBindsFrameTemplate")
frame.dispatch = _A.dispatch
frame:RegisterEvent("PLAYER_LOGIN")

listen("PLAYER_LOGIN", function(e, frame)
  frame.class = select(2, UnitClass("player"))
  frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  frame:dispatch("PLAYER_SPECIALIZATION_CHANGED")
  frame[read(OBroBindsDB, 'GUI', 'open') and 'Show' or 'Hide'](frame)
  --SetBinding("5", "SPELL Divine Star")
  --SaveBindings(GetCurrentBindingSet())
  setmetatable(_A, {__mode = 'v'})
  collectgarbage("collect")
  setmetatable(_A, nil)
  return e:once(frame)
end)

listen("PLAYER_SPECIALIZATION_CHANGED", _A.SetAllOverridesHandler)
listen("OVERRIDE_SET", _A.SetOverrideHandler)

listen("GUI_TOGGLE", function(e, frame)
  OBroBindsDB = write(OBroBindsDB, 'GUI', 'open', not read(OBroBindsDB, 'GUI', 'open') and true or nil)
  frame[frame:IsVisible() and 'Hide' or 'Show'](frame)
  return e:next(frame)
end)

do
  local UpdateStanceButtons = _A.UpdateStanceButtonsHandler
  local UpdateLayout = _A.UpdateOverrideLayoutHandler
  local UpdateBindings = _A.UpdateOverrideBindingsHandler
  local UpdateButtons = _A.UpdateOverrideButtonsHandler
  local GetOverride = _A.GetOverrideHandler
  local DelOverride = _A.DelOverrideHandler
  local PickupOverride = _A.PickupOverrideHandler
  local ReceiveOverride = _A.ReceiveOverrideHandler
  local PromoteOverride = _A.PromoteOverrideHandler
  local LockOverride = _A.LockOverrideHandler
  local ActionBarSlotChanged = _A.ActionBarSlotChangedHandler
  local UpdateTooltip = _A.UpdateTooltipHandler
  local RefreshTooltip = _A.RefreshTooltipHandler
  local UpdateDropdown = _A.UpdateDropdownHandler
  local UpdateUnknownSpells = _A.UpdateUnknownSpellsHandler
  local OnHide
  local function OnShow(e, frame)
    frame:RegisterEvent("UPDATE_BINDINGS")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("UPDATE_MACROS")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    listen("UPDATE_LAYOUT", UpdateLayout)
    listen("OVERRIDE_GET", GetOverride)
    listen("OVERRIDE_DEL", DelOverride)
    listen("OVERRIDE_PICKUP", PickupOverride)
    listen("OVERRIDE_RECEIVE", ReceiveOverride)
    listen("OVERRIDE_PROMOTE", PromoteOverride)
    listen("OVERRIDE_LOCK", LockOverride)
    listen("UPDATE_BINDINGS", UpdateBindings)
    listen("UPDATE_BINDINGS", UpdateButtons)
    listen("UPDATE_BINDINGS", RefreshTooltip)
    listen("OFFSET_CHANGED", UpdateStanceButtons)
    listen("OFFSET_CHANGED", UpdateButtons)
    listen("OFFSET_CHANGED", RefreshTooltip)
    listen("UPDATE_MACROS", UpdateButtons)
    listen("MODIFIER_CHANGED", UpdateButtons)
    listen("MODIFIER_CHANGED", RefreshTooltip)
    listen("PLAYER_TALENT_UPDATE", UpdateUnknownSpells)
    listen("PLAYER_TALENT_UPDATE", UpdateButtons)
    listen("PLAYER_TALENT_UPDATE", RefreshTooltip)
    listen("UPDATE_MACROS", UpdateButtons)
    listen("PLAYER_SPECIALIZATION_CHANGED", UpdateUnknownSpells)
    listen("PLAYER_SPECIALIZATION_CHANGED", UpdateStanceButtons)
    listen("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
    listen("PLAYER_SPECIALIZATION_CHANGED", RefreshTooltip)
    listen("SHOW_TOOLTIP", UpdateTooltip)
    listen("SHOW_DROPDOWN", UpdateDropdown)
    listen("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
    listen("GUI_HIDE", OnHide)
    return push(e, UpdateButtons, UpdateBindings, UpdateStanceButtons):once(frame)
  end
  function OnHide(e, frame)
    frame:UnregisterEvent("UPDATE_BINDINGS")
    frame:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:UnregisterEvent("UPDATE_MACROS")
    frame:UnregisterEvent("PLAYER_TALENT_UPDATE")
    frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    release("UPDATE_LAYOUT", UpdateLayout)
    release("OVERRIDE_GET", GetOverride)
    release("OVERRIDE_DEL", DelOverride)
    release("OVERRIDE_PICKUP", PickupOverride)
    release("OVERRIDE_RECEIVE", ReceiveOverride)
    release("OVERRIDE_PROMOTE", PromoteOverride)
    release("OVERRIDE_LOCK", LockOverride)
    release("UPDATE_BINDINGS", UpdateBindings)
    release("UPDATE_BINDINGS", UpdateButtons)
    release("UPDATE_BINDINGS", RefreshTooltip)
    release("OFFSET_CHANGED", UpdateStanceButtons)
    release("OFFSET_CHANGED", UpdateButtons)
    release("OFFSET_CHANGED", RefreshTooltip)
    release("UPDATE_MACROS", UpdateButtons)
    release("MODIFIER_CHANGED", UpdateButtons)
    release("MODIFIER_CHANGED", RefreshTooltip)
    release("PLAYER_TALENT_UPDATE", UpdateUnknownSpells)
    release("PLAYER_TALENT_UPDATE", UpdateButtons)
    release("PLAYER_TALENT_UPDATE", RefreshTooltip)
    release("UPDATE_MACROS", UpdateButtons)
    release("PLAYER_SPECIALIZATION_CHANGED", UpdateUnknownSpells)
    release("PLAYER_SPECIALIZATION_CHANGED", UpdateStanceButtons)
    release("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
    release("PLAYER_SPECIALIZATION_CHANGED", RefreshTooltip)
    release("SHOW_TOOLTIP", UpdateTooltip)
    release("SHOW_DROPDOWN", UpdateDropdown)
    release("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
    listen("GUI_SHOW", OnShow)
    collectgarbage("collect")
    return e:once(frame)
  end
  local OnUpdate = _A.OnUpdateModifierHandler
  local CreateStanceButton = _A.CreateStanceButton
  local layout = _A.DEFAULT_KEYBOARD_LAYOUT
  listen("GUI_SHOW", function(e, frame)
    frame:SetScript("OnUpdate", OnUpdate)
    frame.modifier = (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")
    frame.mainbar = {}
    frame.buttons = {}
    frame.offset = 1
    frame.stances = nil 
    if frame.class == "ROGUE" then
      write(frame, 'stances', push, CreateStanceButton(frame, 73, 'ability_stealth', 1, 2, 3))
    elseif frame.class == "DRUID" then
      write(frame, 'stances', push, CreateStanceButton(frame, 97,  'ability_racial_bearform',    1, 2, 3, 4))
      write(frame, 'stances', push, CreateStanceButton(frame, 73,  'ability_druid_catform',      1, 2, 3, 4))
      write(frame, 'stances', push, CreateStanceButton(frame, 109, 'spell_nature_forceofnature', 1))
    else
      UpdateStanceButtons = nil
    end
    return push(e, OnShow, UpdateLayout):once(frame, layout)
  end)
end
