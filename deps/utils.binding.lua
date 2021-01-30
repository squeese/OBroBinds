local _A = select(2, ...)
local read, write, map, push = _A.read, _A.write, _A.map, _A.push
local OVERRIDE = { kind = 1, id = 2, name = 3, icon = 4, locked = 5, SPELL = 6, MACRO = 6, ITEM = 6, BLOB = 6 }
local empty = {}

function OVERRIDE:__index(key)
  if self == empty then return nil end
  local value = OVERRIDE[key]
  if type(value) == 'number' then
    if value == 6 then
      return rawget(self, 1) == key
    elseif value == 4 then
      local kind = rawget(self, 1)
      if kind == "SPELL" then
        return select(3, GetSpellInfo(rawget(self, 2))) or rawget(self, 4)
      elseif kind == "MACRO" then
        return select(2, GetMacroInfo(rawget(self, 3))) or rawget(self, 4)
      elseif kind == "ITEM" then
        return select(10, GetItemInfo(rawget(self, 2) or 0)) or rawget(self, 4)
      elseif kind == "BLOB" then
        return 441148
      end
      return nil
    else
      return rawget(self, value)
    end
  end
  return value
end

function OVERRIDE:setBinding(root, binding)
  if self.SPELL then
    SetOverrideBindingSpell(root, false, binding, GetSpellInfo(self.id) or self.name)
  elseif self.MACRO then
    SetOverrideBindingMacro(root, false, binding, self.name)
  elseif self.ITEM then
    SetOverrideBindingItem(root, false, binding, self.name)
  elseif self.BLOB then
  end
end

function _A.UpdatePlayerBindings(e, root, ...)
  print("UpdatePlayerBindings", e.key, root.class)
  root.class = select(2, UnitClass("player"))
  root.spec = GetSpecialization()
  ClearOverrideBindings(root)
  for binding, override in map(nil, OBroBindsDB, root.class, root.spec) do
    setmetatable(override, OVERRIDE):setBinding(root, binding)
  end
  return e(root, ...)
end

function _A.GetOverrideBinding(e, root, binding)
  return e(setmetatable(read(OBroBindsDB, root.class, root.spec, binding) or empty, OVERRIDE))
end

function _A.DelOverrideBinding(e, root, binding)
  if read(OBroBindsDB, root.class, root.spec, binding) then
    OBroBindsDB = write(OBroBindsDB, root.class, root.spec, binding, nil)
    return e(root, binding)
  end
  return e, root, binding
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

--do
  --local function CURSOR_UPDATE(e, frame)
    --frame.__cursor = nil
    --frame:UnregisterEvent("CURSOR_UPDATE")
    --return e:once(frame)
  --end
  --function _A.PickupOverrideEntry(e, frame, button)
    --local binding = frame.modifier..button.key
    --if not read(OBroBindsDB, frame.class, frame.spec, binding, 5) then
      --if frame.mainbar[binding] then
        --PickupAction(frame.mainbar[binding] + frame.offset - 1)
        --return e:next(frame, button)
      --end
      --local kind, id, name, icon = select(3, frame:dispatch("GET_OVERRIDE_ENTRY", binding))
      --if kind == "SPELL" then
        --PickupSpell(id)
        --if not GetCursorInfo() then
          --local macro = CreateMacro("__OBRO_TMP", select(3, GetSpellInfo(id)) or icon)
          --PickupMacro(macro)
          --DeleteMacro(macro)
          --frame.__cursor = read(OBroBindsDB, frame.class, frame.spec, binding)
          --frame:RegisterEvent("CURSOR_UPDATE")
          --_A.listen("CURSOR_UPDATE", CURSOR_UPDATE)
        --end
      --elseif kind == "MACRO" then
        --PickupMacro(name)
      --elseif kind == "ITEM" then
        --PickupItem(id)
      --elseif kind then
        --assert(false, "Unhandled pickup: "..kind)
      --end
      --frame:dispatch("DEL_OVERRIDE_ENTRY", true, binding)
    --end
    --return e:next(frame, button)
  --end
--end

--function _A.ReceiveOverrideEntry(e, frame, button)
  --local binding = frame.modifier..button.key
  --if not read(OBroBindsDB, frame.class, frame.spec, binding, 5) then
    --if frame.mainbar[binding] then
      --PlaceAction(frame.mainbar[binding] + frame.offset - 1)
      --return e:next(frame, button)
    --end
    --local kind, id, link, arg1, arg2 = GetCursorInfo()
    --if kind == "spell" then
      --ClearCursor()
      --frame:dispatch("PICKUP_OVERRIDE_ENTRY", button)
      --local id = arg2 or arg1
      --local name, _, icon = GetSpellInfo(id)
      --assert(id ~= nil, "GetCursorInfo() on spell, id should never be nil")
      --assert(name ~= nil, "GetCursorInfo() on spell, name should never be nil")
      --assert(icon ~= nil, "GetCursorInfo() on spell, icon should never be nil")
      --frame:dispatch("SET_OVERRIDE_ENTRY", true, binding, strupper(kind), id, name, icon)
    --elseif kind == "macro" and id == 0 then
      --local action = frame.__cursor
      --ClearCursor()
      --frame:dispatch("PICKUP_OVERRIDE_ENTRY", button)
      --frame:dispatch("SET_OVERRIDE_ENTRY", true, binding, action[KIND], action[ID], action[NAME], action[ICON])
    --elseif kind == "macro" then
      --ClearCursor()
      --frame:dispatch("PICKUP_OVERRIDE_ENTRY", button)
      --local name, icon = GetMacroInfo(id)
      --assert(id ~= nil, "GetCursorInfo() on macro, id should never be nil")
      --assert(type(id) == "number", "GetCursorInfo() on macro, id should always be number")
      --assert(name ~= nil, "GetCursorInfo() on macro, name should never be nil")
      --assert(icon ~= nil, "GetCursorInfo() on macro, icon should never be nil")
      --frame:dispatch("SET_OVERRIDE_ENTRY", true, binding, strupper(kind), id, name, icon)
    --elseif kind == "item" then
      --ClearCursor()
      --local name = select(3, string.match(link, "^|c%x+|H(%a+):(%d+).+|h%[([^%]]+)"))
      --local icon = select(10, GetItemInfo(id))
      --assert(link ~= nil, "GetCursorInfo() on item, link should never be nil")
      --assert(name ~= nil, "GetCursorInfo() on item, name should never be nil")
      --assert(icon ~= nil, "GetCursorInfo() on item, icon should never be nil")
      --frame:dispatch("PICKUP_OVERRIDE_ENTRY", button)
      --frame:dispatch("SET_OVERRIDE_ENTRY", true, binding, strupper(kind), id, name, icon)
    --elseif kind then
      --assert(false, "Unhandled receive: "..kind)
    --end
  --end
  --return e:next(frame, button)
--end

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
