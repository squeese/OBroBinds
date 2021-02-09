local scope = select(2, ...)
local ACTION, NIL, CLASS, SPECC = scope.ACTION, scope.NIL, nil, nil
local dbRead, dbWrite, dbReadAction, dbWriteAction = scope.dbRead, scope.dbWrite

function scope.UpdatePlayerVariables(next, ...)
  scope.CLASS = select(2, UnitClass("player"))
  scope.SPECC = GetSpecialization()
  CLASS, SPECC = scope.CLASS, scope.SPECC
  return next(...)
end

do
  local function setBinding(binding, action)
    if action.spell then
      SetOverrideBindingSpell(scope.ROOT, false, binding, GetSpellInfo(action.id) or action.name)
    elseif action.macro then
      SetOverrideBindingMacro(scope.ROOT, false, binding, action.name)
    elseif action.item then
      SetOverrideBindingItem(scope.ROOT, false, binding, action.name)
    elseif action.blob then
      SetOverrideBinding(scope.ROOT, false, binding, scope.MACROBUTTONS:next(binding, action))
    end
  end

  function scope.UpdatePlayerBindings(next, ...)
    ClearOverrideBindings(scope.ROOT)
    scope.MACROBUTTONS:reset()
    for binding, action in scope.GetActions() do
      setBinding(binding, action)
    end
    return next(...)
  end

  function scope.UpdateActionBinding(next, event, binding, ...)
    local action = scope.GetAction(binding)
    scope.MACROBUTTONS:release(binding)
    SetOverrideBinding(scope.ROOT, false, binding, nil)
    if action.kind then
      setBinding(binding, action)
    end
    return next(...)
  end
end

function scope.UpdateUnknownSpells(next, ...)

  for binding, action in scope.GetActions() do
    if action.spell and not action.id then
      local icon, _, _, _, id = select(3, GetSpellInfo(action.name))
      action[2], action[4] = id, icon or action.icon

    elseif action.blob and not action.script and action.icon == 134400 then
      local macro = CreateMacro("__TMP__", "INV_MISC_QUESTIONMARK", action.body)
      _, icon = GetMacroInfo(macro)
      DeleteMacro(macro)
      action[4] = icon or action.icon
    end
  end
  return next(...)
end


function dbReadAction(...)
  return dbRead(CLASS, SPECC, ...)
end
scope.dbReadAction = dbReadAction

function dbWriteAction(...)
  return dbWrite(CLASS, SPECC, ...)
end
scope.dbWriteAction = dbWriteAction

function scope.GetAction(binding)
  return setmetatable(dbReadAction(binding) or NIL, ACTION)
end

do
  local function iter(...)
    local k, v = next(...)
    return k, setmetatable(v or NIL, ACTION)
  end
  function scope.GetActions()
    return iter, dbReadAction() or NIL
  end
end

local dispatch = scope.dispatch
local bindingModifiers = scope.bindingModifiers
function scope.DeleteAction(binding)
  if dbWriteAction(binding, nil) then
    dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
    return true
  end
end

do
  local function deleteAction(binding, kind)
    local action = scope.GetAction(binding)
    if action ~= NIL and action.kind ~= kind then
      return scope.DeleteAction(binding)
    end
  end

  function scope.UpdateActionSpell(binding, id, name, icon)
    deleteAction(binding, ACTION.spell)
    if scope.match(true,
      dbWriteAction(binding, ACTION.kind, ACTION.spell),
      dbWriteAction(binding, ACTION.id,   id),
      dbWriteAction(binding, ACTION.name, name),
      dbWriteAction(binding, ACTION.icon, icon or 134400)) then
      dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
      return true
    end
  end

  function scope.UpdateActionItem(binding, id, name, icon)
    deleteAction(binding, ACTION.item)
    if scope.match(true,
      dbWriteAction(binding, ACTION.kind, ACTION.item),
      dbWriteAction(binding, ACTION.id,   id),
      dbWriteAction(binding, ACTION.name, name),
      dbWriteAction(binding, ACTION.icon, icon or 134400)) then
      dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
      return true
    end
  end

  function scope.UpdateActionMacro(binding, id, name, icon)
    deleteAction(binding, ACTION.macro)
    if scope.match(true,
      dbWriteAction(binding, ACTION.kind, ACTION.macro),
      dbWriteAction(binding, ACTION.id,   id),
      dbWriteAction(binding, ACTION.name, name),
      dbWriteAction(binding, ACTION.icon, icon or 134400)) then
      dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
      return true
    end
  end

  function scope.UpdateActionBlob(binding, id, body, icon)
    deleteAction(binding, ACTION.blob)
    if scope.match(true,
      dbWriteAction(binding, ACTION.kind, ACTION.blob),
      dbWriteAction(binding, ACTION.id,   id),
      dbWriteAction(binding, ACTION.body, body),
      dbWriteAction(binding, ACTION.icon, icon or 134400)) then
      dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
      return true
    end
  end

  --function scropt.UpdateActiobBlobIcon(binding, )

  function scope.UpdateAction(binding, kind, ...)
    if kind == ACTION.spell then
      return scope.UpdateActionSpell(binding, ...)
    elseif kind == ACTION.item then
      return scope.UpdateActionItem(binding, ...)
    elseif kind == ACTION.macro then
      return scope.UpdateActionMacro(binding, ...)
    elseif kind == ACTION.blob then
      return scope.UpdateActionBlob(binding, ...)
    end
  end
end

function scope.UpdateActionLock(binding)
  local value = not dbReadAction(binding, ACTION.lock) and true or nil
  if dbWriteAction(binding, ACTION.lock, value) then
    dispatch(scope, "ADDON_ACTION_UPDATED", binding, bindingModifiers(binding))
    return true
  end
