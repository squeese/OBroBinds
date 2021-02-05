local scope = select(2, ...)

do
  local elapsed, pa, pc, ps, modifier = 0, IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
  local function OnUpdate(self, delta)
    elapsed = elapsed + delta
    if elapsed < 0.1 then return end
    local na, nc, ns = IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
    if pa ~= na or pc ~= nc or ps ~= ns then
      pa, pc, ps = na, nc, ns
      scope.modifier = (pa and "ALT-" or "")..(pc and "CTRL-" or "")..(ps and "SHIFT-" or "")
      scope:dispatch("ADDON_MODIFIER_CHANGED")
    end
    elapsed = 0
  end
  local function OnClick(self)
    scope.offset = self.offset ~= scope.offset and self.offset or 1
    scope:dispatch("ADDON_OFFSET_CHANGED")
  end
  local function CreateStanceButton(offset, icon, ...)
    local button = CreateFrame("button", nil, scope.keyboard, "ActionButtonTemplate")
    button.offset = offset
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", OnClick)
    button.icon:SetTexture("Interface/Icons/"..icon)
    return scope.push(button, ...)
  end
  function scope.InitializePageKeyboard(e, ...)
    scope.keyboard:SetScript("OnUpdate", OnUpdate)
    scope.modifier = (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")
    scope.buttons = {}
    scope.offset = 1
    scope.mainbar = nil
    scope.stances = nil
    if scope.class == "ROGUE" then
      scope.write(scope, 'stances', scope.push, CreateStanceButton(73,  'ability_stealth',            1, 2, 3))
    elseif scope.class == "DRUID" then
      scope.write(scope, 'stances', scope.push, CreateStanceButton(97,  'ability_racial_bearform',    1, 2, 3, 4))
      scope.write(scope, 'stances', scope.push, CreateStanceButton(73,  'ability_druid_catform',      1, 2, 3, 4))
      scope.write(scope, 'stances', scope.push, CreateStanceButton(109, 'spell_nature_forceofnature', 1))
    end
    return e(scope.DEFAULT_KEYBOARD_LAYOUT, ...)
  end
end

local CreateActionButton
do
  local function OnEnter(self)
    scope:dispatch("ADDON_SHOW_TOOLTIP", self)
  end
  local function OnLeave()
    GameTooltip:Hide()
  end
  local function OnDragStart(self)
    if InCombatLockdown() then return end
    scope.PickupAction(self.binding)
    self:UpdateButton()
  end
  local function OnReceiveDrag(self)
    if InCombatLockdown() then return end
    scope.ReceiveAction(self.binding)
    self:UpdateButton()
  end
  local function OnClick(self, button)
    if InCombatLockdown() then return end
    if button == "RightButton" then
      local binding = scope.modifier..self.key
      if not scope.mainbar[binding] then
        scope:dispatch("ADDON_SHOW_DROPDOWN", self)
      end
    elseif GetCursorInfo() then
      scope.ReceiveAction(self.binding)
      self:UpdateButton()
    end
  end
  function CreateActionButton()
    local button = CreateFrame("button", nil, scope.keyboard, "ActionButtonTemplate")
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnReceiveDrag", OnReceiveDrag)
    button:SetScript("OnClick", OnClick)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("AnyUp")
    button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    button.AutoCastable:SetTexCoord(0.15, 0.6, 0.6, 0.15)
    button.AutoCastable:ClearAllPoints()
    button.AutoCastable:SetPoint("BOTTOMLEFT", -14, -12)
    button.AutoCastable:SetScale(0.4)
    button.AutoCastable:SetAlpha(0.75)
    button.kind = button:CreateTexture(nil, "OVERLAY")
    button.kind:SetPoint("BOTTOMLEFT", 0, 0)
    button.kind:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, 14)
    --button.kind:SetSize(12, 12)
    --button.kind:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    button.kind:SetColorTexture(0, 0, 0, 0.75)
    return button
  end
end

