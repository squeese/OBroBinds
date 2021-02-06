local scope = select(2, ...)
scope.CreateRootFrame()

scope.enqueue("PLAYER_LOGIN", setmetatable({
  --scope.STACK.fold, nil,
  --scope.STACK.call, scope.UpdatePlayerBindings,
  --scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED", scope.UpdatePlayerBindings,
  scope.STACK.init, function(next, ...)
    if scope.dbRead("GUI", "open") then
      scope:dispatch("ADDON_ROOT_SHOW")
    end
    return next(...)
  end,
}, scope.STACK))

--scope.enqueue("ADDON_ROOT_SHOW", setmetatable({
  --scope.STACK.fold, "ADDON_ROOT_HIDE",
  --scope.STACK.init, scope.CreatePanelFrame,
  --scope.STACK.init, function(e, ...)
    --scope:dispatch("ADDON_KEYBOARD_SHOW")
    ----scope:dispatch("ADDON_EDITOR_SHOW")
    ----scope:dispatch("ADDON_EDITOR_SELECT", "SHIFT-3")
    --return e(...)
  --end,
  --scope.STACK.call, scope.STACK.apply(scope.root, scope.root.Show),
  --scope.STACK.undo, scope.STACK.apply(scope.root, scope.root.Hide),
--}, scope.STACK))


--scope.enqueue("ADDON_KEYBOARD_SHOW", setmetatable({
  --scope.STACK.fold, "ADDON_KEYBOARD_HIDE",
  --scope.STACK.call, scope.STACK.apply(scope, scope.dispatch, "ADDON_EDITOR_HIDE"),
  --scope.STACK.call, scope.STACK.apply(scope, scope.read, "keyboard", scope.root.Show),
  --scope.STACK.undo, scope.STACK.apply(scope, scope.read, "keyboard", scope.root.Hide),
  --scope.STACK.init, scope.InitializePageKeyboard,
  --scope.STACK.init, scope.UpdateKeyboardLayout,
  --scope.STACK.call, scope.UpdateKeyboardStanceButtons,
  --scope.STACK.call, scope.UpdateKeyboardMainbarIndices,
  --scope.STACK.call, scope.UpdateAllKeyboardButtons,
  --scope.STACK.enqueue, "ADDON_UPDATE_LAYOUT",            scope.UpdateKeyboardLayout,
  --scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateKeyboardStanceButtons,
  --scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.UpdateKeyboardStanceButtons,
  --scope.STACK.enqueue, "UPDATE_BINDINGS",                scope.UpdateKeyboardMainbarIndices,
  --scope.STACK.enqueue, "ACTIONBAR_SLOT_CHANGED",         scope.UpdateKeyboardMainbarSlots,
  --scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.UpdateKeyboardMainbarOffsets,
  --scope.STACK.enqueue, "ADDON_MODIFIER_CHANGED",         scope.UpdateAllKeyboardButtons,
  --scope.STACK.enqueue, "ADDON_PLAYER_TALENT_UPDATE",     scope.UpdateAllKeyboardButtons,
  --scope.STACK.enqueue, "ADDON_UPDATE_MACROS",            scope.UpdateAllKeyboardButtons,
  --scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateAllKeyboardButtons,
  --scope.STACK.enqueue, "ADDON_SHOW_TOOLTIP",             scope.UpdateTooltip,
  --scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.RefreshTooltip,
  --scope.STACK.enqueue, "ADDON_MODIFIER_CHANGED",         scope.RefreshTooltip,
  --scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.RefreshTooltip,
  --scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.RefreshTooltip,
  --scope.STACK.enqueue, "UPDATE_BINDINGS",                scope.RefreshTooltip,
  --scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.UpdateUnknownSpells,
  --scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateUnknownSpells,
  --scope.STACK.enqueue, "ADDON_SHOW_DROPDOWN",            scope.UpdateDropdown,
  --scope.STACK.enqueue, "ADDON_BINDING_UPDATED", function(e, binding, ...)
    --local modifier, key = string.match(binding, "^(.--?)([^-]*.)$")
    --if scope.modifier == modifier then
      --scope.buttons[key]:UpdateButton()
    --end
    --return e(binding, ...)
  --end,
--}, scope.STACK))

--scope.enqueue("ADDON_EDITOR_SHOW", setmetatable({
  --scope.STACK.fold, "ADDON_EDITOR_HIDE",
  --scope.STACK.call, scope.STACK.apply(scope, scope.dispatch, "ADDON_KEYBOARD_HIDE"),
  --scope.STACK.call, scope.STACK.apply(scope, scope.read, "editor", scope.root.Show),
  --scope.STACK.undo, scope.STACK.apply(scope, scope.read, "editor", scope.root.Hide),
  --scope.STACK.undo, scope.EditorCleanup,
  --scope.STACK.init, scope.InitializeEditor,
  --scope.STACK.call, function(e, ...)
    --scope.editor.__height = scope.root:GetHeight()
    --scope.root:SetHeight(500)
    --return e(...)
  --end,
  --scope.STACK.undo, function(e, ...)
    --scope.root:SetHeight(scope.editor.__height)
    --scope.editor.__height = nil
    --return e(...)
  --end,
  --scope.STACK.enqueue, "ADDON_EDITOR_SELECT",        scope.EditorSelect,
  --scope.STACK.enqueue, "ADDON_EDITOR_BODY_CHANGED",  scope.EditorUpdateButtons,
  --scope.STACK.enqueue, "ADDON_EDITOR_NAME_CHANGED",  scope.EditorUpdateButtons,
  --scope.STACK.enqueue, "ADDON_EDITOR_CHANGE_SCRIPT", scope.EditorUpdateButtons,
  --scope.STACK.enqueue, "ADDON_EDITOR_ICONS",         scope.EditorToggleIcons,
  --scope.STACK.enqueue, "ADDON_EDITOR_CHANGE_ICON",   scope.EditorChangeIcon,
  --scope.STACK.enqueue, "ADDON_EDITOR_SAVE",          scope.EditorSave,
  --scope.STACK.enqueue, "ADDON_EDITOR_UNDO",          scope.EditorUndo,
--}, scope.STACK))
