local _A = select(2, ...)
local push, match, read, write, map = _A.push, _A.match, _A.read, _A.write, _A.map
local KIND, ID, NAME, ICON, LOCKED = 1, 2, 3, 4, 5

do
  local function dispatch(page, event, ...)
    local parent = page:GetParent()
    return parent:dispatch(event, ...)
  end
  function _A.InitializeRoot(e, root, ...)
    print("InitializeRoot", e.key, root, root.pageKeyboard)
    root.pageKeyboard.dispatch = dispatch
    root.pageSettings.dispatch = dispatch
    root.pageKeyboard:Show()
    return e(root, ...)
  end
end

function _A.UpdateRootPersistState(e, root, ...)
  print("UpdateRootPersistState", e.key, root, root.pageKeyboard)
  OBroBindsDB = write(OBroBindsDB, 'GUI', 'open', e.key == "ADDON_ROOT_SHOW" and true or nil)
  return e(root, ...)
end

do
  local elapsed, pa, pc, ps, modifier = 0, IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
  local function OnUpdate(self, delta)
    elapsed = elapsed + delta
    if elapsed < 0.1 then return end
    local na, nc, ns = IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()
    if pa ~= na or pc ~= nc or ps ~= ns then
      pa, pc, ps = na, nc, ns
      self.modifier = (pa and "ALT-" or "")..(pc and "CTRL-" or "")..(ps and "SHIFT-" or "")
      self:dispatch("ADDON_MODIFIER_CHANGED", self)
    end
    elapsed = 0
  end

  local function CreateStanceButton(page, offset, icon, ...)
    local button = CreateFrame("button", nil, page, "OBroBindsStanceButtonTemplate")
    button.offset = offset
    button.icon:SetTexture("Interface/Icons/"..icon)
    return push(button, ...)
  end

  function _A.InitializePageKeyboard(e, root, ...)
    print("InitializePageKeyboard", e.key)
    local page = root.pageKeyboard
    page:SetScript("OnUpdate", OnUpdate)
    page.modifier = (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")
    --page.mainbar = {}
    page.buttons = {}
    page.offset = 1
    page.stances = nil
    if root.class == "ROGUE" then
      write(page, 'stances', push, CreateStanceButton(page, 73, 'ability_stealth', 1, 2, 3))
    elseif true or root.class == "DRUID" then
      write(page, 'stances', push, CreateStanceButton(page, 97,  'ability_racial_bearform',    1, 2, 3, 4))
      write(page, 'stances', push, CreateStanceButton(page, 73,  'ability_druid_catform',      1, 2, 3, 4))
      write(page, 'stances', push, CreateStanceButton(page, 109, 'spell_nature_forceofnature', 1))
    end
    return e(root, _A.DEFAULT_KEYBOARD_LAYOUT, ...)
  end
end

function _A.UpdateKeyboardStanceButtons(e, root, ...)
  print("UpdateKeyboardStanceButtons", e.key)
  local page = root.pageKeyboard
  if page.stances then
    local prev
    for _, button in ipairs(page.stances) do
      button:Hide()
      if match(root.spec, unpack(button)) then
        button:Show()
        button:ClearAllPoints()
        if not prev then
          button:SetPoint("LEFT", page, "TOPLEFT", 0, -36)
        else
          button:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        end
        button.Border:Hide()
        if page.offset == button.offset then
          button.Border:Show()
        end
        prev = button
      end
    end
  end
  return e(root, ...)
end

do
  local function UpdateKeyboardMainbarActionButton(self, page, binding, slot)
    local kind, id = GetActionInfo(slot)
    self.Border:Show()
    self.Name:SetText(page.mainbar[binding])
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

  local function UpdateKeyboardBindingActionButton(self, page, binding)
    self.Border:Hide()
    self.Name:SetText()
    local override = page:dispatch("ADDON_GET_OVERRIDE_BINDING", binding)
    local hasAction = GetBindingAction(binding, false) ~= ""
    local icon = override.icon
    if icon then
      self.icon:SetVertexColor(1, 1, 1, 1)
      self.icon:SetTexture(icon)
    elseif hasAction then
      self.icon:SetVertexColor(0.8, 1, 0.1, 0.1)
      self.icon:SetTexture(136243)
    else
      self.icon:SetTexture(nil)
    end
    if hasAction then
      self.AutoCastable:Show()
    else
      self.AutoCastable:Hide()
    end
    if override.locked then
      self.LevelLinkLockIcon:Show()
    else
      self.LevelLinkLockIcon:Hide()
    end
  end

  local function Update(self)
    local page = self:GetParent()
    local binding = page.modifier..self.key
    if page.mainbar[binding] then
      UpdateKeyboardMainbarActionButton(self, page, binding, page.mainbar[binding] + page.offset - 1)
    else
      UpdateKeyboardBindingActionButton(self, page, binding)
    end
  end

  local padding, mmin, mmax = 12, math.min, math.max
  function _A.UpdateKeyboardLayout(e, root, layout, ...)
    print("UpdateKeyboardLayout", e.key)
    local page = root.pageKeyboard
    page.index = 0
    page:ClearAllPoints()
    page:SetPoint("TOPLEFT", padding, -padding)
    page:SetSize(1, 1)
    local xmin, xmax = page:GetLeft(), page:GetRight()
    local ymin, ymax = page:GetBottom(), page:GetTop()
    local button
    for key in pairs(page.buttons) do
      if type(key) == "string" then
        page.button[key] = nil
      end
    end
    for i = 1, #layout, 3 do
      page.index = page.index + 1
      if page.index > #page.buttons then
        button = CreateFrame("button", nil, page, "OBroBindsOverrideButtonTemplate")
        button.Update = Update
        table.insert(page.buttons, button)
      else
        button = page.buttons[page.index]
      end
      local key, x, y = select(i, unpack(layout))
      button.key = key
      page.buttons[key] = button
      button:SetPoint("TOPLEFT", x, -y-58)
      button.Border:Hide()
      button.Border:SetAlpha(1)
      button.HotKey:SetText(key)
      button.Name:SetText()
      xmin = mmin(xmin, button:GetLeft())
      xmax = mmax(xmax, button:GetRight())
      ymin = mmin(ymin, button:GetBottom())
      ymax = mmax(ymax, button:GetTop())
    end
    for i = page.index+1, #page.buttons do
      button = page.buttons[page.index]
      button:Hide()
    end
    local w, h = xmax-xmin, ymax-ymin
    root:SetSize(w+padding*2, h+padding*2)
    page:SetSize(w, h)
    --frame.drawer.scroll.edit:SetSize(frame.drawer.scroll:GetWidth(), h)
    --frame.drawer.scroll.edit.bg = frame.drawer.scroll.edit:CreateTexture(nil, 'BACKGROUND')
    --frame.drawer.scroll.edit.bg:SetAllPoints()
    --frame.drawer.scroll.edit.bg:SetVertexColor(1, 0.5, 0.25, 0.5)
    --frame.drawer.scroll.edit.bg:SetColorTexture(1, 0.5, 0.25, 0.5)
    --BackdropTemplateMixin.OnBackdropLoaded(self)
    --frame.scroll.edit:SetSize(w-100-2*padding, h)
    --frame.scroll.edit:SetPoint("TOPLEFT", padding, -padding)
    --frame.tmp:ClearAllPoints()
    --frame.tmp:SetAllPoints(frame.scroll)
    return e(root, ...)
  end
end

do
  local function clean(tbl)
    for key in pairs(tbl) do
      tbl[key] = nil
    end
    return tbl
  end
  local function UpdateButton(page, binding, msg)
    local modifier, key = string.match(binding, "(.*[.*-]?)([^-]*.)$")
    if page.modifier == modifier then
      page.buttons[key]:Update()
    end
  end

  local prev
  function _A.UpdateKeyboardMainbarIndices(e, root, ...)
    print("UpdateKeyboardMainbarBindings", e.key, ...)
    local page = root.pageKeyboard
    prev, page.mainbar = page.mainbar, clean(prev or {})
    for index = 1, 12 do
      local binding = GetBindingKey("ACTIONBUTTON"..index)
      if binding then
        page.mainbar[binding] = index
        if prev then
          if prev[binding] ~= page.mainbar[binding] then
            UpdateButton(page, binding, "mod")
          end
          prev[binding] = nil
        end
      end
    end
    if prev then
      for binding in pairs(prev) do
        UpdateButton(page, binding)
      end
    end
    return e(root, ...)
  end

  function _A.UpdateKeyboardMainbarSlots(e, root, slot, ...)
    local page = root.pageKeyboard
    local index = slot-page.offset+1
    local binding = GetBindingKey("ACTIONBUTTON"..index)
    if binding and 1 <= index and index <= 12 then
      assert(page.mainbar[binding] == index)
      UpdateButton(page, binding)
    end
    return e(root, slot, ...)
  end

  function _A.UpdateKeyboardMainbarOffsets(e, root, ...)
    local page = root.pageKeyboard
    for binding, index in pairs(page.mainbar) do
      UpdateButton(page, binding)
    end
    return e(root, ...)
  end
end

function _A.UpdateKeyboardButtons(e, root, ...)
  print("UpdateKeyboardButtons", e.key)
  local page = root.pageKeyboard
  for index = 1, page.index do
    page.buttons[index]:Update()
  end
  return e(root, ...)
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
    local kind, id, name = select(3, frame:dispatch("GET_OVERRIDE_ENTRY", binding))
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
    elseif kind == 'BLOB' then
      GameTooltip:SetText("BLOB "..id)
    elseif GetBindingAction(binding, false) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding, false))
    elseif GetBindingAction(binding, true) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding, true))
    else
      GameTooltip:Hide()
    end
  end
  local current
  function _A.UpdateTooltip(e, frame, button)
    current = button
    Update(frame, button)
    return e:next(frame, button)
  end
  function _A.RefreshTooltip(e, frame, ...)
    if current and GetMouseFocus() == current then
      Update(frame, current)
    end
    return e:next(frame, ...)
  end
