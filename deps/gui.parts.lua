local _, ADDON = ...
local listen, release, match, rpush, read = ADDON.listen, ADDON.release, ADDON.match, ADDON.rpush, ADDON.read






----------------------------------------------------- frame, OnUpdate => MODIFIER_CHANGED

----------------------------------------------------- Stancebuttons
do
  local function UpdateButtons(e, frame)
    local prev
    for _, button in ipairs(frame.stances) do
      if match(frame.spec, unpack(button)) then
        button:Show()
        button:ClearAllPoints()
        if not prev then
          button:SetPoint("LEFT", frame, "TOPLEFT", 12, 4)
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

----------------------------------------------------- Find missing icons for spells
do
  local KIND, ID, NAME, ICON = 1, 2, 3, 4
  local function Update(e, frame)
    local overrides = read(OBroBindsDB, frame.class, frame.spec)
    if overrides then
      for binding, action in pairs(overrides) do
        if not action[ID] then
          local icon, _, _, _, id = select(3, GetSpellInfo(action[NAME]))
          action[ID], action[ICON] = id, icon or action[ICON]
        end
      end
    end
    return e:next(frame)
  end
  local function SetupListeners(e, frame)
    listen("PLAYER_SPECIALIZATION_CHANGED", Update)
    listen("PLAYER_TALENT_UPDATE", Update)
    return e:next(frame)
  end
  local function RemoveListeners(e, frame)
    release("PLAYER_SPECIALIZATION_CHANGED", Update)
    release("PLAYER_TALENT_UPDATE", Update)
    return e:next(frame)
  end
  function ADDON.InitializeMissingIconHandler(e, frame)
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
    local kind, id, name, icon, locked = select(3, frame:dispatch("GET_OVERRIDE_BINDING", binding))
    self.Border:Hide()
    self.Name:SetText()
    local hasBinding = GetBindingAction(binding, false) ~= ""
    self.icon:SetVertexColor(1, 1, 1, 1)
    if kind == 'SPELL' then
      self.icon:SetTexture(select(3, GetSpellInfo(id)) or icon)
    elseif kind == 'MACRO' then
      self.icon:SetTexture(select(2, GetMacroInfo(name)) or icon)
    elseif kind == 'ITEM' then
      self.icon:SetTexture(select(10, GetItemInfo(id or 0)) or icon)
    elseif kind == 'blob' then
      self.icon:SetTexture(441148)
    elseif hasBinding then
      self.icon:SetTexture(136243)
      self.icon:SetVertexColor(0.8, 1, 0.1, 0.1)
    else
      self.icon:SetTexture(nil)
    end
    if hasBinding then
      self.AutoCastable:Show()
    else
      self.AutoCastable:Hide()
    end
    if locked then
      self.LevelLinkLockIcon:Show()
    else
      self.LevelLinkLockIcon:Hide()
    end
  end

  local function Update(self)
    frame = frame or self:GetParent()
    local binding = frame.modifier..self.key
    if frame.mainbar[binding] then
      local slot = frame.mainbar[binding] + frame.offset - 1
      frame.mainbar[slot] = self
      UpdateMainbarButton(self, frame, binding, slot)
    else
      UpdateOverrideButton(self, frame, binding)
    end
  end

  local function UpdateButtons(e, frame)
    print("UpdateButtons", e.key)
    for index = 1, frame.index do
      frame.buttons[index]:Update(frame)
    end
    return e:next(frame)
  end

  local function UpdateBindings(e, frame)
    print("UpdateBindings", e.key, frame.mainbar)
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
    listen("UPDATE_MACROS", UpdateButtons)
    listen("OFFSET_CHANGED", UpdateButtons)
    listen("MODIFIER_CHANGED", UpdateButtons)
    listen("PLAYER_TALENT_UPDATE", UpdateButtons)
    listen("PLAYER_SPECIALIZATION_CHANGED", UpdateButtons)
    listen("ACTIONBAR_SLOT_CHANGED", ActionBarSlotChanged)
    return UpdateBindings(e, frame)
  end
  local function RemoveListeners(e, frame)
    release("UPDATE_BINDINGS", UpdateBindings)
    release("UPDATE_MACROS", UpdateButtons)
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
      local frame = self:GetParent()
      local binding = frame.modifier..self.key
      if not frame.mainbar[binding] then
        frame:dispatch("SHOW_DROPDOWN", self)
      end
    elseif GetCursorInfo() then
      self:GetParent():dispatch("RECEIVE_BINDING", self)
      self:Update()
    end
  end
  local function OnDragStart(self)
    if InCombatLockdown() then return end
    self:GetParent():dispatch("PICKUP_BINDING", self)
    self:Update()
  end
  local function OnReceiveDrag(self)
    if InCombatLockdown() then return end
    self:GetParent():dispatch("RECEIVE_BINDING", self)
    self:Update()
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
        button.Update = Update
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
      --button.AutoCastable:SetTexCoord(0, 0.5, 0.5, 1)
      button.AutoCastable:SetTexCoord(0.15, 0.6, 0.6, 0.15)
      button.AutoCastable:ClearAllPoints()
      button.AutoCastable:SetPoint("BOTTOMLEFT", -14, -12)
      button.AutoCastable:SetScale(0.4)
      button.AutoCastable:SetAlpha(0.75)
      --button.LevelLinkLockIcon:Show()
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
  local function actionPromotable(action, oKind, id)
    local kind, info = string.match(action, "^(%w+) (.*)$")
    if kind == 'SPELL' then return true end
    if kind == 'MACRO' then return true end
    if kind == 'ITEM' then return true end
  end
  local function RemoveOverride(self, button, binding)
    button:GetParent():dispatch("OVERRIDE_DEL", true, binding)
    button:Update()
    CloseDropDownMenus()
  end
  local function RemoveBinding(self, _, binding)
    SetBinding(binding, nil)
    SaveBindings(GetCurrentBindingSet())
    CloseDropDownMenus()
  end
  local function PromoteBinding(self, button, binding)
    button:GetParent():dispatch("OVERRIDE_PROMOTE", binding)
    SetBinding(binding, nil)
    SaveBindings(GetCurrentBindingSet())
    CloseDropDownMenus()
  end
  local function LockBinding(self, button, binding)
    button:GetParent():dispatch("OVERRIDE_LOCK", binding)
    button:Update()
    CloseDropDownMenus()
  end

  local function set(i, level, ...)
    i.text, i.hasArrow, i.menuList, i.isTitle, i.disabled, i.notCheckable, i.checked, i.func = ...
    UIDropDownMenu_AddButton(i, level)
  end

  function _A.InitializeTooltipHandler(self, _, section)
    local button = self.info.arg1
    local frame = button:GetParent()
    local binding = frame.modifier..button.key
    local i = self.info
    i.arg2 = binding

    if section == "root" then
      set(i, 1, "Override", false, nil, true, true, true, false, nil)
      local kind, id, name, _, locked = select(3, frame:dispatch("GET_OVERRIDE_BINDING", binding))
      set(i, 1, not kind and 'none' or kiknd.." "..name, not locked, "override", false, locked, true, false, nil)

      UIDropDownMenu_AddSeparator(1)
      set(i, 1, "Binding", false, nil, true, true, true, false, nil)
      local action = GetBindingAction(binding, false)
      set(i, 1, action == "" and "none" or action, not locked and action ~= "", "binding", false, false, true, false, nil)
      set(i, 1, locked and "Unlock" or "Lock", false, nil, false, false, false, locked, LockBinding)

    elseif section == "override" then
      --info.hasArrow = false
      --info.menuList = nil
      --info.isTitle = false
      --info.disabled = false
      --info.notCheckable = true
      --info.checked = false

      --local kind = select(3, frame:dispatch("GET_OVERRIDE_BINDING", binding))
      --if kind == 'blob' then
        --info.text = "Edit blob"
        --info.func = EditBlob
        --UIDropDownMenu_AddButton(info, 2)
      --end
      --if kind then
        --info.text = "Clear override"
        --info.func = RemoveOverride
        --UIDropDownMenu_AddButton(info, 2)
      --end
      --if not kind then
        --info.text = "Create blob"
        --info.func = CreateBlob
        --UIDropDownMenu_AddButton(info, 2)
      --end

    elseif section == "binding" then
      --info.hasArrow = false
      --info.menuList = nil
      --info.isTitle = false
      --info.disabled = false

      --local action = GetBindingAction(binding, false)
      --if actionPromotable(action, select(3, frame:dispatch("GET_OVERRIDE_BINDING", binding))) then
        --info.text = "Promote to override"
        --info.func = PromoteBinding
        --UIDropDownMenu_AddButton(info, 2)
      --end

      --info.text = "Clear binding"
      --info.func = RemoveBinding
      --UIDropDownMenu_AddButton(info, 2)
    end
  end
end
