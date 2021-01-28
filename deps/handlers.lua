local _A = select(2, ...)
local push, match, read, write, map = _A.push, _A.match, _A.read, _A.write, _A.map
local KIND, ID, NAME, ICON, LOCKED = 1, 2, 3, 4, 5

do
  local elapsed, pa, pc, ps, modifier = 0
  function _A.OnUpdateModifierHandler(self, delta)
    elapsed = elapsed + delta
    if elapsed < 0.1 then return end
    local na, nc, ns = IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
    if pa ~= na or pc ~= nc or ps ~= ns then
      pa, pc, ps = na, nc, ns
      self.modifier = (pa and "ALT-" or "")..(pc and "CTRL-" or "")..(ps and "SHIFT-" or "")
      self:dispatch("MODIFIER_CHANGED")
    end
    elapsed = 0
  end
end

function _A.CreateStanceButton(frame, offset, icon, ...)
  local button = CreateFrame("button", nil, frame, "OBroBindsStanceButtonTemplate")
  button.offset = offset
  button.icon:SetTexture("Interface/Icons/"..icon)
  return push(button, ...)
end

function _A.UpdateStanceButtonsHandler(e, frame)
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

do
  local function UpdateMainbarButton(self, frame, binding, slot)
    local kind, id = GetActionInfo(slot)
    self.Border:Show()
    self.Name:SetText(frame.mainbar[binding])
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
  end

  local function UpdateOverrideButton(self, frame, binding)
    local kind, id, name, icon, locked = select(3, frame:dispatch("OVERRIDE_GET", binding))
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
    local frame = self:GetParent()
    local binding = frame.modifier..self.key
    if frame.mainbar[binding] then
      local slot = frame.mainbar[binding] + frame.offset - 1
      frame.mainbar[slot] = self
      UpdateMainbarButton(self, frame, binding, slot)
    else
      UpdateOverrideButton(self, frame, binding)
    end
  end

  local padding, mmin, mmax = 12, math.min, math.max
  function _A.UpdateOverrideLayoutHandler(e, frame, layout)
    frame.index = 0
    local xmin, xmax = frame:GetLeft(), frame:GetRight()
    local ymin, ymax = frame:GetBottom(), frame:GetTop()
    local button
    for i = 1, #layout, 3 do
      frame.index = frame.index + 1
      if frame.index > #frame.buttons then
        button = CreateFrame("button", nil, frame, "OBroBindsOverrideButtonTemplate")
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
      xmin = mmin(xmin, button:GetLeft())
      xmax = mmax(xmax, button:GetRight())
      ymin = mmin(ymin, button:GetBottom())
      ymax = mmax(ymax, button:GetTop())
    end
    for i = frame.index+1, #frame.buttons do
      button = frame.buttons[frame.index]
      button:Hide()
    end
    frame:SetSize(xmax-xmin+padding, ymax-ymin+padding)
    return e:next(frame)
  end
end

function _A.UpdateOverrideBindingsHandler(e, frame)
  for key in pairs(frame.mainbar) do
    frame.mainbar[key] = nil
  end
  for index = 1, 12 do
    local binding = GetBindingKey("ACTIONBUTTON"..index)
    if binding then
      frame.mainbar[binding] = index
      frame:dispatch("OVERRIDE_DEL", true, binding)
    end
  end
  return e:next(frame)
end

function _A.UpdateOverrideButtonsHandler(e, frame)
  for index = 1, frame.index do
    frame.buttons[index]:Update()
  end
  return e:next(frame)
end

function _A.SetAllOverridesHandler(e, frame)
  frame.spec = GetSpecialization()
  ClearOverrideBindings(frame)
  for binding, action in map(OBroBindsDB, frame.class, frame.spec) do
    frame:dispatch("OVERRIDE_SET", false, binding, action[1], action[2], action[3], action[4])
  end
  return e:next(frame)
end

function _A.SetOverrideHandler(e, frame, save, binding, kind, id, name, icon, locked)
  if kind == "SPELL" then
    SetOverrideBindingSpell(frame, false, binding, GetSpellInfo(id) or name)
  elseif kind == "MACRO" then
    SetOverrideBindingMacro(frame, false, binding, name)
  elseif kind == "ITEM" then
    SetOverrideBindingItem(frame, false, binding, name)
  end
  if save then
    OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, {kind, id, name, icon, locked})
  end
  return e:next(frame, binding, save, kind, id, name, icon, locked)
end

function _A.GetOverrideHandler(e, frame, binding)
  local action = read(OBroBindsDB, frame.class, frame.spec, binding)
  if action then
    return e:next(frame, binding, action[KIND], action[ID], action[NAME], action[ICON], action[LOCKED])
  end
  return e:next(frame, binding, nil)
end

function _A.DelOverrideHandler(e, frame, save, binding)
  SetOverrideBinding(frame, false, binding, nil)
  if save then
    OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, nil)
  end
  return e:next(frame, binding)
end

