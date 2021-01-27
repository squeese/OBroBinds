local _, ADDON = ...
local listen, release, match, rpush = ADDON.listen, ADDON.release, ADDON.match, ADDON.rpush

function ADDON:part(name)
  local value = self[name]
  self[name] = nil
  return value
end

----------------------------------------------------- frame, OnUpdate => MODIFIER_CHANGED
do
  -- TODO: cleanup
  local pAlt, pCtrl, pShift, modifier
  local function getModifier()
    local nAlt, nCtrl, nShift = IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
    if not (pAlt == nAlt and pCtrl == nCtrl and pShift == nShift) then
      pAlt, pCtrl, pShift = nAlt, nCtrl, nShift
      modifier = (pAlt and "ALT-" or "")..(pCtrl and "CTRL-" or "")..(pShift and "SHIFT-" or "")
    end
    return modifier
  end
  local elapsed = 0
  local function OnUpdate(self, delta)
    elapsed = elapsed + delta
    if elapsed < 0.1 then return end
    local modifier = getModifier()
    if modifier ~= self.modifier then
      self.modifier = modifier
      self:dispatch("MODIFIER_CHANGED")
    end
    elapsed = 0
  end
  function ADDON.InitializeModifierListener(e, frame)
    frame.modifier = getModifier()
    frame:SetScript("OnUpdate", OnUpdate)
    return e:once(frame)
  end
end

