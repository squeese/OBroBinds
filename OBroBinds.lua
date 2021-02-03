local scope = select(2, ...)
scope.CreateRootFrame()

scope.enqueue("PLAYER_LOGIN", setmetatable({
  scope.STACK.fold, nil,
  scope.STACK.call, scope.UpdatePlayerBindings,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED", scope.UpdatePlayerBindings,
  scope.STACK.init, function(e, ...)
    scope.root[scope.dbRead('GUI', 'open') and 'Show' or 'Hide'](scope.root)
    return e(...)
  end,
}, scope.STACK))

scope.enqueue("ADDON_ROOT_SHOW", setmetatable({
  scope.STACK.fold, "ADDON_ROOT_HIDE",
  scope.STACK.init, scope.CreateRootPanel,
  scope.STACK.both, function(e, ...)
    if e.key == "ADDON_ROOT_SHOW" then
      scope.dbWrite('GUI', 'open', true)
    else
      scope.dbWrite('GUI', 'open', nil)
    end
    return e(...)
  end,
}, scope.STACK))


scope.enqueue("ADDON_KEYBOARD_SHOW", setmetatable({
  scope.STACK.fold, "ADDON_KEYBOARD_HIDE",
  scope.STACK.init, scope.InitializePageKeyboard,
  scope.STACK.init, scope.UpdateKeyboardLayout,
  scope.STACK.call, scope.UpdateKeyboardStanceButtons,
  scope.STACK.call, scope.UpdateKeyboardMainbarIndices,
  scope.STACK.call, scope.UpdateAllKeyboardButtons,
  scope.STACK.enqueue, "ADDON_UPDATE_LAYOUT",            scope.UpdateKeyboardLayout,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateKeyboardStanceButtons,
  scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.UpdateKeyboardStanceButtons,
  scope.STACK.enqueue, "UPDATE_BINDINGS",                scope.UpdateKeyboardMainbarIndices,
  scope.STACK.enqueue, "ACTIONBAR_SLOT_CHANGED",         scope.UpdateKeyboardMainbarSlots,
  scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.UpdateKeyboardMainbarOffsets,
  scope.STACK.enqueue, "ADDON_MODIFIER_CHANGED",         scope.UpdateAllKeyboardButtons,
  scope.STACK.enqueue, "ADDON_PLAYER_TALENT_UPDATE",     scope.UpdateAllKeyboardButtons,
  scope.STACK.enqueue, "ADDON_UPDATE_MACROS",            scope.UpdateAllKeyboardButtons,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateAllKeyboardButtons,
  scope.STACK.enqueue, "ADDON_PICKUP_OVERRIDE_BINDING",  scope.PickupOverrideBinding,
  scope.STACK.enqueue, "ADDON_RECEIVE_OVERRIDE_BINDING", scope.ReceiveOverrideBinding,
  scope.STACK.enqueue, "ADDON_SHOW_TOOLTIP",             scope.UpdateTooltip,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.RefreshTooltip,
  scope.STACK.enqueue, "ADDON_MODIFIER_CHANGED",         scope.RefreshTooltip,
  scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.RefreshTooltip,
  scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.RefreshTooltip,
  scope.STACK.enqueue, "UPDATE_BINDINGS",                scope.RefreshTooltip,
  scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.UpdateUnknownSpells,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateUnknownSpells,
  scope.STACK.enqueue, "ADDON_SHOW_DROPDOWN",            scope.UpdateDropdown,
}, scope.STACK))

scope.enqueue("ADDON_SELECTOR_SHOW", setmetatable({
  scope.STACK.fold, "ADDON_SELECTOR_HIDE",
  scope.STACK.init, scope.InitializeSelector,
  scope.STACK.call, function(e, ...)
    print(e.key)
    return e(...)
  end,
}, scope.STACK))

--[[
scope.enqueue("ADDON_PAGE_SETTINGS_SHOW", setmetatable({
  scope.STACK.fold, "ADDON_PAGE_SETTINGS_HIDE",
  scope.STACK.init, scope.createEditbox,
  scope.STACK.call, function(e, ...)
    print("hello?")
    --scope.dbWrite("GUI", "page", scope.tabSettings:GetID())
    return e(...)
  end,
}, scope.STACK))

scope.enqueue("ADDON_EDIT_BLOB", setmetatable({
  scope.STACK.fold, "ADDON_EDIT_DONE",
  scope.STACK.call, function(e, binding, ...)
    print("before pageKeyboard:Hide()")
    scope.pageKeyboard:Hide()
    print("after pageKeyboard:Hide()")

    print("before pageSettings:Show()")
    scope.pageSettings:Show()
    print("after pageSettings:Hide()")
    --local action = scope.dbGetAction(binding)
    --scope.editBox:SetText(action.name)
    --scope.editBox:SetScript("OnEditFocusLost", function(self)
      --print("??", binding, self:GetText())
      --scope.dbWrite(scope.class, scope.spec, binding, scope.ACTION.name, self:GetText())
    --end)
    --scope.editBox:SetFocus()
    return e(...)
  end,
  scope.STACK.call, function(e, ...)
    print("hello!")
    return e(...)
  end,
}, scope.STACK))
]]
