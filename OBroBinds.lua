local _A = select(2, ...)
local listen, release, read, write, push, STATE = _A.listen, _A.release, _A.read, _A.write, _A.push, _A.STATE
local root = _G.OBroBindsRootFrame
root.dispatch = _A.dispatch

frame.dispatch = _A.dispatch
frame:RegisterEvent("PLAYER_LOGIN")

--local frame = CreateFrame("frame", "OBroBindsFrame", UIParent, "OBroBindsFrameTemplate")

--[[

local function log(desc)
  return function(e, ...)
    print(desc, e.key, ...)
    return e:next(...)
  end
end

listen("GUI_TOGGLE", setmetatable({
  STATE.call, function(e, frame)
    root:Show()
  end,
  STATE.skip, STATE.call, function(e, frame)
    root:Hide()
  end,
  STATE.toggle,
}, STATE))



listen("ROOT_SHOW", setmetatable({
  STATE.listen, "PAGE_KEYBOARD_SHOW", log("show keyboard"),
  STATE.listen, "PAGE_SETTINGS_SHOW", log("show settings"),
  STATE.call, log("down"),
  STATE.skip, STATE.call, log("up"),
  STATE.bounce, "ROOT_HIDE"
}, STATE))



frame.dispatch = _A.dispatch
frame:RegisterEvent("PLAYER_LOGIN")

listen("PLAYER_LOGIN", function(e, frame)
  frame.class = select(2, UnitClass("player"))
  frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  frame:dispatch("PLAYER_SPECIALIZATION_CHANGED")
  if read(OBroBindsDB, 'GUI', 'open') then
    frame:dispatch("GUI_TOGGLE", true)
  end
  return e:once(frame)
end)
listen("PLAYER_SPECIALIZATION_CHANGED", _A.BindAllOverrideEntries)
listen("SET_OVERRIDE_ENTRY", _A.SetOverrideEntry)
listen("GUI_TOGGLE", function(e, frame, initial)
  if not initial then
    OBroBindsDB = write(OBroBindsDB, 'GUI', 'open', not read(OBroBindsDB, 'GUI', 'open') and true or nil)
  end
  frame[frame:IsVisible() and 'Hide' or 'Show'](frame)
  return e:next(frame, initial)
end)

listen("GUI_TOGGLE", setmetatable({
  STATE.init, function(e, frame, ...)
    frame:SetScript("OnUpdate", _A.UpdateCurrentModifier)
    frame.modifier = (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")
    frame.mainbar = {}
    frame.buttons = {}
    frame.offset = 1
    frame.stances = nil 
    if frame.class == "ROGUE" then
      write(frame, 'stances', push, _A.CreateStanceButton(frame, 73, 'ability_stealth', 1, 2, 3))
    elseif true or frame.class == "DRUID" then
      write(frame, 'stances', push, _A.CreateStanceButton(frame, 97,  'ability_racial_bearform',    1, 2, 3, 4))
      write(frame, 'stances', push, _A.CreateStanceButton(frame, 73,  'ability_druid_catform',      1, 2, 3, 4))
      write(frame, 'stances', push, _A.CreateStanceButton(frame, 109, 'spell_nature_forceofnature', 1))
    else
      _A.UpdateStanceButtons = nil
    end
    _A.CreateStanceButton = nil
    return e:next(frame, _A.DEFAULT_KEYBOARD_LAYOUT, ...)
  end,
  STATE.init, _A.UpdateKeyboardLayout,
  STATE.push, _A.UpdateStanceButtons,
  STATE.push, _A.UpdateKeyboardMainbarBindings,
  STATE.push, _A.UpdateKeyboardButtons,
  STATE.listen, "UPDATE_LAYOUT", _A.UpdateKeyboardLayout,
  STATE.listen, "PLAYER_SPECIALIZATION_CHANGED", _A.UpdateStanceButtons,
  STATE.listen, "PLAYER_SPECIALIZATION_CHANGED", _A.UpdateUnknownSpells,
  STATE.listen, "PLAYER_SPECIALIZATION_CHANGED", _A.UpdateKeyboardButtons,
  STATE.listen, "PLAYER_SPECIALIZATION_CHANGED", _A.RefreshTooltip,
  STATE.listen, "ACTIONBAR_SLOT_CHANGED", _A.UpdateKeyboardMainbarSlots,
  STATE.listen, "UPDATE_BINDINGS", _A.UpdateKeyboardMainbarBindings,
  STATE.listen, "UPDATE_BINDINGS", _A.UpdateKeyboardButtons,
  STATE.listen, "UPDATE_BINDINGS", _A.RefreshTooltip,
  STATE.listen, "OFFSET_CHANGED", _A.UpdateStanceButtons,
  STATE.listen, "OFFSET_CHANGED", _A.UpdateStanceButtons,
  STATE.listen, "OFFSET_CHANGED", _A.UpdateKeyboardButtons,
  STATE.listen, "OFFSET_CHANGED", _A.RefreshTooltip,
  STATE.listen, "MODIFIER_CHANGED", _A.UpdateKeyboardButtons,
  STATE.listen, "MODIFIER_CHANGED", _A.RefreshTooltip,
  STATE.listen, "PLAYER_TALENT_UPDATE", _A.UpdateUnknownSpells,
  STATE.listen, "PLAYER_TALENT_UPDATE", _A.UpdateKeyboardButtons,
  STATE.listen, "PLAYER_TALENT_UPDATE", _A.RefreshTooltip,
  STATE.listen, "UPDATE_MACROS", _A.UpdateKeyboardButtons,
  STATE.listen, "UPDATE_MACROS", _A.UpdateKeyboardButtons,
  STATE.listen, "SHOW_TOOLTIP", _A.UpdateTooltip,
  STATE.listen, "SHOW_DROPDOWN", _A.UpdateDropdown,
  STATE.listen, "GET_OVERRIDE_ENTRY", _A.GetOverrideEntry,
  STATE.listen, "DEL_OVERRIDE_ENTRY", _A.DelOverrideEntry,
  STATE.listen, "LOCK_OVERRIDE_ENTRY", _A.LockOverrideEntry,
  STATE.listen, "PICKUP_OVERRIDE_ENTRY", _A.PickupOverrideEntry,
  STATE.listen, "RECEIVE_OVERRIDE_ENTRY", _A.ReceiveOverrideEntry,
  STATE.listen, "PROMOTE_OVERRIDE_ENTRY", _A.PromoteOverrideEntry,
  STATE.register, "ACTIONBAR_SLOT_CHANGED",
  STATE.register, "PLAYER_TALENT_UPDATE",
  STATE.register, "PLAYER_REGEN_DISABLED",
  STATE.register, "PLAYER_REGEN_ENABLED",
  STATE.register, "UPDATE_BINDINGS",
  STATE.register, "UPDATE_MACROS",
  STATE.toggle
}, STATE))
--