----------------------------------------------------- Stancebuttons
do
  local function UpdateButtons(e, frame)
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
    return e:next(frame)
  end
  local function UpdateOffset(e, frame, offset)
    frame.offset = offset ~= frame.offset and offset or 1
    return UpdateButtons(e, frame)
  end
  local function SetupListeners(e, frame)
    listen("OFFSET_CHANGED", UpdateOffset)
    listen("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
    return UpdateOffset(e, frame, frame.offset)
  end
  local function RemoveListeners(e, frame)
    release("OFFSET_CHANGED", UpdateOffset)
    release("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
    return e:next(frame)
  end
  local function OnClick(self)
    self:GetParent():dispatch("OFFSET_CHANGED", self.offset)
  end
  local function create(frame, offset, icon, ...)
    local button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
    button.offset = offset
    button.icon:SetTexture("Interface/Icons/"..icon)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", OnClick)
    return rpush(button, ...)
  end
  function ADDON.InitializeStanceHandler(e, frame)
    frame.offset = 1
    frame.stances = nil
    if frame.class == "ROGUE" then
      frame.stances = {
        create(frame, 73, 'ability_stealth', 1, 2, 3)}
    elseif true or frame.class == "DRUID" then
      frame.stances = {
        create(frame, 97,  'ability_racial_bearform',    1, 2, 3, 4),
        create(frame, 73,  'ability_druid_catform',      1, 2, 3, 4),
        create(frame, 109, 'spell_nature_forceofnature', 1)}
    else
      return e:once(frame)
    end
    listen("GUI_HIDE", RemoveListeners)
    listen("GUI_SHOW", SetupListeners)
    return SetupListeners(e:release(), frame)
  end
end

----------------------------------------------------- OverrideButtons
do
  local function UpdateMainbarButton(self, frame, binding, slot)
    local kind, id = GetActionInfo(slot)
    self.Border:Show()
    self.Name:SetText(frame.mainbar[binding])
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

  local function UpdateOverrideButton(self, frame, binding)
    local kind, id = select(3, frame:dispatch("GET_OVERRIDE_BINDING", binding))
    self.Border:Hide()
    self.Name:SetText()
    if kind == 'spell' then
      self.icon:SetTexture(select(3, GetSpellInfo(id)))
    elseif kind == 'macro' then
      self.icon:SetTexture(select(2, GetMacroInfo(id)))
    elseif kind == 'item' then
      self.icon:SetTexture(select(10, GetItemInfo(id)))
    elseif kind == 'blob' then
      self.icon:SetTexture(441148)
    --elseif GetBindingAction(binding) ~= "" then
      --self.icon:SetTexture(136006)
    else
      self.icon:SetTexture(nil)
    end
    if GetBindingAction(binding, false) ~= "" then
      self.AutoCastable:Show()
    else
      self.AutoCastable:Hide()
    end
  end

  local function UpdateButtons(e, frame)
    print("UpdateButtons", e.key)
    for index = 1, frame.index do
      local button = frame.buttons[index]
      local binding = frame.modifier..button.key
      if frame.mainbar[binding] then
        local slot = frame.mainbar[binding] + frame.offset - 1
        frame.mainbar[slot] = button
        UpdateMainbarButton(button, frame, binding, slot)
      else
        UpdateOverrideButton(button, frame, binding)
      end
    end
    return e:next(frame)
  end

  local UpdateBindings
  do
    --local pattern = "^(%w+) (.*)$"
    --local function actionToOverride(action)
      --local kind, info = string.match(action, pattern)
      --if kind == "SPELL" then
        --local id = select(7, GetSpellInfo(info))
        --if id then
          --return 'spell', id
        --end
      --elseif kind == "MACRO" then
        --if GetMacroInfo(info) == info then
          --return 'macro', info
        --end
      --elseif kind == "ITEM" then
        --local name, link = GetItemInfo(info)
        --local id = select(4, string.find(link, "^|c%x+|H(%a+):(%d+)[|:]"))
        --if name == info and id ~= nil then
          --return 'item', id
        --end
      --end
      --return nil
    --end
    --local modifiers = {"", "ALT-", "CTRL-", "SHIFT-", "ALT-CTRL-", "ALT-SHIFT-", "ALT-CTRL-SHIFT-", "CTRL-SHIFT-"}
    function UpdateBindings(e, frame)
      print("UpdateBindings", e.key, frame.mainbar)
      --for index = 1, frame.index do
        --local button = frame.buttons[index]
        --for _, modifier in ipairs(modifiers) do
          --local binding = modifier..button.key
          --local action = GetBindingAction(binding, false)
          --if action and action ~= "" then
            --local kind, id = actionToOverride(action)
            --if kind then
              --local dbKind, dbId = select(3, frame:dispatch("GET_OVERRIDE_BINDING", binding))
              --if not dbKind or (kind == dbKind and id == dbId) then
                --print("import", kind, id)
                --frame:UnregisterEvent("UPDATE_BINDINGS")
                --SetBinding(binding, nil)
                --SaveBindings(GetCurrentBindingSet())
                --frame:RegisterEvent("UPDATE_BINDINGS")
                --frame:dispatch("SET_OVERRIDE_BINDING", binding, kind, id)
              --end
            --end
          --end
        --end
      --end
      for key in pairs(frame.mainbar) do
        frame.mainbar[key] = nil
      end
      for index = 1, 12 do
        local binding = GetBindingKey("ACTIONBUTTON"..index)
        if binding then
          frame.mainbar[binding] = index
          frame:dispatch("DB_DEL_OVERRIDE", binding)
        end
      end
      return UpdateButtons(e, frame)
    end
  end
  local function ActionBarSlotChanged(e, frame, slot)
    if frame.mainbar[slot] then
      local button = frame.mainbar[slot]
      local binding = frame.modifier..button.key
      if binding == GetBindingKey("ACTIONBUTTON"..(slot - frame.offset + 1)) then
        UpdateMainbarButton(button, frame, binding, slot)
      end
    end
    return e:next(frame, slot)
  end
  local function SetupListeners(e, frame)
    listen("UPDATE_BINDINGS", UpdateBindings)
    listen("OFFSET_CHANGED", UpdateButtons)
    listen("MODIFIER_CHANGED", UpdateButtons)
    listen("PLAYER_TALENT_UPDATE", UpdateButtons)
    listen("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
    listen("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
    return UpdateBindings(e, frame)
  end
  local function RemoveListeners(e, frame)
    release("UPDATE_BINDINGS", UpdateBindings)
    release("OFFSET_CHANGED", UpdateButtons)
    release("MODIFIER_CHANGED", UpdateButtons)
    release("PLAYER_TALENT_UPDATE", UpdateButtons)
    release("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
    release("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
    return e:next(frame)
  end
  local function OnEnterTooltip(self)
    self:GetParent():dispatch("SHOW_TOOLTIP", self)
  end
  local function OnLeaveTooltip(self)
    GameTooltip:Hide()
  end
  local function OnClick(self, button)
    if InCombatLockdown() then return end
    if button == "RightButton" then
      self:GetParent():dispatch("SHOW_DROPDOWN", self)
    elseif GetCursorInfo() then
      self:GetParent():dispatch("RECEIVE_BINDING", self)
    end
  end
  local function OnDragStart(self)
    if InCombatLockdown() then return end
    self:GetParent():dispatch("PICKUP_BINDING", self)
  end
  local function OnReceiveDrag(self)
    if InCombatLockdown() then return end
    self:GetParent():dispatch("RECEIVE_BINDING", self)
  end
  function ADDON.InitializeButtonHandler(e, frame)
    -- TODO: cleanup
    frame.mainbar = {}
    frame.buttons = {}
    frame.index = 0
    local layout = ADDON.DEFAULT_KEYBOARD_LAYOUT
    local padding = 12
    local xmin, xmax = frame:GetLeft(), frame:GetRight()
    local ymin, ymax = frame:GetBottom(), frame:GetTop()
    local button
    for i = 1, #layout, 3 do
      frame.index = frame.index + 1
      if frame.index > #frame.buttons then
        button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
        button:SetScript("OnEnter", OnEnterTooltip)
        button:SetScript("OnLeave", OnLeaveTooltip)
        button:SetScript("OnClick", OnClick)
        button:SetScript("OnDragStart", OnDragStart)
        button:SetScript("OnReceiveDrag", OnReceiveDrag)
        button:RegisterForDrag("LeftButton")
        button:RegisterForClicks("AnyUp")
        button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        --button.notice = button:CreateTexture(nil, )
        table.insert(frame.buttons, button)
      else
        button = frame.buttons[frame.index]
      end
      local key, x, y = select(i, unpack(layout))
      button.key = key
      button:SetPoint("TOPLEFT", padding+x, -y-padding-12)
      button.Border:Hide()
      button.Border:SetAlpha(1)
      button.HotKey:SetText(key)
      button.Name:SetText()
      --button.LevelLinkLockIcon:Show()
      --button.AutoCastable:Show()
      --button.SpellHighlightTexture:Show()
      --button.NewActionTexture:Show()
      xmin = math.min(xmin, button:GetLeft())
      xmax = math.max(xmax, button:GetRight())
      ymin = math.min(ymin, button:GetBottom())
      ymax = math.max(ymax, button:GetTop())
    end
    for i = frame.index+1, #frame.buttons do
      button = frame.buttons[frame.index]
      button:Hide()
    end
    frame:SetSize(xmax-xmin+padding, ymax-ymin+padding)
    listen("GUI_HIDE", RemoveListeners)
    listen("GUI_SHOW", SetupListeners)
    return SetupListeners(e:release(), frame)
  end
end

----------------------------------------------------- Tooltips for override buttons
do
  local function update(frame, button)
    if not button:IsVisible() then return end
    GameTooltip:SetOwner(button, 'ANCHOR_BOTTOMRIGHT')
    local binding = frame.modifier..button.key
    if frame.mainbar[binding] then
      GameTooltip:SetAction(frame.mainbar[binding] + frame.offset - 1)
      return
    end
    local kind, id = select(3, frame:dispatch("GET_OVERRIDE_BINDING", binding))
    if kind == 'spell' then
      GameTooltip:SetSpellByID(id)
    elseif kind == 'macro' then
      GameTooltip:SetText("MACRO: "..id)
    elseif kind == 'item' then
      local _, _, _, level = GetItemInfo(id)
      GameTooltip:SetItemKey(id, level, 0)
    elseif kind == 'blob' then
      GameTooltip:SetText("BLOB: "..id)
    elseif GetBindingAction(binding) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding))
    else
      GameTooltip:Hide()
    end
  end
  local current
  local function UpdateTooltip(e, frame, button)
    current = button
    update(frame, button)
    return e:next(frame, button)
  end
  local function RefreshTooltip(e, frame, ...)
    if current and GetMouseFocus() == current then
      update(frame, current)
    end
    return e:next(frame, ...)
  end
  local function SetupListeners(e, frame)
    listen("SHOW_TOOLTIP", UpdateTooltip)
    listen("OFFSET_CHANGED", RefreshTooltip)
    listen("UPDATE_BINDINGS", RefreshTooltip)
    listen("MODIFIER_CHANGED", RefreshTooltip)
    listen("PLAYER_TALENT_UPDATE", RefreshTooltip)
    listen("PLAYER_SPECIALIZATION_CHANGED", RefreshTooltip)
    return e:next(frame)
  end
  local function RemoveListeners(e, frame)
    release("SHOW_TOOLTIP", UpdateTooltip)
    release("OFFSET_CHANGED", RefreshTooltip)
    release("UPDATE_BINDINGS", RefreshTooltip)
    release("MODIFIER_CHANGED", RefreshTooltip)
    release("PLAYER_TALENT_UPDATE", RefreshTooltip)
    release("PLAYER_SPECIALIZATION_CHANGED", RefreshTooltip)
    return e:next(frame)
  end
  function ADDON.InitializeTooltipHandler(e, frame)
    listen("GUI_HIDE", RemoveListeners)
    listen("GUI_SHOW", SetupListeners)
    return SetupListeners(e:release(), frame)
  end
end





do
  local info, dropdown
  local function UpdateDropdown(e, frame, button)
    info.arg1 = button
    ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
    return e:next(frame, button)
  end
  local function SetupListeners(e, frame)
    listen("SHOW_DROPDOWN", UpdateDropdown)
    return e:next(frame)
  end
  local function RemoveListeners(e, frame)
    release("SHOW_DROPDOWN", UpdateDropdown)
    return e:next(frame)
  end
  function ADDON.InitializeDropdownHandler(e, frame)
    info = UIDropDownMenu_CreateInfo()
    dropdown = CreateFrame("frame", nil, UIParent, "UIDropDownMenuTemplate")
    dropdown.displayMode = "MENU"
    function dropdown:initialize()
      local binding = frame.modifier..info.arg1.key
      info.arg2 = binding

      info.text = binding
      info.isTitle = true
      info.notCheckable = true
      UIDropDownMenu_AddButton(info)
      --UIDropDownMenu_AddSpace()
      UIDropDownMenu_AddSeparator(1)
      UIDropDownMenu_AddButton(info)
      -- remove override
      -- remove binding
      -- create macro
    end
    listen("GUI_HIDE", RemoveListeners)
    listen("GUI_SHOW", SetupListeners)
    return SetupListeners(e:release(), frame)
  end
end
