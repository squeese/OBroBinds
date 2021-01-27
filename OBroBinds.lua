local _, ADDON = ...
local listen, dispatch, read, write = ADDON.listen, ADDON.dispatch, ADDON.read, ADDON.write

local frame = CreateFrame("frame", nil, UIParent, "OBroFrameTemplate")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
function frame:dispatch(key, ...)
  return dispatch(key, self, ...)
end

BINDING_HEADER_OBROBINDS = 'OBroBinds'
BINDING_NAME_TOGGLE_CONFIG = 'Toggle Config Panel'
function OBroBinds_Toggle()
  dispatch("GUI_TOGGLE", frame)
end

listen("PLAYER_LOGIN", function(e, frame)
  frame.offset = 1
  frame.class = select(2, UnitClass("player"))
  frame.spec = GetSpecialization()
  frame:dispatch("SET_ALL_OVERRIDE_BINDINGS")
  return e:once(frame)
end)

listen("PLAYER_SPECIALIZATION_CHANGED", function(e, frame)
  frame.spec = GetSpecialization()
  ClearOverrideBindings(frame)
  frame:dispatch("SET_ALL_OVERRIDE_BINDINGS")
  return e:next(frame)
end)

listen("GUI_TOGGLE", function(e, frame)
  if frame:IsVisible() then
    frame:dispatch("DB_WRITE", 'GUI', 'open', nil)
    frame:Hide()
  else
    frame:dispatch("DB_WRITE", 'GUI', 'open', true)
    frame:Show()
  end
  return e:next(frame)
end)

listen("GUI_SHOW", function(e, frame)
  frame:RegisterEvent("UPDATE_BINDINGS")
  frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  frame:RegisterEvent("PLAYER_TALENT_UPDATE")
  frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  return e:next(frame)
end)

listen("GUI_SHOW", ADDON:part("InitializeModifierListener"))
listen("GUI_SHOW", ADDON:part("InitializeStanceHandler"))
listen("GUI_SHOW", ADDON:part("InitializeButtonHandler"))
listen("GUI_SHOW", ADDON:part("InitializeTooltipHandler"))
listen("GUI_SHOW", ADDON:part("InitializeDropdownHandler"))

listen("GUI_HIDE", function(e, frame)
  frame:UnregisterEvent("UPDATE_BINDINGS")
  frame:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
  frame:UnregisterEvent("PLAYER_TALENT_UPDATE")
  frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
  frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
  return e:next(frame)
end)

listen("SET_ALL_OVERRIDE_BINDINGS", function(e, frame)
  local overrides = read(OBroBindsDB, frame.class, frame.spec)
  if overrides then
    for binding, action in pairs(overrides) do
      frame:dispatch("SET_OVERRIDE_BINDING", false, binding, unpack(action))
    end
  end
  return e:next(frame)
end)

listen("GET_OVERRIDE_BINDING", function(e, frame, binding)
  local action = read(OBroBindsDB, frame.class, frame.spec, binding)
  if action then
    return e:next(frame, binding, unpack(action))
  end
  return e:next(frame, binding, nil)
end)

listen("SET_OVERRIDE_BINDING", function(e, frame, save, binding, kind, id)
  if kind == "spell" then
    local name = GetSpellInfo(id)
    SetOverrideBindingSpell(frame, false, binding, name)
  elseif kind == "macro" then
    SetOverrideBindingMacro(frame, false, binding, id)
  elseif kind == "item" then
    local name = GetItemInfo(id)
    SetOverrideBindingItem(frame, false, binding, name)
  end
  if save then
    OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, {kind, id})
  end
  return e:next(frame, binding, kind, id)
end)

listen("DEL_OVERRIDE_BINDING", function(e, frame, save, binding)
  SetOverrideBinding(frame, false, binding, nil)
  if save then
    OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, nil)
  end
  return e:next(frame, binding)
end)

listen("PICKUP_BINDING", function(e, frame, button)
  print("PICKUP_BINDING", button.key)
  local binding = frame.modifier..button.key
  if frame.mainbar[binding] then
    PickupAction(frame.mainbar[binding] + frame.offset - 1)
    return e:next(frame, button)
  end
  local kind, id = select(3, frame:dispatch("GET_OVERRIDE_BINDING", binding))
  if kind == "spell" then
    PickupSpell(id)
    --if not GetCursorInfo() then
      --local icon = select(3, GetSpellInfo(id))
      --local macro = CreateMacro("__TMP", icon)
      --PickupMacro(macro)
      --DeleteMacro(macro)
      --frame.__tmp = id
    --end
  elseif kind == "macro" then
    PickupMacro(id)
  elseif kind == "item" then
    PickupItem(id)
  elseif kind then
    assert(false, "Unhandled pickup: "..kind)
  end
  frame:dispatch("DEL_OVERRIDE_BINDING", true, binding)
  return e:next(frame, button)
end)

listen("RECEIVE_BINDING", function(e, frame, button)
  print("RECEIVE_BINDING", button.key, GetCursorInfo())
  local binding = frame.modifier..button.key
  if frame.mainbar[binding] then
    PlaceAction(frame.mainbar[binding] + frame.offset - 1)
    return e:next(frame, button)
  end
  local kind, id, _, arg1, arg2, action = GetCursorInfo()
  if kind == "spell" then
    ClearCursor()
    frame:dispatch("PICKUP_BINDING", button)
    frame:dispatch("SET_OVERRIDE_BINDING", true, binding, kind, arg2 or arg1)
  --elseif kind == "macro" and frame.__tmp then
    --action = { "spell", frame.__tmp }
    --frame.__tmp = nil
  elseif kind == "macro" then
    ClearCursor()
    frame:dispatch("PICKUP_BINDING", button)
    frame:dispatch("SET_OVERRIDE_BINDING", true, binding, kind, GetMacroInfo(id))
  elseif kind == "item" then
    ClearCursor()
    frame:dispatch("PICKUP_BINDING", button)
    frame:dispatch("SET_OVERRIDE_BINDING", true, binding, kind, id)
  elseif kind then
    assert(false, "Unhandled receive: "..kind)
  end
  return e:next(frame, button)
end)
