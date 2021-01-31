local _A = select(2, ...)
local read, write, map, push = _A.read, _A.write, _A.map, _A.push
local empty = {}


function OVERRIDE:Pickup()
end


function _A.GetOverrideBinding(e, root, binding)
  return e(setmetatable(read(OBroBindsDB, root.class, root.spec, binding) or empty, OVERRIDE))
end

function _A.DelOverrideBinding(e, root, binding)
  OBroBindsDB = write(OBroBindsDB, root.class, root.spec, binding, nil)
  return e(root, binding)
end

function _A.UpdateUnknownSpells(e, root, ...)
  for binding, override in map(nil, read(OBroBindsDB, root.class, root.spec)) do
    setmetatable(override, OVERRIDE)
    if override.SPELL and not override.id then
      local icon, _, _, _, id = select(3, GetSpellInfo(override.name))
      action[1], action[4] = id, icon or override.icon
    end
  end
  return e(root, ...)
end

--do
  --local function save(override, ...)
    --for i = 1, 5 do
      --override[i] = select(i, ...)
    --end
    --return override
  --end
  --function _A.SaveOverrideBinding(e, root, binding, ...)
    --OBroBindsDB = write(OBroBindsDB, root.class, root.spec, binding, save, ...)
    --return _A.GetOverrideBinding(e, root, binding)
  --end
--end


--function _A.DelOverrideEntry(e, frame, save, binding)
  --SetOverrideBinding(frame, false, binding, nil)
  --if save then
    --OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, nil)
  --end
  --return e:next(frame, binding)
--end

do
  local function CURSOR_UPDATE(e, frame)
    frame.__cursor = nil
    frame:UnregisterEvent("CURSOR_UPDATE")
    return e:once(frame)
  end
  function _A.PickupOverrideBinding(e, root, button, ...)
    local page = root.pageKeyboard
    local binding = page.modifier..button.key
    if not read(OBroBindsDB, root.class, root.spec, binding, OVERRIDE.locked) then
      if page.mainbar[binding] then
        PickupAction(page.mainbar[binding] + page.offset - 1)
        return e(root, button, ...)
      end
      local override = roo
      --local kind, id, name, icon = select(3, root:dispatch("GET_OVERRIDE_ENTRY", binding))
      --if kind == "SPELL" then
        --PickupSpell(id)
        --if not GetCursorInfo() then
          --local macro = CreateMacro("__OBRO_TMP", select(3, GetSpellInfo(id)) or icon)
          --PickupMacro(macro)
          --DeleteMacro(macro)
          --root.__cursor = read(OBroBindsDB, root.class, root.spec, binding)
          --root:RegisterEvent("CURSOR_UPDATE")
          --_A.listen("CURSOR_UPDATE", CURSOR_UPDATE)
        --end
      --elseif kind == "MACRO" then
        --PickupMacro(name)
      --elseif kind == "ITEM" then
        --PickupItem(id)
      --elseif kind then
        --assert(false, "Unhandled pickup: "..kind)
      --end
      --root:dispatch("DEL_OVERRIDE_ENTRY", true, binding)
    end
    return e(root, button, ...)
  end
end

function _A.ReceiveOverrideBinding(e, root, button, ...)
  local page = root.pageKeyboard
  local binding = page.modifier..button.key
  if not read(OBroBindsDB, root.class, root.spec, binding, OVERRIDE.locked) then
    if page.mainbar[binding] then
      PlaceAction(page.mainbar[binding] + page.offset - 1)
      return e(root, button, ...)
    end
    local kind, id, link, arg1, arg2 = GetCursorInfo()
    if kind == "spell" then
      ClearCursor()
      root:dispatch("ADDON_PICKUP_OVERRIDE_BINDING", button)
      local id = arg2 or arg1
      local name, _, icon = GetSpellInfo(id)

      assert(id ~= nil, "GetCursorInfo() on spell, id should never be nil")
      assert(name ~= nil, "GetCursorInfo() on spell, name should never be nil")
      assert(icon ~= nil, "GetCursorInfo() on spell, icon should never be nil")
      root:dispatch("SET_OVERRIDE_ENTRY", true, binding, strupper(kind), id, name, icon)

    elseif kind == "macro" and id == 0 then
      local action = root.__cursor
      ClearCursor()
      root:dispatch("PICKUP_OVERRIDE_ENTRY", button)
      root:dispatch("SET_OVERRIDE_ENTRY", true, binding, action[KIND], action[ID], action[NAME], action[ICON])
    elseif kind == "macro" then
      ClearCursor()
      root:dispatch("PICKUP_OVERRIDE_ENTRY", button)
      local name, icon = GetMacroInfo(id)
      assert(id ~= nil, "GetCursorInfo() on macro, id should never be nil")
      assert(type(id) == "number", "GetCursorInfo() on macro, id should always be number")
      assert(name ~= nil, "GetCursorInfo() on macro, name should never be nil")
      assert(icon ~= nil, "GetCursorInfo() on macro, icon should never be nil")
      root:dispatch("SET_OVERRIDE_ENTRY", true, binding, strupper(kind), id, name, icon)
    elseif kind == "item" then
      ClearCursor()
      local name = select(3, string.match(link, "^|c%x+|H(%a+):(%d+).+|h%[([^%]]+)"))
      local icon = select(10, GetItemInfo(id))
      assert(link ~= nil, "GetCursorInfo() on item, link should never be nil")
      assert(name ~= nil, "GetCursorInfo() on item, name should never be nil")
      assert(icon ~= nil, "GetCursorInfo() on item, icon should never be nil")
      root:dispatch("PICKUP_OVERRIDE_ENTRY", button)
      root:dispatch("SET_OVERRIDE_ENTRY", true, binding, strupper(kind), id, name, icon)
    elseif kind then
      assert(false, "Unhandled receive: "..kind)
    end
  end
  return next(root, button)
end

--function _A.PromoteOverrideEntry(e, frame, binding)
  --local action = GetBindingAction(binding, false)
  --local kind, name = string.match(action, "^(%w+) (.*)$")
  --if kind == 'SPELL' then
    --local icon, _, _, _, id = select(3, GetSpellInfo(name))
    --assert(name ~= nil)
    --frame:dispatch("SET_OVERRIDE_ENTRY", true, binding, kind, id, name, icon or 134400)
  --elseif kind == 'MACRO' then
    --local id = GetMacroIndexByName(name)
    --local icon = select(2, GetMacroInfo(name))
    --assert(name ~= nil)
    --frame:dispatch("SET_OVERRIDE_ENTRY", true, binding, kind, id, name, icon or 134400)
  --elseif kind == 'ITEM' then
    --local link, _, _, _, _, _, _, _, icon = select(2, GetItemInfo(name))
    --local id = link and select(4, string.find(link, "^|c%x+|H(%a+):(%d+)[|:]"))
    --assert(name ~= nil)
    --frame:dispatch("SET_OVERRIDE_ENTRY", true, binding, kind, id, name, icon or 134400)
  --else
    --assert(false, "Unhandled type: "..kind)
  --end
  --return e:next(frame, binding)
--end

--function _A.LockOverrideEntry(e, frame, binding)
  --local value = not read(OBroBindsDB, frame.class, frame.spec, binding, 5) and true or nil
  --OBroBindsDB = write(OBroBindsDB, frame.class, frame.spec, binding, 5, value)
  --return e:next(frame, binding)
--end
