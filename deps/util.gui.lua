local _, addon = ...

  for index = 1, 12 do
    local binding = GetBindingKey("ACTIONBUTTON"..index)
    if binding then
      tbl = write(tbl, binding, index)
    end
  end
  return tbl


subscribe("TOGGLE_GUI", function(event, frame, ...)
  local stances = {
    {class = "ROGUE", offset = 72,  icon = 'ability_stealth',            1, 2, 3},
    {class = "DRUID", offset = 97,  icon = 'ability_racial_bearform',    1, 2, 3, 4},
    {class = "DRUID", offset = 72,  icon = 'ability_druid_catform',      1, 2, 3, 4},
    {class = "DRUID", offset = 109, icon = 'spell_nature_forceofnature', 1}
  }
  for index = #stances, 1, -1 do
    if frame.class ~= stances[index].class then
      table.remove(stances, index)
    else
      local button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
      button.offset = stance.offset
      button.icon:SetTexture("Interface/Icons/"..stance.icon)
      button:RegisterForClicks("AnyUp")
      button:SetScript("OnClick", OnClick)
      rpush(button, unpack(stance))
      stances[index] = button
    end
  end
  return event:unsub():next(frame, ...)
end)





















--[-[----------------------------------------------------------------------- ROOT FRAME
do
  local prev

  local function panelButton(frame, text, fn)
    local button = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
    button:SetSize(100, 32)
    button:SetText(text)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", fn)
    if not prev then
      button:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
    else
      button:SetPoint("TOP", prev, "BOTTOM", 0, 0)
    end
    prev = button
  end
  addon.REF("panelButton", panelButton)

  subscribe("INITIALIZE_GUI", function(event, frame, ...)
    frame:SetFrameStrata("DIALOG")
    frame:SetSize(1, 1)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 32)
    frame:SetBackdrop({
      bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
      edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    panelButton(frame, "reload", function()
      ReloadUI()
    end)
    panelButton(frame, "reset", function()
      OBroBindsDB = nil
      ReloadUI()
    end)
    panelButton(frame, "import", function()
      OBroBindsDB = nil
      dispatch("IMPORT")
    end)
    do
      local elapsed, pAlt, pCtrl, pShift = 0, false, false, false
      dispatch("MODIFIER_CHANGED", (pAlt and "ALT-" or "")..(pCtrl and "CTRL-" or "")..(pShift and "SHIFT-" or ""))
      frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed > 0.1 then
          elapsed = 0
          local nAlt, nCtrl, nShift = IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
          if pAlt == nAlt and pCtrl == nCtrl and pShift == nShift then return end
          pAlt, pCtrl, pShift = nAlt, nCtrl, nShift
          dispatch("MODIFIER_CHANGED", (pAlt and "ALT-" or "")..(pCtrl and "CTRL-" or "")..(pShift and "SHIFT-" or ""))
        end
      end)
    end
    return event:unsub():next(frame, ...)
  end)
end
--]]




--[-[------------------------------------------------------------------------- STANCE BUTTONS
do
  local match, rpush = addon:get("match", "rpush")
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

  subscribe("UPDATE_STANCE_BUTTON_LAYOUT", function(event, frame, stances, spec, offset)
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
      subscribe("UPDATE_STANCE_BUTTON_LAYOUT", UpdateButtons)
      return UpdateButtons(event:unsub(), frame, stances, spec, offset)
    end
    return event:unsub():next(frame, stances, spec, offset)
  end)
end
--]]

--[-[------------------------------------------------------------------------- ACTION BUTTONS
do
  local function OnDragStart(self)
  end
  local function OnReceiveDrag(self)
  end
  local index, buttons
  subscribe("UPDATE_ACTION_BUTTON_LAYOUT", function(event, frame, layout)
    if not buttons or buttons.layout ~= layout then
      buttons, index = buttons or {}, 0
      local xmin, xmax = frame:GetLeft(), frame:GetRight()
      local ymin, ymax = frame:GetBottom(), frame:GetTop()
      local button
      for i = 1, #layout, 3 do
        index = index + 1
        if index > #buttons then
          button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
          button:SetScript("OnDragStart", OnDragStart)
          button:SetScript("OnReceiveDrag", OnReceiveDrag)
          button:SetScript("OnClick", OnReceiveDrag)
          button:RegisterForDrag("LeftButton")
          button:RegisterForClicks("AnyUp")
          tinsert(buttons, button)
        else
          button = buttons[index]
        end
        local key, x, y = select(i, unpack(layout))
        button.key = key
        button:SetPoint("TOPLEFT", 16+x, -y-16)
        button.Border:Hide()
        button.Border:SetAlpha(1)
        button.HotKey:SetText(key)
        button.Name:SetText()
        xmin = math.min(xmin, button:GetLeft())
        xmax = math.max(xmax, button:GetRight())
        ymin = math.min(ymin, button:GetBottom())
        ymax = math.max(ymax, button:GetTop())
      end
      for i = index+1, #buttons do
        button = buttons[index]
        button:Hide()
      end
      frame:SetSize(xmax-xmin+16, ymax-ymin+16)
      buttons.layout = layout
    end
    return event:next(buttons)
  end)

  --local read = addon:get("read")
  --subscribe("UPDATE_ACTION_BUTTON_LAYOUT", function(event, buttons)
    --for _, button in ipairs(buttons) do
      --local 
    --end
    --return event:next(buttons)
  --end)

  --[[
  local regex = "[.*-]?([^-]*.)$"
  subscribe("UPDATE_MAINBAR_BUTTONS", function(event)
    print("set mainbar buttons")
    for index = 1, 12 do
      local binding = GetBindingKey("ACTIONBUTTON"..index)
      if binding then
        local key = string.match(binding, regex)
        print("??", index, binding, key)
        -- local button = self['key__'..key]
        --write(button, 'bindings', increment)
        --write(button, binding, index)
      end
    end
    return event:next()
  end)
  ]]

  --[[
  subscribe("IMPORT", function(event)
    OBroBindsDB = nil
    local regx = "^(%w+) (.*)$"
    local mods = {"", "ALT-", "CTRL-", "SHIFT-", "ALT-CTRL-", "ALT-SHIFT-", "ALT-CTRL-SHIFT-", "CTRL-SHIFT-"}
    local class = select(2, UnitClass("player"))
    local spec = GetSpecialization()
    for i = 1, index do
      local button = buttons[i]
      for _, modifier in ipairs(mods) do
        local binding = modifier..button.key
        local action = GetBindingAction(binding)
        local kind, info = string.match(action, regx)
        print(kind, info, binding)
        if not kind then
        elseif kind == "SPELL" then
          local name, _, icon, _, _, _, id = GetSpellInfo(info)
          if name == info then
            dbWrite(class, spec, 'bindings', binding, { SPELL, id, name = name })
          end
        elseif kind == "MACRO" then
          local name, icon = GetMacroInfo(info)
          if name == info then
            dbWrite(class, spec, 'bindings', binding, { MACRO, name })
          end
        elseif kind == "ITEM" then
        end
      end
    end
    ReloadUI()
    return event:next()
  end)
  ]]
end
--]]







frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("UPDATE_BINDINGS")
frame:SetScript("OnEvent", function(self, event, ...)
  dispatch(event, ...)
end)

BINDING_HEADER_OBROBINDS = 'OBroBinds'
BINDING_NAME_TOGGLE_CONFIG = 'Toggle Config Panel'
function OBroBinds_Toggle()
  dispatch("TOGGLE_GUI")
end





















--subscribe("TOGGLE_GUI", addon, function()


  ---- create stance buttons
  --do
    --local stances = {
      --{class = "ROGUE", offset = 72,  icon = 'ability_stealth',            1, 2, 3},
      --{class = "DRUID", offset = 97,  icon = 'ability_racial_bearform',    1, 2, 3, 4},
      --{class = "DRUID", offset = 72,  icon = 'ability_druid_catform',      1, 2, 3, 4},
      --{class = "DRUID", offset = 109, icon = 'spell_nature_forceofnature', 1}
    --}
  --end
  --subscribe("TOGGLE_GUI", state, function()
    --state.open = not state.open
    --if state.open then
      --print("show")
      --frame:Show()
    --else
      --print("hide")
      --frame:Hide()
    --end
  --end)
  --dispatch("TOGGLE_GUI")
--end)


--subscribe("INITIALIZE_GUI", function())



-- GetCurrentBindingSet
-- GetBindingKey
-- GetBindingAction("5")
-- SetBindingSpell("5", "Rejuvenation")
-- GetSpellInfo(spell)
-- GetKeyFromBinding(binding)



--subscribe("INITIALIZE", function(self, _, frame)
  --frame:Hide()
  --frame:SetFrameStrata("DIALOG")
  --frame:SetSize(1, 1)
  --frame:SetPoint("CENTER", UIParent, "CENTER", 0, 32)
  --frame:SetBackdrop({
    --bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    --edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    --tile = true,
    --tileSize = 32,
    --edgeSize = 32,
    --insets = { left = 11, right = 12, top = 12, bottom = 11 }
  --})

  --frame:SetScript("OnShow", function(self)
  --end)
  --frame:SetScript("OnEvent", function(_, ...)
    --print("event", ...)
    --dispatch(...)
  --end)
  --frame:SetScript("OnHide", function(self)
    --self:UnregisterAllEvents()
  --end)

  --do
    --local elapsed, pAlt, pCtrl, pShift = 0
    --dispatch("MODIFIER_CHANGED", (pAlt and "ALT-" or "")..(pCtrl and "CTRL-" or "")..(pShift and "SHIFT-" or ""))
    --frame:SetScript("OnUpdate", function(_, delta)
      --elapsed = elapsed + delta
      --if elapsed > 0.1 then
        --elapsed = 0
        --local nAlt, nCtrl, nShift = IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
        --if pAlt == nAlt and pCtrl == nCtrl and pShift == nShift then return end
        --pAlt, pCtrl, pShift = nAlt, nCtrl, nShift
        --dispatch("MODIFIER_CHANGED", (pAlt and "ALT-" or "")..(pCtrl and "CTRL-" or "")..(pShift and "SHIFT-" or ""))
      --end
    --end)
  --end

  --do -- dev
    --local reset = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
    --reset:SetSize(100, 32)
    --reset:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0)
    --reset:SetText("reset")
    --reset:RegisterForClicks("AnyUp")
    --reset:SetScript("OnClick", function()
      --OBroBindsDB = nil
      --ReloadUI()
    --end)

    --local reload = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
    --reload:SetSize(100, 32)
    --reload:SetPoint("RIGHT", reset, "LEFT", -16, 0)
    --reload:SetText("reload")
    --reload:RegisterForClicks("AnyUp")
    --reload:SetScript("OnClick", function()
      --ReloadUI()
    --end)

    --local scan = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
    --scan:SetSize(100, 32)
    --scan:SetPoint("RIGHT", reload, "LEFT", -16, 0)
    --scan:SetText("scan")
    --scan:RegisterForClicks("AnyUp")
    --scan:SetScript("OnClick", function()
      --dispatch("SCAN")
    --end)
  --end

  --unsubscribe("INITIALIZE", self, true)
--end)
