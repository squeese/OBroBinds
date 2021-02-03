local scope = select(2, ...)
scope.ACTION = { kind = 1, id = 2, name = 3, text = 3, icon = 4, locked = 5, SPELL = 6, MACRO = 6, ITEM = 6, BLOB = 6 }

function scope.ACTION:__index(key)
  if self == scope.empty then return end
  local val = scope.ACTION[key]
  if type(val) ~= 'number' then
    return val
  elseif val == 6 then
    return rawget(self, 1) == key
  else
    return rawget(self, val)
  end
  return value
end

function scope.ACTION:SetOverrideBinding(binding)
  if self.SPELL then
    SetOverrideBindingSpell(scope.root, false, binding, GetSpellInfo(self.id) or self.name)
  elseif self.MACRO then
    SetOverrideBindingMacro(scope.root, false, binding, self.name)
  elseif self.ITEM then
    SetOverrideBindingItem(scope.root, false, binding, self.name)
  elseif self.BLOB then
    scope.secureButtons.index = scope.secureButtons.index + 1
    if scope.secureButtons.index > #scope.secureButtons then
      local button = CreateFrame("Button", "OBroBindsSecureBlobButton"..scope.secureButtons.index, nil, "SecureActionButtonTemplate")
      button:RegisterForClicks("AnyUp")
      button:SetAttribute("type", "macro")
      button.command = "CLICK "..button:GetName()..":LeftButton"
      table.insert(scope.secureButtons, button)
    end
    local button = scope.secureButtons[scope.secureButtons.index]
    button:SetAttribute("macrotext", self.text)
    SetOverrideBinding(scope.root, false, binding, button.command)
  else
    SetOverrideBinding(scope.root, false, binding, nil)
  end
end

function scope.ACTION:Icon()
  if self.SPELL then
    return select(3, GetSpellInfo(self.id)) or self.icon 
  elseif self.MACRO then
    return select(2, GetMacroInfo(self.name)) or self.icon
  elseif self.ITEM then
    return select(10, GetItemInfo(self.id or 0)) or self.icon
  elseif self.BLOB then
    return self.icon or 441148
  end
  return self.icon or nil
end

do
  local function iter(...)
    local k, v = next(...)
    return k, setmetatable(v or scope.empty, scope.ACTION)
  end
  function scope.GetActions()
    return iter, scope.read(OBroBindsDB, scope.class, scope.spec) or scope.empty
  end
end

function scope.GetAction(binding)
  return setmetatable(scope.read(OBroBindsDB, scope.class, scope.spec, binding) or scope.empty, scope.ACTION)
end

do
  local function save(action, ...)
    for i = 1, select("#", ...) do
      action[i] = select(i, ...)
    end
    return action
  end
  function scope.SaveAction(binding, ...)
    OBroBindsDB = scope.write(OBroBindsDB, scope.class, scope.spec, binding, save, ...)
    local action = setmetatable(scope.read(OBroBindsDB, scope.class, scope.spec, binding) or scope.empty, scope.ACTION)
    action:SetOverrideBinding(binding)
    scope:dispatch("ADDON_BINDING_UPDATED", binding)
  end
end

function scope.DeleteAction(binding)
  OBroBindsDB = scope.write(OBroBindsDB, scope.class, scope.spec, binding, nil)
  local index = string.match(GetBindingAction(binding, true), "CLICK OBroBindsSecureBlobButton(%d+):LeftButton")
  if index then
    scope.secureButtons.index = scope.secureButtons.index - 1
    local button = table.remove(scope.secureButtons, tonumber(index))
    table.insert(scope.secureButtons, button)
  end
  SetOverrideBinding(scope.root, false, binding, nil)
  scope:dispatch("ADDON_BINDING_UPDATED", binding)
end

function scope.ToggleActionLock(binding)
  local value = not scope.GetAction(binding).locked and true or nil
  OBroBindsDB = scope.write(OBroBindsDB, scope.class, scope.spec, binding, scope.ACTION.locked, value)
  scope:dispatch("ADDON_BINDING_UPDATED", binding)
end

