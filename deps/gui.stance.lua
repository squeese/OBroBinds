local _, addon = ...
local subscribe, dispatch = addon:get("subscribe", "dispatch")

subscribe("TOGGLE_GUI", function(event, frame)
  print(event.key, "frame.stances")
  return event:unsub():next(frame)
end)

subscribe("SHOW_GUI", function(event, frame)
  print(event.key, "stance - update")
  return event:next(frame)
end)


--[[
subscribe("GET_CLASS_STANCES", function(event, class)
  local stances = {
    {class = "ROGUE", offset = 72,  icon = 'ability_stealth',            1, 2, 3},
    {class = "DRUID", offset = 97,  icon = 'ability_racial_bearform',    1, 2, 3, 4},
    {class = "DRUID", offset = 72,  icon = 'ability_druid_catform',      1, 2, 3, 4},
    {class = "DRUID", offset = 109, icon = 'spell_nature_forceofnature', 1}
  }
  for index = #stances, 1, -1 do
    if class ~= stances[index].class then
      table.remove(stances, index)
    end
  end
  return event:unsub():next(#stances > 0 and stances or nil)
end)

local function UpdateButtons(event, frame, buttons, spec, offset)
  local prev
  for _, button in ipairs(buttons) do
    if match(spec, unpack(button)) then
      button:Show()
      button:ClearAllPoints()
      if not prev then
        button:SetPoint("TOPLEFT", 16, 34)
      else
        button:SetPoint("LEFT", prev, "RIGHT", 4, 0)
      end
      if offset == button.offset then
        button.Border:Show()
      else
        button.Border:Hide()
      end
      prev = button
    else
      button:Hide()
    end
  end
  return event:next(frame, buttons, spec, offset)
end

subscribe("UPDATE_STANCE_BUTTONS", function(event, frame, stances, spec, offset)
  if stances then
    local function OnClick(self)
      dispatch("OFFSET_CHANGED", self.offset)
    end
    for index, stance in ipairs(stances) do
      local button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
      button.offset = stance.offset
      button.icon:SetTexture("Interface/Icons/"..stance.icon)
      button:RegisterForClicks("AnyUp")
      button:SetScript("OnClick", OnClick)
      rpush(button, unpack(stance))
      stances[index] = button
    end
    subscribe("UPDATE_STANCE_BUTTONS", UpdateButtons)
    return UpdateButtons(event:unsub(), frame, stances, spec, offset)
  end
  return event:unsub():next(frame, stances, spec, offset)
end)
]]
