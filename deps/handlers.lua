local _A = select(2, ...)
local push, match, read, write, map = _A.push, _A.match, _A.read, _A.write, _A.map

do
  --local empty = {}
  --local OVERRIDE = { kind = 1, id = 2, name = 3, icon = 4, locked = 5, SPELL = 6, MACRO = 6, ITEM = 6, BLOB = 6 }
  --function OVERRIDE:__index(key)
    --if self == empty then return nil end
    --local value = OVERRIDE[key]
    --if type(value) == 'number' then
      --if value == 6 then
        --return rawget(self, 1) == key
      --elseif value == 4 then
        --local kind = rawget(self, 1)
        --if kind == "SPELL" then
          --return select(3, GetSpellInfo(rawget(self, 2))) or rawget(self, 4)
        --elseif kind == "MACRO" then
          --return select(2, GetMacroInfo(rawget(self, 3))) or rawget(self, 4)
        --elseif kind == "ITEM" then
          --return select(10, GetItemInfo(rawget(self, 2) or 0)) or rawget(self, 4)
        --elseif kind == "BLOB" then
          --return 441148
        --end
        --return nil
      --else
        --return rawget(self, value)
      --end
    --end
    --return value
  --end

  --function OVERRIDE:Bind(root, binding)
    --if self.SPELL then
      --SetOverrideBindingSpell(root, false, binding, GetSpellInfo(self.id) or self.name)
    --elseif self.MACRO then
      --SetOverrideBindingMacro(root, false, binding, self.name)
    --elseif self.ITEM then
      --SetOverrideBindingItem(root, false, binding, self.name)
    --elseif self.BLOB then
    --end
  --end

  local function dispatch(page, event, ...)
    local parent = page:GetParent()
    return parent:dispatch(event, ...)
  end

  local function dbRead(self, ...)
    return read(OBroBindsDB, ...)
  end
  local function dbWrite(self, ...)
    OBroBindsDB = write(OBroBindsDB, ...)
  end
  local function dbGetOverride(self, binding)
    return setmetatable(read(OBroBindsDB, self.class, self.spec, binding) or empty, OVERRIDE)
  end
  local function dbDeleteOverride(self, binding)
    OBroBindsDB = write(OBroBindsDB, self.class, self.spec, binding, nil)
  end
  local function iter(...)
    local binding, override = next(...)
    return binding, setmetatable(override or empty, OVERRIDE)
  end
  local function dbMapOverrides(self)
    return iter, read(OBroBindsDB, self.class, self.spec) or empty, nil
  end
  function _A.InitializeRoot(e, root, ...)
    root.dbRead = dbRead
    root.dbWrite = dbWrite
    root.dbMapOverrides = dbMapOverrides
    root.dbGetOverride = dbGetOverride
    root.dbDeleteOverride = dbDeleteOverride
    root.pageKeyboard.dispatch = dispatch
    root.pageSettings.dispatch = dispatch
    PanelTemplates_SetTab(root, root.tabKeyboard:GetID())
    return e(root, ...)
  end
end

function _A.UpdatePlayerBindings(e, root, ...)
  root.class = select(2, UnitClass("player"))
  root.spec = GetSpecialization()
  ClearOverrideBindings(root)
  for binding, override in root:dbMapOverrides() do
    override:Bind(root, binding)
  end
  return e(root, ...)
end

function _A.UpdateUnknownSpells(e, root, ...)
  for binding, override in root:dbMapOverrides() do
    if override.SPELL and not override.id then
      local icon, _, _, _, id = select(3, GetSpellInfo(override.name))
      action[1], action[4] = id, icon or override.icon
    end
  end
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
    local page = root.pageKeyboard
    page:SetScript("OnUpdate", OnUpdate)
    page.modifier = (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")
    page.buttons = {}
    page.offset = 1
    page.mainbar = nil
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
  local function UpdateButton(self)
    local page = self:GetParent()
    local binding = page.modifier..self.key
    if page.mainbar[binding] then
      local kind, id = GetActionInfo(page.mainbar[binding] + page.offset - 1)
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
    else
      self.Border:Hide()
      self.Name:SetText()
      local override = page:GetParent():dbGetOverride(binding)
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
  end

  local padding, mmin, mmax = 12, math.min, math.max
  function _A.UpdateKeyboardLayout(e, root, layout, ...)
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
        button.UpdateButton = UpdateButton
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
    local modifier, key = string.match(binding, "^(.--?)([^-]*.)$")
    if page.modifier == modifier then
      page.buttons[key]:UpdateButton()
    end
  end
  local prev
  function _A.UpdateKeyboardMainbarIndices(e, root, ...)
    local page = root.pageKeyboard prev, page.mainbar = page.mainbar, clean(prev or {})
    for index = 1, 12 do
      local binding = GetBindingKey("ACTIONBUTTON"..index)
      if binding then
        page.mainbar[binding] = index
        root:dbDeleteOverride(binding)
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
function _A.UpdateAllKeyboardButtons(e, root, ...)
  local page = root.pageKeyboard
  for index = 1, page.index do
    page.buttons[index]:UpdateButton()
  end
  return e(root, ...)
end

do
  local function Update(page, button)
    if not button:IsVisible() then return end
    GameTooltip:SetOwner(button, 'ANCHOR_BOTTOMRIGHT')
    local binding = page.modifier..button.key
    if page.mainbar[binding] then
      GameTooltip:SetAction(page.mainbar[binding] + page.offset - 1)
      return
    end
    local override = page:GetParent():dbGetOverride(binding)
    if override.SPELL then
      if override.id and GetSpellInfo(override.id) then
        GameTooltip:SetSpellByID(override.id)
      else
        GameTooltip:SetText("SPELL "..override.name)
      end
    elseif override.MACRO then
      GameTooltip:SetText("MACRO "..override.name)
    elseif override.ITEM then
      local level = select(4, GetItemInfo(override.id or 0))
      if override.id and level then
        GameTooltip:SetItemKey(override.id, level, 0)
      else
        GameTooltip:SetText("ITEM "..override.name)
      end
    elseif override.BLOB then
      GameTooltip:SetText("BLOB "..override.id)
    elseif GetBindingAction(binding, false) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding, false))
    elseif GetBindingAction(binding, true) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding, true))
    else
      GameTooltip:Hide()
    end
  end
  local current
  function _A.UpdateTooltip(e, root, button)
    current = button
    Update(root.pageKeyboard, button)
    return e(root, button)
  end
  function _A.RefreshTooltip(e, root, ...)
    if current and GetMouseFocus() == current then
      Update(root.pageKeyboard, current)
    end
    return e(root, ...)
  end
end

do
  local function RemoveOverride(self, button, binding)
    button:GetParent():dispatch("ADDON_DEL_OVERRIDE_BINDING", binding)
    button:UpdateButton()
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
    button:UpdateButton()
    CloseDropDownMenus()
  end
  local function CreateBlob(self, button, binding)
    button:GetParent():dispatch("SET_OVERRIDE_ENTRY", true, binding, "BLOB", "somename", "/cast Fade", 3615513)
    button:UpdateButton()
    CloseDropDownMenus()
  end
  local function EditBlob(self, button, binding)
    button:GetParent():dispatch("EDIT_BLOB", binding)
    --button:GetParent():dispatch("SET_OVERRIDE_ENTRY", true, binding, "BLOB", "somename", "/cast Fade", 3615513)
    --button:UpdateButton()
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