end

do
  local function RemoveOverride(self, button, binding)
    button:GetParent():dispatch("ADDON_DEL_OVERRIDE_BINDING", binding)
    button:Update()
    CloseDropDownMenus()
  end
  local function RemoveBinding(self, _, binding)
    SetBinding(binding, nil)
    SaveBindings(GetCurrentBindingSet())
    CloseDropDownMenus()
  end
  local function PromoteBinding(self, button, binding)
    button:GetParent():dispatch("PROMOTE_OVERRIDE_ENTRY", binding)
    SetBinding(binding, nil)
    SaveBindings(GetCurrentBindingSet())
    CloseDropDownMenus()
  end
  local function LockBinding(self, button, binding)
    button:GetParent():dispatch("LOCK_OVERRIDE_ENTRY", binding)
    button:Update()
    CloseDropDownMenus()
  end
  local function CreateBlob(self, button, binding)
    button:GetParent():dispatch("SET_OVERRIDE_ENTRY", true, binding, "BLOB", "somename", "/cast Fade", 3615513)
    button:Update()
    CloseDropDownMenus()
  end
  local function EditBlob(self, button, binding)
    button:GetParent():dispatch("EDIT_BLOB", binding)
    --button:GetParent():dispatch("SET_OVERRIDE_ENTRY", true, binding, "BLOB", "somename", "/cast Fade", 3615513)
    --button:Update()
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
      local kind, id, name, _, locked = select(3, frame:dispatch("GET_OVERRIDE_ENTRY", binding))
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
      local kind, id, name, _, locked = select(3, frame:dispatch("GET_OVERRIDE_ENTRY", binding))

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

  function _A.UpdateDropdown(e, frame, button)
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

function _A.UpdateUnknownSpells(e, frame)
  for binding, action in map(nil, read(OBroBindsDB, frame.class, frame.spec)) do
    if not action[ID] then
      local icon, _, _, _, id = select(3, GetSpellInfo(action[NAME]))
      action[ID], action[ICON] = id, icon or action[ICON]
    end
  end
  return e:next(frame)
end

