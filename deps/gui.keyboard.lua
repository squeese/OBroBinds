local _, addon = ...
local subscribe, dispatch, unsubscribe, dbWrite, dbRead, spread = addon:get("subscribe", "dispatch", "unsubscribe", "dbWrite", "dbRead", "spread")
local index, buttons, mainbar

local function UpdateButton(self, frame)
  local binding, kind, id = frame.modifier..self.key
  if mainbar[binding] then
    kind, id = GetActionInfo(mainbar[binding] + frame.offset - 1)
    self.Border:Show()
    self.Name:SetText(mainbar[binding])
  else
    kind, id = spread(dbRead(nil, frame.spec, binding))
    self.Border:Hide()
    self.Name:SetText()
  end
  if kind == 'spell' then
    self.icon:SetTexture(select(3, GetSpellInfo(id)))
  elseif kind == 'macro' then
    self.icon:SetTexture(select(2, GetMacroInfo(id)))
  elseif kind == 'item' then
    self.icon:SetTexture(select(10, GetItemInfo(id)))
  else
    self.icon:SetTexture(nil)
  end
end

local function PickupBinding(frame, kind, id, name)
  if kind == "spell" then
    PickupSpell(id)
    if not GetCursorInfo() then
      local icon = select(3, GetSpellInfo(id))
      local macro = CreateMacro("__TMP", icon)
      PickupMacro(macro)
      DeleteMacro(macro)
      frame.__tmp = id
    end
  elseif kind == "macro" then
    PickupMacro(id)
  elseif kind == "item" then
    PickupItem(id)
  end
end

local function OnDragStart(self)
  local frame = self:GetParent()
  local binding = frame.modifier..self.key
  if mainbar[binding] then
    PickupAction(mainbar[binding] + frame.offset - 1)
  else
    PickupBinding(frame, spread(dbRead(nil, frame.spec, binding)))
    dbWrite(nil, frame.spec, binding, nil)
    SetBinding(binding, nil)
    UpdateButton(self, frame)
  end
end

local function OnReceiveDrag(self)
  local frame = self:GetParent()
  local binding = frame.modifier..self.key
  if mainbar[binding] then
    PlaceAction(mainbar[binding] + frame.offset - 1)
  else
    local kind, id, _, arg1, arg2, action = GetCursorInfo()
    if kind == "spell" then
      action = { kind, arg2 or arg1 }
    elseif kind == "macro" and frame.__tmp then
      action = { "spell", frame.__tmp }
      frame.__tmp = nil
    elseif kind == "macro" then
      local name = GetMacroInfo(id)
      action = { kind, name }
    elseif kind == "item" then
      action = { kind, id }
    end
    if action then
      ClearCursor()
      PickupBinding(frame, spread(dbRead(nil, frame.spec, binding)))
      dbWrite(nil, frame.spec, binding, action)
      dispatch("BIND_ACTION", binding, unpack(action))
      UpdateButton(self, frame)
    end
  end
end

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
    UpdateButton(buttons[i], frame)
  end
  return event:next(frame)
end

local function UpdateBindings(event, frame)
  mainbar = mainbar or {}
  for binding in pairs(mainbar) do
    mainbar[binding] = nil
  end
  for i = 1, 12 do
    local binding = GetBindingKey("ACTIONBUTTON"..i)
    if binding then
      dbWrite(nil, frame.spec, binding, nil)
      mainbar[binding] = i
    end
  end
  return UpdateButtons(event, frame)
end

local function ActionBarSlotChanged(event, frame, slot)
  slot = slot - frame.offset + 1
  if (slot >= 1 and slot <= 12) then
    for i = 1, index do
      local button = buttons[i]
      local binding = frame.modifier..button.key
      if mainbar[binding] == slot then
        UpdateButton(button, frame)
        break
      end
    end
  end
  return event:next(frame, slot)
end

subscribe("SHOW_GUI", function(event, frame)
  UpdateLayout(frame, addon.DEFAULT_KEYBOARD_LAYOUT)
  return event:unsub(frame):next(frame)
end)

subscribe("SHOW_GUI", function(event, frame)
  subscribe("UPDATE_BINDINGS", UpdateBindings)
  subscribe("MODIFIER_CHANGED", UpdateButtons)
  subscribe("OFFSET_CHANGED", UpdateButtons)
  subscribe("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
  subscribe("PLAYER_TALENT_UPDATE", UpdateButtons)
  subscribe("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
  return UpdateBindings(event, frame)
end)

subscribe("HIDE_GUI", function(event, frame)
  unsubscribe("UPDATE_BINDINGS", UpdateBindings)
  unsubscribe("MODIFIER_CHANGED", UpdateButtons)
  unsubscribe("OFFSET_CHANGED", UpdateButtons)
  unsubscribe("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
  unsubscribe("PLAYER_TALENT_UPDATE", UpdateButtons)
  subscribe("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
  return event:next(frame)
end)

do
  local keyRegx = "^(%w+) (.*)$"
  local allMods = {"", "ALT-", "CTRL-", "SHIFT-", "ALT-CTRL-", "ALT-SHIFT-", "ALT-CTRL-SHIFT-", "CTRL-SHIFT-"}
  local function tmp()
    for i = 1, index do
      local button = buttons[i]
      for _, modifier in ipairs(allMods) do
        local binding = modifier..button.key
        local action = GetBindingAction(binding)
        local kind, info = string.match(action, keyRegx)

        if kind == "SPELL" then
          return binding, action, "spell", info

        elseif kind == "MACRO" then
          return binding, action, "macro", info

        elseif kind == "ITEM" then
          return binding, action, "item", info

        end
      end
    end
  end

  subscribe("IMPORT_BINDS", function(event)
    return event:next(tmp())
  end)
end