do
  local function UpdateButton(self)
    local binding = scope.modifier..self.key
    self.binding = binding
    if scope.mainbar[binding] then
      local kind, id = GetActionInfo(scope.mainbar[binding] + scope.offset - 1)
      --self.Border:Show()
      self.SpellHighlightTexture:Show()
      self.kind:Hide()
      self.Name:SetText(scope.mainbar[binding])
      self.icon:SetVertexColor(1, 1, 1, 1)
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
      --self.Border:Hide()
      self.SpellHighlightTexture:Hide()
      self.Name:SetText()
      local action = scope.GetAction(binding)
      local command = GetBindingAction(binding, false)
      local hasCommand = command ~= ""
      local icon = action.kind and action:Icon()
      if icon then
        self.icon:SetVertexColor(1, 1, 1, 1)
        self.icon:SetTexture(icon)
      elseif hasCommand then
        self.icon:SetVertexColor(0.8, 1, 0.3, 0.5)
        if command == "MOVEFORWARD" then
          self.icon:SetTexture(450907)
        elseif command == "MOVEBACKWARD" then
          self.icon:SetTexture(450905)
        elseif command == "STRAFELEFT" then
          self.icon:SetTexture(450906)
        elseif command == "STRAFERIGHT" then
          self.icon:SetTexture(450908)
        else
          local kind, name = string.match(command, "^(%w+) (.*)$")
          self.icon:SetVertexColor(0.4, 1, 0.4, 0.1)
          if kind == "SPELL" then
            self.icon:SetTexture(1519263)
          elseif kind == "MACRO" then
            self.icon:SetTexture("Interface\\MacroFrame\\MacroFrame-Icon")
          elseif kind == "ITEM" then
            self.icon:SetTexture(979584)
          else
            self.icon:SetTexture(892831)
            self.icon:SetVertexColor(1, 0.4, 0.8, 0.2)
          end
        end
      else
        self.icon:SetTexture(nil)
      end
      if hasCommand then
        self.AutoCastable:Show()
      else
        self.AutoCastable:Hide()
      end
      if action.locked then
        self.LevelLinkLockIcon:Show()
      else
        self.LevelLinkLockIcon:Hide()
      end
      if action.BLOB then
        self.kind:Show()
        self.Name:SetText(action.id)
      else
        self.kind:Hide()
        --self.Name:SetText("")
      end
    end
  end

  local padding, mmin, mmax = 12, math.min, math.max
  function scope.UpdateKeyboardLayout(e, layout, ...)
    scope.index = 0
    scope.keyboard:ClearAllPoints()
    scope.keyboard:SetPoint("TOPLEFT", padding, -padding)
    scope.keyboard:SetSize(1, 1)
    local xmin, xmax = scope.keyboard:GetLeft(), scope.keyboard:GetRight()
    local ymin, ymax = scope.keyboard:GetBottom(), scope.keyboard:GetTop()
    local button
    for key in pairs(scope.buttons) do
      if type(key) == "string" then
        scope.button[key] = nil
      end
    end
    for i = 1, #layout, 3 do
      scope.index = scope.index + 1
      if scope.index > #scope.buttons then
        button = CreateActionButton()
        button.UpdateButton = UpdateButton
        table.insert(scope.buttons, button)
      else
        button = scope.buttons[scope.index]
      end
      local key, x, y = select(i, unpack(layout))
      button.key = key
      scope.buttons[key] = button
      button:SetPoint("TOPLEFT", x, -y-20)
      button.Border:Hide()
      button.Border:SetAlpha(1)
      button.HotKey:SetText(key)
      button.Name:SetText()
      xmin = mmin(xmin, button:GetLeft())
      xmax = mmax(xmax, button:GetRight())
      ymin = mmin(ymin, button:GetBottom())
      ymax = mmax(ymax, button:GetTop())
    end
    for i = scope.index+1, #scope.buttons do
      button = scope.buttons[scope.index]
      button:Hide()
    end
    local w, h = xmax-xmin, ymax-ymin
    scope.root:SetSize(w+padding*2, h+padding*2)
    scope.keyboard:SetSize(w, h)
    return e(...)
  end
end

