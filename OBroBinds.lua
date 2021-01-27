local _, ADDON = ...
local listen, dispatch, read, write = ADDON.listen, ADDON.dispatch, ADDON.read, ADDON.write

local frame = CreateFrame("frame", "OBroBindsFrame", UIParent, "OBroFrameTemplate")
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
  SaveBindings(GetCurrentBindingSet())
  frame:dispatch("SET_ALL_OVERRIDE_BINDINGS")
  if read(OBroBindsDB, 'GUI', 'open') then
    OBroBinds_Toggle()
  end
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
    OBroBindsDB = write(OBroBindsDB, 'GUI', 'open', nil)
    frame:Hide()
  else
    OBroBindsDB = write(OBroBindsDB, 'GUI', 'open', true)
    frame:Show()
  end
  return e:next(frame)
end)

listen("GUI_SHOW", function(e, frame)
  frame:RegisterEvent("UPDATE_BINDINGS")
  frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  frame:RegisterEvent("UPDATE_MACROS")
  frame:RegisterEvent("PLAYER_TALENT_UPDATE")
  frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  return e:next(frame)
end)

listen("GUI_SHOW", ADDON:part("InitializeModifierListener"))
listen("GUI_SHOW", ADDON:part("InitializeStanceHandler"))
listen("GUI_SHOW", ADDON:part("InitializeMissingIconHandler"))
listen("GUI_SHOW", ADDON:part("InitializeButtonHandler"))
listen("GUI_SHOW", ADDON:part("InitializeTooltipHandler"))
listen("GUI_SHOW", ADDON:part("InitializeDropdownHandler"))

listen("GUI_HIDE", function(e, frame)
  frame:UnregisterEvent("UPDATE_BINDINGS")
  frame:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
  frame:UnregisterEvent("UPDATE_MACROS")
  frame:UnregisterEvent("PLAYER_TALENT_UPDATE")
  frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
  frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
  return e:next(frame)
end)

listen("SET_ALL_OVERRIDE_BINDINGS", function(e, frame)
  local overrides = read(OBroBindsDB, frame.class, frame.spec)
  if overrides then
    for binding, action in pairs(overrides) do
      frame:dispatch("SET_OVERRIDE_BINDING", false, binding, action[1], action[2], action[3], action[4])
    end
  end
  return e:next(frame)
end)

listen("GET_OVERRIDE_BINDING", function(e, frame, binding)
  local action = read(OBroBindsDB, frame.class, frame.spec, binding)
  if action then
    return e:next(frame, binding, action[1], action[2], action[3], action[4], action[5])
  end
  return e:next(frame, binding, nil)
end)

listen("SET_OVERRIDE_BINDING", function(e, frame, save, binding, kind, id, name, icon, locked)
  if kind == "SPELL" then
    SetOverrideBindingSpell(frame, false, binding, GetSpellInfo(id) or name)
  elseif kind == "macro" then
    SetOverrideBindingMacro(frame, false, binding, name)
  elseif kind == "ITEM" then
    SetOverrideBindingItem(frame, false, binding, name)
  end
  if save then
    OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, {kind, id, name, icon, locked})
  end
  return e:next(frame, binding, save, kind, id, name, icon, locked)
end)

listen("DEL_OVERRIDE_BINDING", function(e, frame, save, binding)
  SetOverrideBinding(frame, false, binding, nil)
  if save then
    OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, nil)
  end
  return e:next(frame, binding)
end)

listen("PICKUP_BINDING", function(e, frame, button)
  local binding = frame.modifier..button.key
  if not read(OBroBindsDB, frame.class, frame.spec, binding, 5) then
    if frame.mainbar[binding] then
      PickupAction(frame.mainbar[binding] + frame.offset - 1)
      return e:next(frame, button)
    end
    local kind, id, name = select(3, frame:dispatch("GET_OVERRIDE_BINDING", binding))
    if kind == "SPELL" then
      PickupSpell(id)
    elseif kind == "MACRO" then
      PickupMacro(name)
    elseif kind == "ITEM" then
      PickupItem(id)
    elseif kind then
      assert(false, "Unhandled pickup: "..kind)
    end
    frame:dispatch("DEL_OVERRIDE_BINDING", true, binding)
  end
  return e:next(frame, button)
end)

