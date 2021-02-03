local scope = select(2, ...)



function scope.UpdateUnknownSpells(e, ...)
  for binding, action in scope.dbActions() do
    if action.SPELL and not action.id then
      local icon, _, _, _, id = select(3, GetSpellInfo(action.name))
      action[1], action[4] = id, icon or action.icon
    end
  end
  return e(...)
end






do
  local function Update(button)
    if not button:IsVisible() then return end
    GameTooltip:SetOwner(button, 'ANCHOR_BOTTOMRIGHT')
    local binding = scope.modifier..button.key
    if scope.mainbar[binding] then
      GameTooltip:SetAction(scope.mainbar[binding] + scope.offset - 1)
      return
    end
    local action = scope.dbGetAction(binding)
    if action.SPELL then
      if action.id and GetSpellInfo(action.id) then
        GameTooltip:SetSpellByID(action.id)
      else
        GameTooltip:SetText("SPELL "..action.name)
      end
    elseif action.MACRO then
      GameTooltip:SetText("MACRO "..action.name)
    elseif action.ITEM then
      local level = select(4, GetItemInfo(action.id or 0))
      if action.id and level then
        GameTooltip:SetItemKey(action.id, level, 0)
      else
        GameTooltip:SetText("ITEM "..action.name)
      end
    elseif action.BLOB then
      GameTooltip:SetText("BLOB "..action.id)
    elseif GetBindingAction(binding, false) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding, false))
    elseif GetBindingAction(binding, true) ~= "" then
      GameTooltip:SetText(GetBindingAction(binding, true))
    else
      GameTooltip:Hide()
    end
  end
  local current
  function scope.UpdateTooltip(e, button, ...)
    current = button
    Update(button)
    return e(button, ...)
  end
  function scope.RefreshTooltip(e, ...)
    if current and GetMouseFocus() == current then
      Update(current)
    end
    return e(...)
  end
end

do
  --local function CURSOR_UPDATE(e, frame)
    --frame.__cursor = nil
    --frame:UnregisterEvent("CURSOR_UPDATE")
    --return e:once(frame)
  --end
  function scope.PickupOverrideBinding(e, button, ...)
    local binding = scope.modifier..button.key
    if scope.mainbar[binding] then
      PickupAction(scope.mainbar[binding] + scope.offset - 1)
      return e(button, ...)
    end
    local action = scope.dbGetAction(binding)
    if not action.locked then
      if action.SPELL then
        PickupSpell(action.id)
        --if not GetCursorInfo() then
          --local macro = CreateMacro("__OBRO_TMP", select(3, GetSpellInfo(id)) or icon)
          --PickupMacro(macro)
          --DeleteMacro(macro)
          --root.__cursor = read(OBroBindsDB, root.class, root.spec, binding)
          --root:RegisterEvent("CURSOR_UPDATE")
          --_A.listen("CURSOR_UPDATE", CURSOR_UPDATE)
        --end
      elseif action.MACRO then
        PickupMacro(action.name)
      elseif action.ITEM then
        PickupItem(action.id)
      elseif action.kind then
        assert(false, "Unhandled pickup: "..action.kind)
      end
      scope.dbDeleteAction(binding)
    end
    return e(button, ...)
  end
end

function scope.ReceiveOverrideBinding(e, button, ...)
  local binding = scope.modifier..button.key
  if scope.mainbar[binding] then
    PlaceAction(scope.mainbar[binding] + scope.offset - 1)
    return e(button, ...)
  end

  if not scope.dbGetAction(binding).locked then
    local kind, id, link, arg1, arg2 = GetCursorInfo()

    if kind == "spell" then
      ClearCursor()
      scope:dispatch("ADDON_PICKUP_OVERRIDE_BINDING", button)
      local id = arg2 or arg1
      local name, _, icon = GetSpellInfo(id)
      assert(id ~= nil)
      assert(name ~= nil)
      assert(icon ~= nil)
      scope.dbSaveAction(binding, strupper(kind), id, name, icon)

    --elseif kind == "macro" and id == 0 then
      --local action = root.__cursor
      --ClearCursor()
      --root:dispatch("PICKUP_OVERRIDE_ENTRY", button)
      --root:dispatch("SET_OVERRIDE_ENTRY", true, binding, action[KIND], action[ID], action[NAME], action[ICON])

    elseif kind == "macro" then
      ClearCursor()
      scope:dispatch("ADDON_PICKUP_OVERRIDE_BINDING", button)
      local name, icon = GetMacroInfo(id)
      assert(type(id) == "number")
      assert(id ~= nil)
      assert(name ~= nil)
      assert(icon ~= nil)
      scope.dbSaveAction(binding, strupper(kind), id, name, icon)

    elseif kind == "item" then
      ClearCursor()
      local name = select(3, string.match(link, "^|c%x+|H(%a+):(%d+).+|h%[([^%]]+)"))
      local icon = select(10, GetItemInfo(id))
      assert(link ~= nil)
      assert(name ~= nil)
      assert(icon ~= nil)
      scope:dispatch("ADDON_PICKUP_OVERRIDE_BINDING", button)
      scope.dbSaveAction(binding, strupper(kind), id, name, icon)

    elseif kind then
      assert(false, "Unhandled receive: "..kind)
    end
  end
  return next(button)
end