function scope.PromoteToAction(binding)
  local kind, name = string.match(GetBindingAction(binding, false), "^(%w+) (.*)$")
  if kind == 'SPELL' then
    local icon, _, _, _, id = select(3, GetSpellInfo(name))
    assert(name ~= nil)
    scope.SaveAction(binding, kind, id, name, icon or 134400)
    scope:dispatch("ADDON_BINDING_UPDATED", binding)
  elseif kind == 'MACRO' then
    local id = GetMacroIndexByName(name)
    local icon = select(2, GetMacroInfo(name))
    assert(name ~= nil)
    scope.SaveAction(binding, kind, id, name, icon or 134400)
    scope:dispatch("ADDON_BINDING_UPDATED", binding)
  elseif kind == 'ITEM' then
    local link, _, _, _, _, _, _, _, icon = select(2, GetItemInfo(name))
    local id = link and select(4, string.find(link, "^|c%x+|H(%a+):(%d+)[|:]"))
    assert(name ~= nil)
    scope.SaveAction(binding, kind, id, name, icon or 134400)
    scope:dispatch("ADDON_BINDING_UPDATED", binding)
  end
end

function scope.ImportMacroToAction(_, button, binding)
  local _, name = string.match(GetBindingAction(binding, false), "^(%w+) (.*)$")
  local _, icon, body = GetMacroInfo(name)
  if icon and body then
    SetBinding(binding, nil)
    SaveBindings(GetCurrentBindingSet())
    scope.SaveAction(binding, "BLOB", name, body, icon)
  else
    print("Macro", name, "not found")
  end
  CloseDropDownMenus()
end

do
  local function cleanup(e, ...)
    scope.__pickup = nil
    scope.dequeue("CURSOR_UPDATE", cleanup)
    return e(...)
  end
  function scope.PickupAction(binding)
    if scope.mainbar[binding] then
      PickupAction(scope.mainbar[binding] + scope.offset - 1)
      return
    end
    local action = scope.GetAction(binding)
    if not action.locked then
      if action.SPELL then
        PickupSpell(action.id)
        if not GetCursorInfo() then
          local macro = CreateMacro("__OBRO_TMP", action:Icon())
          PickupMacro(macro)
          DeleteMacro(macro)
          scope.__pickup = action
          scope.enqueue("CURSOR_UPDATE", cleanup)
        end
      elseif action.MACRO then
        PickupMacro(action.name)
      elseif action.ITEM then
        PickupItem(action.id)
      elseif action.BLOB then
        local macro = CreateMacro("__OBRO_TMP", action:Icon())
        PickupMacro(macro)
        DeleteMacro(macro)
        scope.enqueue("CURSOR_UPDATE", cleanup)
        scope.__pickup = action
      elseif action.kind then
        assert(false, "Unhandled pickup: "..action.kind)
      end
      scope.DeleteAction(binding)
    end
  end
end

function scope.ReceiveAction(binding)
  if scope.mainbar[binding] then
    PlaceAction(scope.mainbar[binding] + scope.offset - 1)
    return
  end
  if not scope.GetAction(binding).locked then
    local kind, id, link, arg1, arg2 = GetCursorInfo()
    if kind == "spell" then
      ClearCursor()
      local id = arg2 or arg1
      local name, _, icon = GetSpellInfo(id)
      assert(id ~= nil)
      assert(name ~= nil)
      assert(icon ~= nil)
      scope.PickupAction(binding)
      scope.SaveAction(binding, strupper(kind), id, name, icon)

    elseif kind == "item" then
      ClearCursor()
      local name = select(3, string.match(link, "^|c%x+|H(%a+):(%d+).+|h%[([^%]]+)"))
      local icon = select(10, GetItemInfo(id))
      assert(link ~= nil)
      assert(name ~= nil)
      assert(icon ~= nil)
      scope.PickupAction(binding)
      scope.SaveAction(binding, strupper(kind), id, name, icon)

    elseif kind == "macro" and id == 0 then
      local action = scope.__pickup
      ClearCursor()
      assert(scope.__pickup == nil)
      scope.PickupAction(binding)
      scope.SaveAction(binding, unpack(action, 1, 5))

    elseif kind == "macro" then
      ClearCursor()
      local name, icon = GetMacroInfo(id)
      assert(type(id) == "number")
      assert(id ~= nil)
      assert(name ~= nil)
      assert(icon ~= nil)
      scope.PickupAction(binding)
      scope.SaveAction(binding, strupper(kind), id, name, icon)
    elseif kind then
      assert(false, "Unhandled receive: "..kind)
    end
  end
end