listen("RECEIVE_BINDING", function(e, frame, button)
  local binding = frame.modifier..button.key
  if not read(OBroBindsDB, frame.class, frame.spec, binding, 5) then
    if frame.mainbar[binding] then
      PlaceAction(frame.mainbar[binding] + frame.offset - 1)
      return e:next(frame, button)
    end
    local kind, id, link, arg1, arg2 = GetCursorInfo()
    if kind == "spell" then
      ClearCursor()
      frame:dispatch("PICKUP_BINDING", button)
      local id = arg2 or arg1
      local name, _, icon = GetSpellInfo(id)
      assert(id ~= nil, "GetCursorInfo() on spell, id should never be nil")
      assert(name ~= nil, "GetCursorInfo() on spell, name should never be nil")
      assert(icon ~= nil, "GetCursorInfo() on spell, icon should never be nil")
      frame:dispatch("SET_OVERRIDE_BINDING", true, binding, strupper(kind), id, name, icon)

    elseif kind == "macro" then
      ClearCursor()
      frame:dispatch("PICKUP_BINDING", button)
      local name, icon = GetMacroInfo(id)
      assert(id ~= nil, "GetCursorInfo() on macro, id should never be nil")
      assert(type(id) == "number", "GetCursorInfo() on macro, id should always be number")
      assert(name ~= nil, "GetCursorInfo() on macro, name should never be nil")
      assert(icon ~= nil, "GetCursorInfo() on macro, icon should never be nil")
      frame:dispatch("SET_OVERRIDE_BINDING", true, binding, strupper(kind), id, name, icon)

    elseif kind == "item" then
      ClearCursor()
      local name = select(3, string.match(link, "^|c%x+|H(%a+):(%d+).+|h%[([^%]]+)"))
      local icon = select(10, GetItemInfo(id))
      assert(link ~= nil, "GetCursorInfo() on item, link should never be nil")
      assert(name ~= nil, "GetCursorInfo() on item, name should never be nil")
      assert(icon ~= nil, "GetCursorInfo() on item, icon should never be nil")
      frame:dispatch("PICKUP_BINDING", button)
      frame:dispatch("SET_OVERRIDE_BINDING", true, binding, strupper(kind), id, name, icon)

    elseif kind then
      assert(false, "Unhandled receive: "..kind)
    end
  end
  return e:next(frame, button)
end)

listen("PROMOTE_BINDING", function(e, frame, binding)
  local action = GetBindingAction(binding, false)
  local kind, name = string.match(action, "^(%w+) (.*)$")
  print(e.key, binding, action, "|", kind, name)

  if kind == 'SPELL' then
    local icon, _, _, _, id = select(3, GetSpellInfo(name))
    assert(name ~= nil)
    frame:dispatch("SET_OVERRIDE_BINDING", true, binding, kind, id, name, icon or 134400)

  elseif kind == 'MACRO' then
    local id = GetMacroIndexByName(name)
    local icon = select(2, GetMacroInfo(name))
    assert(name ~= nil)
    frame:dispatch("SET_OVERRIDE_BINDING", true, binding, kind, id, name, icon or 134400)

  elseif kind == 'ITEM' then
    local link, _, _, _, _, _, _, _, icon = select(2, GetItemInfo(name))
    local id = link and select(4, string.find(link, "^|c%x+|H(%a+):(%d+)[|:]"))
    assert(name ~= nil)
    frame:dispatch("SET_OVERRIDE_BINDING", true, binding, kind, id, name, icon or 134400)

  else
    assert(false, "Unhandled type: "..kind)
  end

  return e:next(frame, binding)
end)

listen("LOCK_BINDING", function(e, frame, binding)
  local value = not read(OBroBindsDB, frame.class, frame.spec, binding, 5) and true or nil
  OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, 5, value)
  return e:next(frame, binding)
end)