do
  local function CURSOR_UPDATE(e, frame)
    frame.__cursor = nil
    frame:UnregisterEvent("CURSOR_UPDATE")
    return e:once(frame)
  end
  function _A.PickupOverrideHandler(e, frame, button)
    local binding = frame.modifier..button.key
    if not read(OBroBindsDB, frame.class, frame.spec, binding, 5) then
      if frame.mainbar[binding] then
        PickupAction(frame.mainbar[binding] + frame.offset - 1)
        return e:next(frame, button)
      end
      local kind, id, name, icon = select(3, frame:dispatch("OVERRIDE_GET", binding))
      if kind == "SPELL" then
        PickupSpell(id)
        if not GetCursorInfo() then
          local macro = CreateMacro("__OBRO_TMP", select(3, GetSpellInfo(id)) or icon)
          PickupMacro(macro)
          DeleteMacro(macro)
          frame.__cursor = read(OBroBindsDB, frame.class, frame.spec, binding)
          frame:RegisterEvent("CURSOR_UPDATE")
          _A.listen("CURSOR_UPDATE", CURSOR_UPDATE)
        end
      elseif kind == "MACRO" then
        PickupMacro(name)
      elseif kind == "ITEM" then
        PickupItem(id)
      elseif kind then
        assert(false, "Unhandled pickup: "..kind)
      end
      frame:dispatch("OVERRIDE_DEL", true, binding)
    end
    return e:next(frame, button)
  end
end

function _A.ReceiveOverrideHandler(e, frame, button)
  local binding = frame.modifier..button.key
  if not read(OBroBindsDB, frame.class, frame.spec, binding, 5) then
    if frame.mainbar[binding] then
      PlaceAction(frame.mainbar[binding] + frame.offset - 1)
      return e:next(frame, button)
    end
    local kind, id, link, arg1, arg2 = GetCursorInfo()
    if kind == "spell" then
      ClearCursor()
      frame:dispatch("OVERRIDE_PICKUP", button)
      local id = arg2 or arg1
      local name, _, icon = GetSpellInfo(id)
      assert(id ~= nil, "GetCursorInfo() on spell, id should never be nil")
      assert(name ~= nil, "GetCursorInfo() on spell, name should never be nil")
      assert(icon ~= nil, "GetCursorInfo() on spell, icon should never be nil")
      frame:dispatch("OVERRIDE_SET", true, binding, strupper(kind), id, name, icon)
    elseif kind == "macro" and id == 0 then
      local action = frame.__cursor
      ClearCursor()
      frame:dispatch("OVERRIDE_PICKUP", button)
      frame:dispatch("OVERRIDE_SET", true, binding, action[KIND], action[ID], action[NAME], action[ICON])
    elseif kind == "macro" then
      ClearCursor()
      frame:dispatch("OVERRIDE_PICKUP", button)
      local name, icon = GetMacroInfo(id)
      assert(id ~= nil, "GetCursorInfo() on macro, id should never be nil")
      assert(type(id) == "number", "GetCursorInfo() on macro, id should always be number")
      assert(name ~= nil, "GetCursorInfo() on macro, name should never be nil")
      assert(icon ~= nil, "GetCursorInfo() on macro, icon should never be nil")
      frame:dispatch("OVERRIDE_SET", true, binding, strupper(kind), id, name, icon)
    elseif kind == "item" then
      ClearCursor()
      local name = select(3, string.match(link, "^|c%x+|H(%a+):(%d+).+|h%[([^%]]+)"))
      local icon = select(10, GetItemInfo(id))
      assert(link ~= nil, "GetCursorInfo() on item, link should never be nil")
      assert(name ~= nil, "GetCursorInfo() on item, name should never be nil")
      assert(icon ~= nil, "GetCursorInfo() on item, icon should never be nil")
      frame:dispatch("OVERRIDE_PICKUP", button)
      frame:dispatch("OVERRIDE_SET", true, binding, strupper(kind), id, name, icon)
    elseif kind then
      assert(false, "Unhandled receive: "..kind)
    end
  end
  return e:next(frame, button)
end

function _A.PromoteOverrideHandler(e, frame, binding)
  local action = GetBindingAction(binding, false)
  local kind, name = string.match(action, "^(%w+) (.*)$")
  if kind == 'SPELL' then
    local icon, _, _, _, id = select(3, GetSpellInfo(name))
    assert(name ~= nil)
    frame:dispatch("OVERRIDE_SET", true, binding, kind, id, name, icon or 134400)
  elseif kind == 'MACRO' then
    local id = GetMacroIndexByName(name)
    local icon = select(2, GetMacroInfo(name))
    assert(name ~= nil)
    frame:dispatch("OVERRIDE_SET", true, binding, kind, id, name, icon or 134400)
  elseif kind == 'ITEM' then
    local link, _, _, _, _, _, _, _, icon = select(2, GetItemInfo(name))
    local id = link and select(4, string.find(link, "^|c%x+|H(%a+):(%d+)[|:]"))
    assert(name ~= nil)
    frame:dispatch("OVERRIDE_SET", true, binding, kind, id, name, icon or 134400)
  else
    assert(false, "Unhandled type: "..kind)
  end
  return e:next(frame, binding)
end

function _A.LockOverrideHandler(e, frame, binding)
  local value = not read(OBroBindsDB, frame.class, frame.spec, binding, 5) and true or nil
  OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, 5, value)
  return e:next(frame, binding)
