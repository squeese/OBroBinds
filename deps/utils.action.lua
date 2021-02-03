local scope = select(2, ...)
scope.ACTION = { kind = 1, id = 2, name = 3, icon = 4, locked = 5, SPELL = 6, MACRO = 6, ITEM = 6, BLOB = 6 }

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
    return 441148
  end
  return self.icon or nil
end

function scope.ActionIterator(...)
  local k, v = next(...)
  return k, setmetatable(v or scope.empty, scope.ACTION)
end

function scope.GetActions()
  return scope.ActionIterator, scope.read(OBroBindsDB, scope.class, scope.spec) or scope.empty
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
  end
end


function scope.ToggleActionLock(binding)
  local value = not scope.GetAction(binding).locked and true or nil
  OBroBindsDB = scope.write(OBroBindsDB, scope.class, scope.spec, binding, scope.ACTION.locked, value)
end

function scope.DeleteAction(binding)
  OBroBindsDB = scope.write(OBroBindsDB, scope.class, scope.spec, binding, nil)
  SetOverrideBinding(scope.root, false, binding, nil)
end

function scope.PromoteToAction(binding)
  local kind, name = string.match(GetBindingAction(binding, false), "^(%w+) (.*)$")
  if kind == 'SPELL' then
    local icon, _, _, _, id = select(3, GetSpellInfo(name))
    assert(name ~= nil)
    scope.dbSaveAction(binding, kind, id, name, icon or 134400)
  elseif kind == 'MACRO' then
    local id = GetMacroIndexByName(name)
    local icon = select(2, GetMacroInfo(name))
    assert(name ~= nil)
    scope.dbSaveAction(binding, kind, id, name, icon or 134400)
  elseif kind == 'ITEM' then
    local link, _, _, _, _, _, _, _, icon = select(2, GetItemInfo(name))
    local id = link and select(4, string.find(link, "^|c%x+|H(%a+):(%d+)[|:]"))
    assert(name ~= nil)
    scope.dbSaveAction(binding, kind, id, name, icon or 134400)
  else
    assert(false, "Unhandled type: "..kind)
  end
end