end

function scope.ActionIcon(action)
  if action.spell then
    return select(3, GetSpellInfo(action.id)) or action.icon 
  elseif action.macro then
    return select(2, GetMacroInfo(action.name)) or action.icon
  elseif action.item then
    return select(10, GetItemInfo(action.id or 0)) or action.icon
  elseif action.blob then
    return action.icon or 441148
  end
  return action.icon or nil
end

do
  local function copy(a, b)
    for k, v in pairs(b) do
      a[k] = v
    end
    return a
  end
  local function cleanup(e, ...)
    scope.__pickup = nil
    scope.dequeue("CURSOR_UPDATE", cleanup)
    return e(...)
  end
  function scope.PickupAction(binding)
    if scope.PORTAL_BUTTONS[binding] then
      PickupAction(scope.PORTAL_BUTTONS[binding] + scope.STANCE_OFFSET - 1)
      return true
    end
    local action = scope.GetAction(binding)
    if action.lock then
      return false
    elseif action.spell then
      PickupSpell(action.id)
      if not GetCursorInfo() then
        local macro = CreateMacro("__OBRO_TMP", scope.ActionIcon(action))
        PickupMacro(macro)
        DeleteMacro(macro)
        scope.__pickup = copy(scope.poolAcquire(nil), action)
        scope.enqueue("CURSOR_UPDATE", cleanup)
      end
    elseif action.macro then
      PickupMacro(action.name)
    elseif action.item then
      PickupItem(action.id)
    elseif action.blob then
      local macro = CreateMacro("__OBRO_TMP", scope.ActionIcon(action))
      PickupMacro(macro)
      DeleteMacro(macro)
      scope.enqueue("CURSOR_UPDATE", cleanup)
      --scope.__pickup = {unpack(action, 1, 6)}
      scope.__pickup = copy(scope.poolAcquire(nil), action)
    elseif action.kind then
      assert(false, "Unhandled pickup: "..action.kind)
    end
    return scope.DeleteAction(binding)
  end
end

function scope.ReceiveAction(binding)
  if scope.PORTAL_BUTTONS[binding] then
    PlaceAction(scope.PORTAL_BUTTONS[binding] + scope.STANCE_OFFSET - 1)
    return true
  elseif scope.GetAction(binding).locked then
    return false
  end
  local kind, id, link, arg1, arg2 = GetCursorInfo()
  if kind == "spell" then
    ClearCursor()
    local id = arg2 or arg1
    local name, _, icon = GetSpellInfo(id)
    assert(id ~= nil)
    assert(name ~= nil)
    assert(icon ~= nil)
    return scope.match(true,
      scope.PickupAction(binding),
      scope.UpdateActionSpell(binding, id, name, icon))

  elseif kind == "item" then
    ClearCursor()
    local name = select(3, string.match(link, "^|c%x+|H(%a+):(%d+).+|h%[([^%]]+)"))
    local icon = select(10, GetItemInfo(id))
    assert(link ~= nil)
    assert(name ~= nil)
    assert(icon ~= nil)
    return scope.match(true,
      scope.PickupAction(binding),
      scope.UpdateActionItem(binding, id, name, icon))

  elseif kind == "macro" and id == 0 then
    local action = scope.__pickup
    ClearCursor()
    assert(scope.__pickup == nil)
    if scope.match(true, scope.PickupAction(binding), scope.dbWriteAction(binding, action)) then
      dispatch(scope, "ADDON_ACTION_UPDATED", binding, scope.bindingModifiers(binding))
      return true
    end

  elseif kind == "macro" then
    ClearCursor()
    local name, icon = GetMacroInfo(id)
    assert(type(id) == "number")
    assert(id ~= nil)
    assert(name ~= nil)
    assert(icon ~= nil)
    return scope.match(true,
      scope.PickupAction(binding),
      scope.UpdateActionMacro(binding, id, name, icon))

  elseif kind then
    assert(false, "Unhandled receive: "..kind)
  end
end

function scope.PromoteToAction(binding)
  local kind, name = string.match(GetBindingAction(binding, false), "^(%w+) (.*)$")
  if kind == 'SPELL' then
    local icon, _, _, _, id = select(3, GetSpellInfo(name))
    assert(name ~= nil)
    return scope.UpdateActionSpell(binding, id, name, icon or 134400)
  elseif kind == 'MACRO' then
    local id = GetMacroIndexByName(name)
    local icon = select(2, GetMacroInfo(name))
    assert(name ~= nil)
    return scope.UpdateActionMacro(binding, id, name, icon or 134400)
  elseif kind == 'ITEM' then
    local link, _, _, _, _, _, _, _, icon = select(2, GetItemInfo(name))
    local id = link and select(4, string.find(link, "^|c%x+|H(%a+):(%d+)[|:]"))
    assert(name ~= nil)
    return scope.UpdateActionItem(binding, id, name, icon or 134400)
  end
end

function scope.PromoteToMacroBlob(binding)
  local _, name = string.match(GetBindingAction(binding, false), "^(%w+) (.*)$")
  local _, icon, body = GetMacroInfo(name)
  if icon and body then
    return scope.UpdateActionBlob(binding, name, body, icon)
  else
    print("Macro", name, "not found")
  end
end

function scope.PromoteToMacroBlobFromOverride(binding)
  local name, icon = unpack(scope.GetAction(binding), 3, 4)
  local mIcon, body = select(2, GetMacroInfo(name))
  if not body then
    print("Macro", name, "not found")
    return false
  end
  return scope.UpdateActionBlob(binding, name, body, mIcon or icon)
end
