local _A = select(2, ...)
local listen, release, read, write, push, STACK = _A.listen, _A.release, _A.read, _A.write, _A.push, _A.STACK

listen("PLAYER_LOGIN", setmetatable({
  STACK.fold, nil,
  STACK.call, _A.UpdatePlayerBindings,
  STACK.listen, "PLAYER_SPECIALIZATION_CHANGED", _A.UpdatePlayerBindings,
  STACK.init, function(e, root, ...)
    root[read(OBroBindsDB, 'GUI', 'open') and 'Show' or 'Hide'](root)
    e(root, ...)
  end,

}, STACK))

listen("ADDON_ROOT_SHOW", setmetatable({
  STACK.fold, "ADDON_ROOT_HIDE",
  STACK.init, _A.InitializeRoot,
  STACK.both, _A.UpdateRootPersistState,
  STACK.listen, "ADDON_GET_OVERRIDE_BINDING", _A.GetOverrideBinding,
  --STACK.listen, "ADDON_DEL_OVERRIDE_BINDING", _A.DelOverrideBinding,
}, STACK))

function TEST1()
  print("START")
  SetBinding(GetBindingKey("ACTIONBUTTON1"), nil)
  SetBinding(GetBindingKey("ACTIONBUTTON2"), nil)
  SetBinding("SHIFT-1", "ACTIONBUTTON1")
  SetBinding("2", "ACTIONBUTTON2")
  SaveBindings(2)
  print("STOP")
end

function TEST2()
  print("START")
  SetBinding(GetBindingKey("ACTIONBUTTON1"), nil)
  SetBinding(GetBindingKey("ACTIONBUTTON2"), nil)
  SetBinding("SHIFT-1", "ACTIONBUTTON2")
  SetBinding("2", "ACTIONBUTTON1")
  SaveBindings(2)
  print("STOP")
end



listen("ADDON_PAGE_KEYBOARD_SHOW", setmetatable({
  STACK.fold, "ADDON_PAGE_KEYBOARD_HIDE",
  STACK.init, _A.InitializePageKeyboard,
  STACK.call, _A.UpdateKeyboardStanceButtons,
  STACK.init, _A.UpdateKeyboardLayout,
  STACK.call, _A.UpdateKeyboardMainbarIndices,
  STACK.call, _A.UpdateKeyboardButtons,

  STACK.listen, "ADDON_UPDATE_LAYOUT",           _A.UpdateKeyboardLayout,
  STACK.listen, "UPDATE_BINDINGS",               _A.UpdateKeyboardMainbarIndices,
  STACK.listen, "ACTIONBAR_SLOT_CHANGED",        _A.UpdateKeyboardMainbarSlots,
  STACK.listen, "ADDON_OFFSET_CHANGED",          _A.UpdateKeyboardMainbarOffsets,
  STACK.listen, "ADDON_MODIFIER_CHANGED",        _A.UpdateKeyboardButtons,
  STACK.listen, "ADDON_PLAYER_TALENT_UPDATE",    _A.UpdateKeyboardButtons,
  STACK.listen, "ADDON_UPDATE_MACROS",           _A.UpdateKeyboardButtons,
  STACK.listen, "PLAYER_SPECIALIZATION_CHANGED", _A.UpdateKeyboardButtons,
  STACK.listen, "ADDON_OFFSET_CHANGED",          _A.UpdateKeyboardStanceButtons,
  STACK.listen, "PLAYER_SPECIALIZATION_CHANGED", _A.UpdateKeyboardStanceButtons,

  --STACK.listen, "ADDON_DEL_OVERRIDE_BINDING", _A.UpdateKeyboardDeletedButtons,
  --STACK.listen, "UPDATE_BINDINGS", _A.RefreshTooltip,
  --STACK.listen, "OFFSET_CHANGED", _A.RefreshTooltip,
  --STACK.listen, "MODIFIER_CHANGED", _A.RefreshTooltip,
  --STACK.listen, "PLAYER_TALENT_UPDATE", _A.UpdateUnknownSpells,
  --STACK.listen, "PLAYER_SPECIALIZATION_CHANGED", _A.RefreshTooltip,
  --STACK.listen, "PLAYER_TALENT_UPDATE", _A.RefreshTooltip,
  --STACK.listen, "SHOW_TOOLTIP", _A.UpdateTooltip,
  --STACK.listen, "SHOW_DROPDOWN", _A.UpdateDropdown,
  --STACK.listen, "PLAYER_SPECIALIZATION_CHANGED", _A.UpdateUnknownSpells,
  --STACK.listen, "GET_OVERRIDE_ENTRY", _A.GetOverrideEntry,
  --STACK.listen, "DEL_OVERRIDE_ENTRY", _A.DelOverrideEntry,
  --STACK.listen, "LOCK_OVERRIDE_ENTRY", _A.LockOverrideEntry,
  --STACK.listen, "PICKUP_OVERRIDE_ENTRY", _A.PickupOverrideEntry,
  --STACK.listen, "RECEIVE_OVERRIDE_ENTRY", _A.ReceiveOverrideEntry,
  --STACK.listen, "PROMOTE_OVERRIDE_ENTRY", _A.PromoteOverrideEntry,
}, STACK))










------local frame = CreateFrame("frame", "OBroBindsFrame", UIParent, "OBroBindsFrameTemplate")

----[>
----local function log(desc)
  ----return function(e, ...)
    ----print(desc, e.key, ...)
    ----return e:next(...)
  ----end
----end

----listen("GUI_TOGGLE", setmetatable({
  ----STATE.call, function(e, frame)
    ----root:Show()
  ----end,
  ----STATE.skip, STATE.call, function(e, frame)
    ----root:Hide()
  ----end,
  ----STATE.toggle,
----}, STATE))



----listen("ROOT_SHOW", setmetatable({
  ----STATE.listen, "PAGE_KEYBOARD_SHOW", log("show keyboard"),
  ----STATE.listen, "PAGE_SETTINGS_SHOW", log("show settings"),
  ----STATE.call, log("down"),
  ----STATE.skip, STATE.call, log("up"),
  ----STATE.bounce, "ROOT_HIDE"
----}, STATE))
------]]






