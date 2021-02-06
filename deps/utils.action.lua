local scope = select(2, ...)




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
  scope.secureButtons:release(binding)
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
    if scope.PORTAL_BUTTONS[binding] then
      PickupAction(scope.PORTAL_BUTTONS[binding] + scope.STANCE_OFFSET - 1)
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
  if scope.PORTAL_BUTTONS[binding] then
    PlaceAction(scope.PORTAL_BUTTONS[binding] + scope.STANCE_OFFSET - 1)
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


scope.secureButtons = { index = 0 }

function scope.secureButtons:next(binding)
  local index = string.match(GetBindingAction(binding, true), "CLICK OBroBindsSecureBlobButton(%d+):LeftButton")
  if index then
    local button = self[tonumber(index)]
    if button.stack then
      local event = scope.poolAcquire(scope.EVENT, button.stack)
      scope.poolRelease(event, event())
      scope.poolRelease(button.stack)
      button.stack = nil
    end
    return button
  end
  self.index = self.index + 1
  if self.index > #self then
    local button = CreateFrame("Button", "OBroBindsSecureBlobButton"..self.index, nil, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp")
    button:SetAttribute("type", "macro")
    button.command = "CLICK "..button:GetName()..":LeftButton"
    table.insert(self, button)
  end
  return self[self.index]
end

function scope.secureButtons:release(binding)
  local index = string.match(GetBindingAction(binding, true), "CLICK OBroBindsSecureBlobButton(%d+):LeftButton")
  if index then
    if button.stack then
      local event = scope.poolAcquire(scope.EVENT, button.stack)
      scope.poolRelease(event, event())
      scope.poolRelease(button.stack)
      button.stack = nil
    end
    table.insert(self, table.remove(self, tonumber(index)))
    self.index = self.index - 1
  end
end

function scope.ACTION:SetOverrideBinding(binding)
  if self.SPELL then
    SetOverrideBindingSpell(scope.root, false, binding, GetSpellInfo(self.id) or self.name)
  elseif self.MACRO then
    SetOverrideBindingMacro(scope.root, false, binding, self.name)
  elseif self.ITEM then
    SetOverrideBindingItem(scope.root, false, binding, self.name)

  elseif self.BLOB and self.script then
    local button = scope.secureButtons:next(binding)

    if not button.update then
      button.update = function(text)
        if InCombatLockdown() then
          return
        end
        button:SetAttribute("macrotext", text)
      end
    end
    -- TODO: pcall
    local init, err = loadstring([[
      local STACK, update = ...
    ]]..self.text)

    if err then
      print("Error making script ("..binding.."): ", err)
    else
      button.stack = scope.poolAcquire(scope.STACK, init(scope.STACK, button.update))
      local event = scope.poolAcquire(scope.EVENT, button.stack)
      scope.poolRelease(event, event())
      SetOverrideBinding(scope.root, false, binding, button.command)
    end

  elseif self.BLOB then
    local button = scope.secureButtons:next(binding)
    button:SetAttribute("macrotext", self.text)
    SetOverrideBinding(scope.root, false, binding, button.command)

  else
    SetOverrideBinding(scope.root, false, binding, nil)
  end
end
