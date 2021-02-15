local scope = select(2, ...)
do
  local elapsed, pa, pc, ps, modifier = 0, IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
  local function OnUpdate(self, delta)
    elapsed = elapsed + delta
    if elapsed < 0.1 then return end
    local na, nc, ns = IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
    if pa ~= na or pc ~= nc or ps ~= ns then
      pa, pc, ps = na, nc, ns
      scope.MODIFIER = (pa and "ALT-" or "")..(pc and "CTRL-" or "")..(ps and "SHIFT-" or "")
      scope:dispatch("ADDON_MODIFIER_CHANGED")
    end
    elapsed = 0
  end
  function scope.InitializeKeyboardModifierListener()
    scope.InitializeKeyboardModifierListener = nil
    scope.KEYBOARD:SetScript("OnUpdate", OnUpdate)
    scope.MODIFIER = (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")
  end
end

do
  local function OnClick(self)
    scope.STANCE_OFFSET = self.STANCE_OFFSET ~= scope.STANCE_OFFSET and self.STANCE_OFFSET or 1
    scope:dispatch("ADDON_OFFSET_CHANGED")
  end
  local function CreateStanceButton(offset, icon, ...)
    local button = CreateFrame("button", nil, scope.KEYBOARD, "ActionButtonTemplate")
    button.STANCE_OFFSET = offset
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", OnClick)
    button.icon:SetTexture("Interface/Icons/"..icon)
    return scope.push(button, ...)
  end
  function scope.InitializeKeyboardStanceButtons()
    scope.InitializeKeyboardStanceButtons = nil
    if scope.CLASS == "ROGUE" then
      scope.write(scope, 'STANCE_BUTTONS', scope.push, CreateStanceButton(73,  'ability_stealth',            1, 2, 3))
    elseif scope.CLASS == "DRUID" then
      scope.write(scope, 'STANCE_BUTTONS', scope.push, CreateStanceButton(97,  'ability_racial_bearform',    1, 2, 3, 4))
      scope.write(scope, 'STANCE_BUTTONS', scope.push, CreateStanceButton(73,  'ability_druid_catform',      1, 2, 3, 4))
      scope.write(scope, 'STANCE_BUTTONS', scope.push, CreateStanceButton(109, 'spell_nature_forceofnature', 1))
    end
  end
end

local CreateActionButton
do
  local function UpdateActionButton(self)
    local binding = scope.MODIFIER..self.key
    self.binding = binding
    if scope.PORTAL_BUTTONS[binding] then
      local kind, id = GetActionInfo(scope.PORTAL_BUTTONS[binding] + scope.STANCE_OFFSET - 1)
      self.SpellHighlightTexture:Show()
      self.kind:Hide()
      self.Name:SetText(scope.PORTAL_BUTTONS[binding])
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
      self.SpellHighlightTexture:Hide()
      self.Name:SetText()
      local action = scope.GetAction(binding)
      local command = GetBindingAction(binding, false)
      local hasCommand = command ~= ""
      local icon = action.kind and scope.ActionIcon(action)
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
      if action.lock then
        self.LevelLinkLockIcon:Show()
      else
        self.LevelLinkLockIcon:Hide()
      end
      if action.blob then
        self.kind:Show()
        self.Name:SetText(scope.dbRead("BLOBS", action.id, "name"))
      else
        self.kind:Hide()
      end
    end
  end
  local function OnEnter(self)
    scope:dispatch("ADDON_SHOW_TOOLTIP", self)
  end
  local function OnLeave()
    GameTooltip:Hide()
  end
  local function OnDragStart(self)
    if InCombatLockdown() then return end
    if scope.PickupAction(self.binding) then
      self:Update()
    end
  end
  local function OnReceiveDrag(self)
    if InCombatLockdown() then return end
    if scope.ReceiveAction(self.binding) then
      self:Update()
    end
  end
  local function OnClick(self, button)
    if InCombatLockdown() then return end
    if button == "RightButton" then
      local binding = scope.MODIFIER..self.key
      if not scope.PORTAL_BUTTONS[binding] then
        scope:dispatch("ADDON_SHOW_DROPDOWN", self)
      end
    elseif GetCursorInfo() and scope.ReceiveAction(self.binding) then
      self:Update()
    end
  end
  function CreateActionButton()
    local button = CreateFrame("button", nil, scope.KEYBOARD, "ActionButtonTemplate")
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnReceiveDrag", OnReceiveDrag)
    button:SetScript("OnClick", OnClick)
    button.Update = UpdateActionButton
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
    button.kind:SetColorTexture(0, 0, 0, 0.75)
    return button
  end
end

do
  local padding, mmin, mmax = 12, math.min, math.max
  local tinsert = table.insert
  function scope.UpdateKeyboardLayout(next, layout, ...)
    scope.KEYBOARD:ClearAllPoints()
    scope.KEYBOARD:SetPoint("TOPLEFT", padding, -padding)
    scope.KEYBOARD:SetSize(1, 1)
    scope.ACTION_BUTTONS = scope.ACTION_BUTTONS or {}
    scope.ACTION_INDEX = 0
    local xmin, xmax = scope.KEYBOARD:GetLeft(), scope.KEYBOARD:GetRight()
    local ymin, ymax = scope.KEYBOARD:GetBottom(), scope.KEYBOARD:GetTop()
    local button
    for key in pairs(scope.ACTION_BUTTONS) do
      if type(key) == "string" then
        scope.button[key] = nil
      end
    end
    for i = 1, #layout, 3 do
      scope.ACTION_INDEX = scope.ACTION_INDEX + 1
      if scope.ACTION_INDEX > #scope.ACTION_BUTTONS then
        button = CreateActionButton()
        tinsert(scope.ACTION_BUTTONS, button)
      else
        button = scope.ACTION_BUTTONS[scope.ACTION_INDEX]
      end
      local key, x, y = select(i, unpack(layout))
      button.key = key
      scope.ACTION_BUTTONS[key] = button
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
    for i = scope.ACTION_INDEX+1, #scope.ACTION_BUTTONS do
      button = scope.ACTION_BUTTONS[scope.ACTION_INDEX]
      button:Hide()
    end
    local width, height = xmax-xmin, ymax-ymin
    scope.ROOT:SetSize(width+padding*2, height+padding*2)
    scope.KEYBOARD:SetSize(width, height)
    return next(...)
  end
end

function scope.UpdateKeyboardStanceButtons(next, ...)
  if scope.STANCE_BUTTONS then
    local prev
    for _, button in ipairs(scope.STANCE_BUTTONS) do
      button:Hide()
      if scope.match(scope.SPECC, unpack(button)) then
        button:Show()
        button:ClearAllPoints()
        if not prev then
          button:SetPoint("TOPLEFT", scope.KEYBOARD, "BOTTOMLEFT", 0, -10)
        else
          button:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        end
        button.Border:Hide()
        if scope.STANCE_OFFSET == button.STANCE_OFFSET then
          button.Border:Show()
        end
        prev = button
      end
    end
  end
  return next(...)
end

do
  local pattern, strmatch = "^(.--?)([^-]*.)$", string.match
  local function UpdateButton(binding)
    local modifier, key = strmatch(binding, pattern)
    if scope.MODIFIER == modifier then
      scope.ACTION_BUTTONS[key]:Update()
    end
  end
  local clean, prev = scope.clean
  function scope.UpdateKeyboardMainbarIndices(next, ...)
    prev, scope.PORTAL_BUTTONS = scope.PORTAL_BUTTONS, clean(prev or {})
    for index = 1, 12 do
      local binding = GetBindingKey("ACTIONBUTTON"..index)
      if binding then
        scope.PORTAL_BUTTONS[binding] = index
        scope.DeleteAction(binding)
        if prev then
          if prev[binding] ~= scope.PORTAL_BUTTONS[binding] then
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
    return next(...)
  end

  function scope.UpdateKeyboardMainbarSlots(next, event, slot, ...)
    local index = slot-scope.STANCE_OFFSET+1
    local binding = GetBindingKey("ACTIONBUTTON"..index)
    if binding and 1 <= index and index <= 12 then
      assert(scope.PORTAL_BUTTONS[binding] == index)
      UpdateButton(binding)
    end
    return next(event, slot, ...)
  end

  function scope.UpdateKeyboardMainbarOffsets(next, ...)
    for binding, index in pairs(scope.PORTAL_BUTTONS) do
      UpdateButton(binding)
    end
    return next(...)
  end
end

function scope.UpdateKeyboardActionButtons(next, ...)
  for index = 1, scope.ACTION_INDEX do
    scope.ACTION_BUTTONS[index]:Update()
  end
  return next(...)
end

function scope.UpdateChangedActionButtons(next, event, binding, modifier, key, ...)
  if scope.MODIFIER == modifier then
    scope.ACTION_BUTTONS[key]:Update()
  end
  return next(event, binding, modifier, key, ...)
end

do
  local function UpdateButtonTooltip(button)
    if not button:IsVisible() then return end
    GameTooltip:SetOwner(button, 'ANCHOR_BOTTOMRIGHT')
    local binding = scope.MODIFIER..button.key
    if scope.PORTAL_BUTTONS[binding] then
      GameTooltip:SetAction(scope.PORTAL_BUTTONS[binding] + scope.STANCE_OFFSET - 1)
      return
    end
    local action = scope.GetAction(binding)
    if action.spell then
      if action.id and GetSpellInfo(action.id) then
        GameTooltip:SetSpellByID(action.id)
      else
        GameTooltip:SetText("SPELL "..action.name)
      end
    elseif action.macro then
      GameTooltip:SetText("MACRO "..action.name)
    elseif action.item then
      local level = select(4, GetItemInfo(action.id or 0))
      if action.id and level then
        GameTooltip:SetItemKey(action.id, level, 0)
      else
        GameTooltip:SetText("ITEM "..action.name)
      end
    elseif action.blob then
      GameTooltip:SetText("BLOB "..action.id)
      local blob = scope.dbRead("BLOBS", action.id)
      if blob.script then
        local name = string.match(GetBindingAction(binding, true), "CLICK (OBroBindsSecureBlobButton%d+):LeftButton")
        local button = _G[name]
        if button then
          GameTooltip:AddLine(button:GetAttribute("macrotext"))
          GameTooltip:AddLine(" ")
        end
      end
      GameTooltip:AddLine(blob.body)
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
  function scope.UpdateTooltip(next, event, button, ...)
    current = button
    UpdateButtonTooltip(button)
    return next(event, button, ...)
  end
  function scope.RefreshTooltip(next, ...)
    if current and GetMouseFocus() == current then
      UpdateButtonTooltip(current)
    end
    return next(...)
  end
end

do
  local function RemoveOverride(self, button, binding)
    CloseDropDownMenus()
    if scope.DeleteAction(binding) then
      button:Update()
    end
  end
  local function RemoveBinding(self, button, binding)
    CloseDropDownMenus()
    SetBinding(binding, nil)
    SaveBindings(GetCurrentBindingSet())
    button:Update()
  end
  local function PromoteToAction(self, button, binding)
    CloseDropDownMenus()
    if scope.PromoteToAction(binding) then
      SetBinding(binding, nil)
      SaveBindings(GetCurrentBindingSet())
      button:Update()
    end
  end
  --local function PromoteToMacroBlobFromOverride(self, button, binding)
    --CloseDropDownMenus()
    --if scope.PromoteToMacroBlobFromOverride(binding) then
      --button:Update()
    --end
  --end
  --local function PromoteToMacroBlob(self, button, binding)
    --CloseDropDownMenus()
    --if scope.PromoteToMacroBlob(binding) then
      --SetBinding(binding, nil)
      --SaveBindings(GetCurrentBindingSet())
      --button:Update()
    --end
  --end
  local function LockBinding(self, button, binding)
    CloseDropDownMenus()
    if scope.UpdateActionLock(binding) then
      button:Update()
    end
  end
  local function CreateBlob(self, button, binding)
    CloseDropDownMenus()
    scope.dbWrite("BLOBS", scope.push, {
      name = scope.CLASS.."_"..binding,
      icon = 3615513,
      body = "",
    })
    local index = #scope.dbRead("BLOBS")
    scope.UpdateActionBlob(binding, index)
    scope:dispatch("ADDON_EDITOR_SHOW")
    scope:dispatch("ADDON_SELECTOR_SHOW")
    scope:dispatch("ADDON_EDITOR_SELECT", index)
    scope:dispatch("ADDON_SELECTOR_SELECT", index)
  end
  local function EditBlob(self, button, binding)
    CloseDropDownMenus()
    local index = scope.GetAction(binding).id
    scope:dispatch("ADDON_EDITOR_SHOW")
    scope:dispatch("ADDON_SELECTOR_SHOW")
    scope:dispatch("ADDON_EDITOR_SELECT", index)
    scope:dispatch("ADDON_SELECTOR_SELECT", index)
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
    local binding = scope.MODIFIER..button.key
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
      elseif action.blob then
        info.text = action.id
      else
        info.text = action.kind.." "..action.name
      end
      info.hasArrow = action.kind and not action.lock
      info.menuList = "override"
      info.disabled = not action.kind or action.lock
      UIDropDownMenu_AddButton(info, 1)

      if action.blob then
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
      info.hasArrow = not action.lock and command ~= ""
      info.menuList = "binding"
      info.disabled = not info.hasArrow
      UIDropDownMenu_AddButton(info, 1)

      reset()
      info.text = action.lock and "Unlock" or "Lock"
      info.notCheckable = false
      info.checked = action.lock
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
      --if action.macro then
        --reset()
        --info.text = "Promote to BLOB override"
        --info.func = PromoteToMacroBlobFromOverride
        --UIDropDownMenu_AddButton(info, 2)
      --end

    elseif section == "binding" then
      local command = GetBindingAction(binding, false)
      local kind, name = string.match(command, "^(%w+) (.*)$")
      if kind == 'SPELL' or kind == 'MACRO' or kind == 'ITEM' then
        reset()
        info.text = "Promote to "..kind.." override"
        info.func = PromoteToAction
        UIDropDownMenu_AddButton(info, 2)
      end
      --if kind == 'MACRO' then
        --reset()
        --info.text = "Promote to BLOB override"
        --info.func = PromoteToMacroBlob
        --UIDropDownMenu_AddButton(info, 2)
      --end
      reset()
      info.text = "Clear binding"
      info.func = RemoveBinding
      UIDropDownMenu_AddButton(info, 2)
    end
  end

  function scope.UpdateDropdown(next, event, button, ...)
    if not drop then
      info = UIDropDownMenu_CreateInfo()
      drop = CreateFrame("frame", nil, UIParent, "UIDropDownMenuTemplate")
      drop.displayMode = "MENU"
      drop.initialize = InitializeDropdown
    end
    info.arg1 = button
    ToggleDropDownMenu(1, nil, drop, "cursor", 0, 0, "root")
    return next(event, button, ...)
  end
end
