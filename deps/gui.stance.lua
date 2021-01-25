local _, addon = ...
local subscribe, dispatch, unsubscribe, rpush, match = addon:get("subscribe", "dispatch", "unsubscribe", "rpush", "match")

subscribe("PLAYER_LOGIN", function(event, frame)
  local stances = {
    {class = "ROGUE", offset = 73,  icon = 'ability_stealth',            1, 2, 3},
    {class = "DRUID", offset = 97,  icon = 'ability_racial_bearform',    1, 2, 3, 4},
    {class = "DRUID", offset = 73,  icon = 'ability_druid_catform',      1, 2, 3, 4},
    {class = "DRUID", offset = 109, icon = 'spell_nature_forceofnature', 1}
  }
  for index = #stances, 1, -1 do
    if frame.class ~= stances[index].class then
      table.remove(stances, index)
    end
  end
  frame.stances = stances
  return event:unsub():next(frame)
end)

local function UpdateButtons(event, frame)
  local prev
  for _, button in ipairs(frame.stances) do
    if match(frame.spec, unpack(button)) then
      button:Show()
      button:ClearAllPoints()
      if not prev then
        button:SetPoint("TOPLEFT", 16, 34)
      else
        button:SetPoint("LEFT", prev, "RIGHT", 4, 0)
      end
      if frame.offset == button.offset then
        button.Border:Show()
      else
        button.Border:Hide()
      end
      prev = button
    else
      button:Hide()
    end
  end
  return event:next(frame)
end

local function ShowButtons(event, frame)
  subscribe("OFFSET_CHANGED", UpdateButtons)
  subscribe("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
  return UpdateButtons(event, frame)
end

local function HideButtons(event, frame)
  unsubscribe("OFFSET_CHANGED", UpdateButtons)
  unsubscribe("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
  return event:next(frame)
end

subscribe("SHOW_GUI", function(event, frame)
  if frame.stances then
    local function OnClick(self)
      dispatch("OFFSET_CHANGED", frame, self.offset)
    end
    for index, stance in ipairs(frame.stances) do
      local button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
      button.offset = stance.offset
      button.icon:SetTexture("Interface/Icons/"..stance.icon)
      button:RegisterForClicks("AnyUp")
      button:SetScript("OnClick", OnClick)
      rpush(button, unpack(stance))
      frame.stances[index] = button
    end
    subscribe("SHOW_GUI", ShowButtons)
    subscribe("HIDE_GUI", HideButtons)
    return ShowButtons(event:unsub(), frame)
  end
  return event:unsub():next(frame)
end)
