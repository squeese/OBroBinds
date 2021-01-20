local _, addon = ...
local subscribe, dispatch, unsubscribe, dbWrite, dbRead, spread = addon:get("subscribe", "dispatch", "unsubscribe", "dbWrite", "dbRead", "spread")
local index, buttons, mainbar
local SPELL, MACRO, ITEM = 1, 2, 3

local function UpdateLayout(frame, layout)
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
end

local function UpdateButtons(event, frame)
  for i = 1, index do
    local button = buttons[i]
    local binding = frame.modifier..button.key
    if mainbar[binding] then
      button.Border:Show()
      button.Name:SetText(mainbar[binding])
    else
      button.Border:Hide()
      button.Name:SetText()
      local kind, id = spread(dbRead(nil, frame.spec, 'bindings', binding))
      -- print("?", binding, kind, id)
    end
  end
  return event:next(frame)
end

local function UpdateBindings(event, frame)
  mainbar = mainbar or {}
  for binding in pairs(mainbar) do
    mainbar[binding] = nil
  end
  for index = 1, 12 do
    local binding = GetBindingKey("ACTIONBUTTON"..index)
    if binding then
      mainbar[binding] = index 
    end
  end
  return UpdateButtons(event, frame)
end

subscribe("SHOW_GUI", function(event, frame)
  UpdateLayout(frame, addon.DEFAULT_KEYBOARD_LAYOUT)
  return event:unsub(frame):next(frame)
end)

subscribe("SHOW_GUI", function(event, frame)
  subscribe("UPDATE_BINDINGS", UpdateBindings)
  subscribe("MODIFIER_CHANGED", UpdateButtons)
  return UpdateBindings(event, frame)
end)

subscribe("HIDE_GUI", function(event, frame)
  unsubscribe("UPDATE_BINDINGS", UpdateBindings)
  unsubscribe("MODIFIER_CHANGED", UpdateButtons)
  return event:next(frame)
end)

subscribe("IMPORT_BINDS", function(event, frame)
  --[[
  OBroBindsDB = nil
  local regx = "^(%w+) (.*)$"
  local mods = {"", "ALT-", "CTRL-", "SHIFT-", "ALT-CTRL-", "ALT-SHIFT-", "ALT-CTRL-SHIFT-", "CTRL-SHIFT-"}
  for i = 1, index do
    local button = buttons[i]
    for _, modifier in ipairs(mods) do
      local binding = modifier..button.key
      local action = GetBindingAction(binding)
      local kind, info = string.match(action, regx)
      if not kind then
      elseif kind == "SPELL" then
        local name, _, icon, _, _, _, id = GetSpellInfo(info)
        if name == info then
          dbWrite(nil, frame.spec, 'bindings', binding, { SPELL, id, name = name })
        end
      elseif kind == "MACRO" then
        local name, icon = GetMacroInfo(info)
        if name == info then
          dbWrite(nil, frame.spec, 'bindings', binding, { MACRO, name })
        end
      elseif kind == "ITEM" then
      end
    end
  end
  ReloadUI()
  ]]
end)
