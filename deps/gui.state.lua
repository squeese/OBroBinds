local _, addon = ...

local subscribe, dispatch = addon:get("subscribe", "dispatch")

local frame = CreateFrame("frame", nil, UIParent, "BackdropTemplate")
local class, spec = nil, nil
local open = false
local modifier = nil
local stances = nil
local buttons = nil
local mainbinds = nil
local offset = 1
local layout = addon.DEFAULT_KEYBOARD_LAYOUT

subscribe("UPDATE_BINDINGS", function(event)
  mainbinds = addon.updateMainbarBindings(mainbinds)
  dispatch("UPDATE_KEYBOARD_BUTTONS", buttons, mainbinds)
  return event:next()
end)

subscribe("MODIFIER_CHANGED", function(event, value)
  modifier = value
  return event:next(value)
end)

subscribe("VARIABLES_LOADED", function(event)
  class = select(2, UnitClass("player"))
  spec = GetSpecialization()
  stances = dispatch("GET_CLASS_STANCES", class)
  C_Timer.After(1, OBroBinds_Toggle)
  return event:unsub():next()
end)

subscribe("PLAYER_SPECIALIZATION_CHANGED", function(event)
  spec = GetSpecialization()
  offset = getValidOffset(offset, stances)
  dispatch("UPDATE_STANCE_BAR", frame, stances, spec, offset)
end)

subscribe("TOGGLE_GUI", function(event)
  dispatch("INITIALIZE_GUI", frame)
  if not open then
    dispatch("UPDATE_STANCE_BAR", frame, stances, spec, offset)
    dispatch("UPDATE_KEYBOARD_LAYOUT", frame, buttons, layout)
    dispatch("UPDATE_KEYBOARD_BUTTONS", buttons, mainbinds)
    frame:Show()
  else
    frame:Hide()
  end
  open = not open
  event:next()
end)

subscribe("OFFSET_CHANGED", function(event, value)
  offset = value ~= offset and value or 1
  dispatch("UPDATE_STANCE_BAR", frame, stances, spec, offset)
  event:next()
end)







