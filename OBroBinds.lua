local _, addon = ...
local subscribe, dispatch, rpush = addon:get("subscribe", "dispatch", "rpush")
local frame = CreateFrame("frame", nil, UIParent, "BackdropTemplate")

frame:RegisterEvent("UPDATE_BINDINGS")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:SetScript("OnEvent", function(self, event, ...)
  dispatch(event, self, ...)
end)

BINDING_HEADER_OBROBINDS = 'OBroBinds'
BINDING_NAME_TOGGLE_CONFIG = 'Toggle Config Panel'
function OBroBinds_Toggle()
  dispatch("TOGGLE_GUI", frame)
end