function scope.UpdateKeyboardStanceButtons(e, ...)
  if scope.stances then
    local prev
    for _, button in ipairs(scope.stances) do
      button:Hide()
      if scope.match(scope.spec, unpack(button)) then
        button:Show()
        button:ClearAllPoints()
        if not prev then
          button:SetPoint("TOPLEFT", scope.keyboard, "BOTTOMLEFT", 0, -10)
        else
          button:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        end
        button.Border:Hide()
        if scope.offset == button.offset then
          button.Border:Show()
        end
        prev = button
      end
    end
  end
  return e(...)
end

do
  local pattern = "^(.--?)([^-]*.)$"
  local function UpdateButton(binding)
    local modifier, key = string.match(binding, pattern)
    if scope.modifier == modifier then
      scope.buttons[key]:UpdateButton()
    end
  end
  local prev
  function scope.UpdateKeyboardMainbarIndices(e, ...)
    prev, scope.mainbar = scope.mainbar, scope.clean(prev or {})
    for index = 1, 12 do
      local binding = GetBindingKey("ACTIONBUTTON"..index)
      if binding then
        scope.mainbar[binding] = index
        scope.DeleteAction(binding)
        if prev then
          if prev[binding] ~= scope.mainbar[binding] then
            UpdateButton(binding)
          end
          prev[binding] = nil
        end
      end
    end
    if prev then
      for binding in pairs(prev) do
        UpdateButton(binding)
      end
    end
    return e(...)
  end

  function scope.UpdateKeyboardMainbarSlots(e, slot, ...)
    local index = slot-scope.offset+1
    local binding = GetBindingKey("ACTIONBUTTON"..index)
    if binding and 1 <= index and index <= 12 then
      assert(scope.mainbar[binding] == index)
      UpdateButton(binding)
    end
    return e(slot, ...)
  end

  function scope.UpdateKeyboardMainbarOffsets(e, ...)
    for binding, index in pairs(scope.mainbar) do
      UpdateButton(binding)
    end
    return e(...)
  end
end

function scope.UpdateAllKeyboardButtons(e, ...)
  for index = 1, scope.index do
    scope.buttons[index]:UpdateButton()
  end
  return e(...)
end

do
  local function Update(button)
    if not button:IsVisible() then return end
    GameTooltip:SetOwner(button, 'ANCHOR_BOTTOMRIGHT')
    local binding = scope.modifier..button.key
    if scope.mainbar[binding] then
      GameTooltip:SetAction(scope.mainbar[binding] + scope.offset - 1)
      return
    end
    local action = scope.GetAction(binding)
    if action.SPELL then
      if action.id and GetSpellInfo(action.id) then
        GameTooltip:SetSpellByID(action.id)
      else
        GameTooltip:SetText("SPELL "..action.name)
      end
    elseif action.MACRO then
      GameTooltip:SetText("MACRO "..action.name)
    elseif action.ITEM then
      local level = select(4, GetItemInfo(action.id or 0))
      if action.id and level then
        GameTooltip:SetItemKey(action.id, level, 0)
      else
        GameTooltip:SetText("ITEM "..action.name)
      end
    elseif action.BLOB then
      GameTooltip:SetText("BLOB "..action.id)
      GameTooltip:AddLine(action.name)
      GameTooltip:Show()

    elseif GetBindingAction(binding, false) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding, false))
    elseif GetBindingAction(binding, true) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding, true))
    else
      GameTooltip:Hide()
    end
  end
  local current
  function scope.UpdateTooltip(e, button, ...)
    current = button
    Update(button)
    return e(button, ...)
  end
  function scope.RefreshTooltip(e, ...)
    if current and GetMouseFocus() == current then
      Update(current)
    end
    return e(...)
  end
end

function scope.UpdateUnknownSpells(e, ...)
  for binding, action in scope.GetActions() do
    if action.SPELL and not action.id then
      local icon, _, _, _, id = select(3, GetSpellInfo(action.name))
      action[2], action[4] = id, icon or action.icon
    end
  end
  return e(...)
end

