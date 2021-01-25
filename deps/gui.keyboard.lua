local _, addon = ...
local subscribe, dispatch, unsubscribe, dbWrite, dbRead, spread = addon:get("subscribe", "dispatch", "unsubscribe", "dbWrite", "dbRead", "spread")
local index, buttons, mainbar, current, OnDragStart, OnReceiveDrag

local function OnEnterSlotTooltip(self)
  if not self:IsVisible() then return end
  GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
  GameTooltip:SetAction(self.id)
  current = self
end

local function OnEnterSpellTooltip(self)
  if not self:IsVisible() then return end
  GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
  GameTooltip:SetSpellByID(self.id)
  current = self
end

local function OnEnterMacroTooltip(self)
  if not self:IsVisible() then return end
  GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
  GameTooltip:SetText(self.id)
  current = self
end

local function OnEnterItemTooltip(self)
  if not self:IsVisible() then return end
  GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
  local _, _, _, level = GetItemInfo(self.id)
  GameTooltip:SetItemKey(self.id, level, 0)
  current = self
end

local function OnEnterOtherTooltip(self)
  if not self:IsVisible() then return end
  GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
  GameTooltip:SetText(GetBindingAction(self.id))
  current = self
end

local function OnLeaveTooltip(self)
  GameTooltip:Hide()
  current = nil
end

local function UpdateButton(self, frame, inCombat)
  local binding, kind, id = frame.modifier..self.key
  if mainbar[binding] then
    local slot = mainbar[binding] + frame.offset - 1
    kind, id = GetActionInfo(slot)
    self.Border:Show()
    self.Name:SetText(mainbar[binding])
    self.id = slot
    self:SetScript("OnEnter", OnEnterSlotTooltip)
    if kind == 'spell' then
      self.icon:SetTexture(select(3, GetSpellInfo(id)))
    elseif kind == 'macro' then
      self.icon:SetTexture(select(2, GetMacroInfo(id)))
    elseif kind == 'item' then
      self.icon:SetTexture(select(10, GetItemInfo(id)))
    else
      self.icon:SetTexture(nil)
    end
  else
    kind, id = spread(dbRead(nil, frame.spec, binding))
    self.Border:Hide()
    self.Name:SetText()
    self.id = id
    if kind == 'spell' then
      self.icon:SetTexture(select(3, GetSpellInfo(id)))
      self.icon:SetAlpha(1)
      self:SetScript("OnEnter", OnEnterSpellTooltip)
    elseif kind == 'macro' then
      self.icon:SetTexture(select(2, GetMacroInfo(id)))
      self.icon:SetAlpha(1)
      self:SetScript("OnEnter", OnEnterMacroTooltip)
    elseif kind == 'item' then
      self.icon:SetTexture(select(10, GetItemInfo(id)))
      self.icon:SetAlpha(1)
      self:SetScript("OnEnter", OnEnterItemTooltip)
    elseif GetBindingAction(binding) ~= "" then
      --self.icon:SetTexture(773178)
      self.icon:SetTexture(136006)
      self.icon:SetAlpha(0.5)
      self.id = binding
      self:SetScript("OnEnter", OnEnterOtherTooltip)
    else
      self.icon:SetTexture(nil)
      self.icon:SetAlpha(0.5)
      self.icon:SetColorTexture(0, 0, 0)
      self:SetScript("OnEnter", nil)
    end
  end
  if not inCombat then
    self:SetScript("OnDragStart", OnDragStart)
    self:SetScript("OnReceiveDrag", OnReceiveDrag)
    self:SetScript("OnClick", OnReceiveDrag)
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("AnyUp")
    self:SetAlpha(1.0)
  else
    self:SetScript("OnDragStart", nil)
    self:SetScript("OnReceiveDrag", nil)
    self:SetScript("OnClick", nil)
    self:RegisterForDrag(nil)
    self:RegisterForClicks(nil)
    self:SetAlpha(0.75)
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
  else
    return false
  end
  return true
end

function OnDragStart(self)
  local frame = self:GetParent()
  local binding = frame.modifier..self.key
  if mainbar[binding] then
    PickupAction(mainbar[binding] + frame.offset - 1)
  elseif PickupBinding(frame, spread(dbRead(nil, frame.spec, binding))) then
    dbWrite(nil, frame.spec, binding, nil)
    SetBinding(binding, nil)
    UpdateButton(self, frame)
  end
end

function OnReceiveDrag(self)
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
      button:SetScript("OnLeave", OnLeaveTooltip)
      button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
      tinsert(buttons, button)
    else
      button = buttons[index]
    end
    local key, x, y = select(i, unpack(layout))
    button.key = key
    button:SetPoint("TOPLEFT", 12+x, -y-12)
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
  frame:SetSize(xmax-xmin+12, ymax-ymin+12)
end

local function UpdateButtons(event, frame)
  local inCombat = InCombatLockdown() or event.key == "PLAYER_REGEN_DISABLED"
  for i = 1, index do
    UpdateButton(buttons[i], frame, inCombat)
  end
  if current then
    local fn = current:GetScript("OnEnter")
    if fn then
      fn(current)
    else
      GameTooltip:Hide()
    end
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
  --for k, v in pairs(GameTooltip) do
    --if type(v) == 'function' then
      --print(k)
    --end
  --end
  return event:unsub(frame):next(frame)
end)


subscribe("SHOW_GUI", function(event, frame)
  subscribe("UPDATE_BINDINGS", UpdateBindings)
  subscribe("MODIFIER_CHANGED", UpdateButtons)
  subscribe("OFFSET_CHANGED", UpdateButtons)
  subscribe("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
  subscribe("PLAYER_TALENT_UPDATE", UpdateButtons)
  subscribe("PLAYER_REGEN_DISABLED", UpdateButtons)
  subscribe("PLAYER_REGEN_ENABLED", UpdateButtons)
  subscribe("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
  return UpdateBindings(event, frame)
end)

subscribe("HIDE_GUI", function(event, frame)
  unsubscribe("UPDATE_BINDINGS", UpdateBindings)
  unsubscribe("MODIFIER_CHANGED", UpdateButtons)
  unsubscribe("OFFSET_CHANGED", UpdateButtons)
  unsubscribe("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
  unsubscribe("PLAYER_TALENT_UPDATE", UpdateButtons)
  unsubscribe("PLAYER_REGEN_DISABLED", UpdateButtons)
  unsubscribe("PLAYER_REGEN_ENABLED", UpdateButtons)
  unsubscribe("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
  return event:next(frame)
end)

--[[
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
]]