end

function _A.ActionBarSlotChangedHandler(e, frame, slot)
  if frame.mainbar[slot] then
    local button = frame.mainbar[slot]
    local binding = frame.modifier..button.key
    if binding == GetBindingKey("ACTIONBUTTON"..(slot-frame.offset+1)) then
      button:Update()
    end
  end
  return e:next(frame, slot)
end

do
  local function Update(frame, button)
    if not button:IsVisible() then return end
    GameTooltip:SetOwner(button, 'ANCHOR_BOTTOMRIGHT')
    local binding = frame.modifier..button.key
    if frame.mainbar[binding] then
      GameTooltip:SetAction(frame.mainbar[binding] + frame.offset - 1)
      return
    end
    local kind, id, name = select(3, frame:dispatch("OVERRIDE_GET", binding))
    if kind == 'SPELL' then
      if id and GetSpellInfo(id) then
        GameTooltip:SetSpellByID(id)
      else
        GameTooltip:SetText("SPELL "..name)
      end
    elseif kind == 'MACRO' then
      GameTooltip:SetText("MACRO "..name)
    elseif kind == 'ITEM' then
      local level = select(4, GetItemInfo(id or 0))
      if id and level then
        GameTooltip:SetItemKey(id, level, 0)
      else
        GameTooltip:SetText("ITEM "..name)
      end
    elseif kind == 'blob' then
      GameTooltip:SetText("BLOB "..id)
    elseif GetBindingAction(binding, false) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding, false))
    else
      GameTooltip:Hide()
    end
  end
  local current
  function _A.UpdateTooltipHandler(e, frame, button)
    current = button
    Update(frame, button)
    return e:next(frame, button)
  end
  function _A.RefreshTooltipHandler(e, frame, ...)
    if current and GetMouseFocus() == current then
      Update(frame, current)
    end
    return e:next(frame, ...)
  end
end

do
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
    local frame = button:GetParent()
    local binding = frame.modifier..button.key
    info.arg2 = binding

    if section == "root" then
      local kind, id, name, _, locked = select(3, frame:dispatch("OVERRIDE_GET", binding))
      local action = GetBindingAction(binding, false)

      reset()
      info.text = "Override"
      info.isTitle = true
      UIDropDownMenu_AddButton(info, 1)

      reset()
      info.text = not kind and 'none' or kind.." "..name
      info.hasArrow = not locked
      info.menuList = "override"
      info.disabled = locked
      UIDropDownMenu_AddButton(info, 1)
      UIDropDownMenu_AddSeparator(1)

      reset()
      info.text = "Binding"
      info.isTitle = true
      UIDropDownMenu_AddButton(info, 1)

      reset()
      info.text = action == "" and "none" or action
      info.hasArrow = not locked and action ~= ""
      info.menuList = "binding"
      info.disabled = not info.hasArrow
      UIDropDownMenu_AddButton(info, 1)

      reset()
      info.text = locked and "Unlock" or "Lock"
      info.notCheckable = false
      info.checked = locked
      info.func = LockBinding
      UIDropDownMenu_AddButton(info, 1)

    elseif section == "override" then
      local kind, id, name, _, locked = select(3, frame:dispatch("OVERRIDE_GET", binding))

      if kind == 'BLOB' then
        reset()
        info.text = "Edit blob"
        info.func = EditBlob
        UIDropDownMenu_AddButton(info, 2)
      end

      if kind then
        reset()
        info.text = "Clear override"
        info.func = RemoveOverride
        UIDropDownMenu_AddButton(info, 2)
      else
        reset()
        info.text = "Create blob"
        info.func = CreateBlob
        UIDropDownMenu_AddButton(info, 2)
      end

    elseif section == "binding" then
      local action = GetBindingAction(binding, false)
      local kind, name = string.match(action, "^(%w+) (.*)$")

      if kind == 'SPELL' or kind == 'MACRO' or kind == 'ITEM' then
        reset()
        info.text = "Promote to override"
        info.func = PromoteBinding
        UIDropDownMenu_AddButton(info, 2)
      end

      reset()
      info.text = "Clear binding"
      info.func = RemoveBinding
      UIDropDownMenu_AddButton(info, 2)
    end
  end

  function _A.UpdateDropdownHandler(e, frame, button)
    if not drop then
      info = UIDropDownMenu_CreateInfo()
      drop = CreateFrame("frame", nil, UIParent, "UIDropDownMenuTemplate")
      drop.displayMode = "MENU"
      drop.initialize = InitializeDropdown
    end
    info.arg1 = button
    ToggleDropDownMenu(1, nil, drop, "cursor", 0, 0, "root")
    return e:next(frame, button)
  end
end

function _A.UpdateUnknownSpellsHandler(e, frame)
  for binding, action in map(nil, read(OBroBindsDB, frame.class, frame.spec)) do
    if not action[ID] then
      local icon, _, _, _, id = select(3, GetSpellInfo(action[NAME]))
      action[ID], action[ICON] = id, icon or action[ICON]
    end
  end
  return e:next(frame)
end
