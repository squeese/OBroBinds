local _, addon = ...
local next, _, rpush, _, _, subscribe, dispatch, unsubscribe, write, read, dbWrite, dbRead, _, match = unpack(addon)

local function OnStanceButtonUpdate(self, offset)
  next(self.Border, self.__offset == offset and self.Border.Show or self.Border.Hide)
end
addon.REF("OnStanceButtonUpdate", OnStanceButtonUpdate)

local function OnStanceButtonClick(self)
  local current = dbRead(nil, "offset")
  local offset = self.__offset ~= current and self.__offset or nil
  dbWrite(nil, "offset", offset)
  dispatch("OFFSET_CHANGED", offset)
end
addon.REF("OnStanceButtonClick", OnStanceButtonClick)

local function OnSpecializationChanged(self)
  local spec = GetSpecialization()
  if self.spec == spec then return end
  self.spec = spec
  local offset = dbRead(nil, "offset")
  local prev, valid
  for _, button in ipairs(self) do
    if match(spec, unpack(button)) then
      button:Show()
      button:ClearAllPoints()
      if not prev then
        button:SetPoint("TOPLEFT", 16, 34)
      else
        button:SetPoint("LEFT", prev, "RIGHT", 4, 0)
      end
      subscribe("OFFSET_CHANGED", button)
      OnStanceButtonUpdate(button, offset)
      valid = valid or not offset or offset == button.__offset
      prev = button
    else
      button:Hide()
      unsubscribe("OFFSET_CHANGED", button)
    end
  end
  if not valid then
    dbWrite(nil, "offset", nil)
    dispatch("OFFSET_CHANGED", nil)
  end
end
addon.REF("OnSpecializationChanged", OnSpecializationChanged)

do
  local stances = {
    {class = "ROGUE", offset = 72,  icon = 'ability_stealth',            1, 2, 3},
    {class = "DRUID", offset = 97,  icon = 'ability_racial_bearform',    1, 2, 3, 4},
    {class = "DRUID", offset = 72,  icon = 'ability_druid_catform',      1, 2, 3, 4},
    {class = "DRUID", offset = 109, icon = 'spell_nature_forceofnature', 1}
  }
  addon.REF("stances", stances)

  subscribe("INITIALIZE", stances, function(_, parent, _, class)
    local buttons = {}
    for _, stance in ipairs(stances) do
      if class == stance.class then
        local button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
        button.__offset = stance.offset
        button.icon:SetTexture("Interface/Icons/"..stance.icon)
        button:RegisterForClicks("AnyUp")
        button:SetScript("OnClick", OnStanceButtonClick)
        button.OFFSET_CHANGED = OnStanceButtonUpdate
        rpush(buttons, rpush(button, unpack(stance)))
      end
    end
    if #buttons > 0 then
      subscribe("PLAYER_SPECIALIZATION_CHANGED", buttons, OnSpecializationChanged)
    end
    unsubscribe("INITIALIZE", stances, true)
  end)
  addon.REF("stances.INITIALIZE", stances.INITIALIZE)
end