do
  local function RemoveOverride(self, button, binding)
    scope.DeleteAction(binding)
    --button:UpdateButton()
    CloseDropDownMenus()
  end
  local function RemoveBinding(self, button, binding)
    SetBinding(binding, nil)
    SaveBindings(GetCurrentBindingSet())
    button:UpdateButton()
    CloseDropDownMenus()
  end
  local function PromoteBinding(self, button, binding)
    scope.PromoteToAction(binding)
    SetBinding(binding, nil)
    SaveBindings(GetCurrentBindingSet())
    --button:UpdateButton()
    CloseDropDownMenus()
  end
  local function LockBinding(self, button, binding)
    scope.ToggleActionLock(binding)
    --button:UpdateButton()
    CloseDropDownMenus()
  end
  local function CreateBlob(self, button, binding)
    scope.SaveAction(binding, "BLOB", binding, "", 3615513)
    --button:UpdateButton()
    CloseDropDownMenus()
  end
  local function EditBlob(self, button, binding)
    scope:dispatch("ADDON_EDITOR_SHOW")
    scope:dispatch("ADDON_EDITOR_SELECT", binding)
    CloseDropDownMenus()
  end

  local drop, info
  local function reset()
    info.hasArrow = false
    info.menuList = nil
    info.isTitle = false
    info.disabled = false
    info.notCheckable = true
    info.checked = false
    info.func = nil
  end

  local function InitializeDropdown(self, _, section)
    local button = info.arg1
    local binding = scope.modifier..button.key
    info.arg2 = binding
    if section == "root" then
      local action = scope.GetAction(binding)
      local command = GetBindingAction(binding, false)

      reset()
      info.text = "Override"
      info.isTitle = true
      UIDropDownMenu_AddButton(info, 1)

      reset()
      if not action.kind then
        info.text = 'none'
      elseif action.BLOB then
        info.text = action.id
      else
        info.text = action.kind.." "..action.name
      end
      info.hasArrow = action.kind and not action.locked
      info.menuList = "override"
      info.disabled = not action.kind or action.locked
      UIDropDownMenu_AddButton(info, 1)

      if action.BLOB then
        reset()
        info.text = "Edit blob"
        info.func = EditBlob
        UIDropDownMenu_AddButton(info, 1)
      elseif not action.kind then
        reset()
        info.text = "Create blob"
        info.func = CreateBlob
        UIDropDownMenu_AddButton(info, 1)
      end

      reset()
      info.text = "Binding"
      info.isTitle = true
      UIDropDownMenu_AddSeparator(1)
      UIDropDownMenu_AddButton(info, 1)

      reset()
      info.text = command == "" and "none" or command
      info.hasArrow = not action.locked and command ~= ""
      info.menuList = "binding"
      info.disabled = not info.hasArrow
      UIDropDownMenu_AddButton(info, 1)

      reset()
      info.text = action.locked and "Unlock" or "Lock"
      info.notCheckable = false
      info.checked = action.locked
      info.func = LockBinding
      UIDropDownMenu_AddSeparator(1)
      UIDropDownMenu_AddButton(info, 1)

    elseif section == "override" then
      local action = scope.GetAction(binding)

      if action.kind then
        reset()
        info.text = "Clear override"
        info.func = RemoveOverride
        UIDropDownMenu_AddButton(info, 2)
      end

    elseif section == "binding" then
      local command = GetBindingAction(binding, false)
      local kind, name = string.match(command, "^(%w+) (.*)$")
      if kind == 'SPELL' or kind == 'MACRO' or kind == 'ITEM' then
        reset()
        info.text = "Promote to override"
        info.func = PromoteBinding
        UIDropDownMenu_AddButton(info, 2)
      end
      if kind == 'MACRO' then
        reset()
        info.text = "Import to blob"
        info.func = scope.ImportMacroToAction
        UIDropDownMenu_AddButton(info, 2)
      end
      reset()
      info.text = "Clear binding"
      info.func = RemoveBinding
      UIDropDownMenu_AddButton(info, 2)
    end
  end

  function scope.UpdateDropdown(e, button, ...)
    if not drop then
      info = UIDropDownMenu_CreateInfo()
      drop = CreateFrame("frame", nil, UIParent, "UIDropDownMenuTemplate")
      drop.displayMode = "MENU"
      drop.initialize = InitializeDropdown
    end
    info.arg1 = button
    ToggleDropDownMenu(1, nil, drop, "cursor", 0, 0, "root")
    return e(button, ...)
  end
end
