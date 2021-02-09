local scope = select(2, ...)
scope.ROOT = scope.CreateRootFrame()

scope.enqueue("PLAYER_LOGIN", scope.poolAcquire(scope.STACK,
  scope.STACK.fold, nil,
  scope.STACK.once, scope.UpdatePlayerVariables,
  scope.STACK.once, scope.UpdatePlayerBindings,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED", scope.UpdatePlayerVariables,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED", scope.UpdatePlayerBindings,
  scope.STACK.once, function(next, ...)
    if scope.dbRead("GUI", "open") then
      scope:dispatch("ADDON_ROOT_SHOW")
    end
    return next(...)
  end
))

scope.enqueue("ADDON_ROOT_SHOW", scope.poolAcquire(scope.STACK,
  scope.STACK.fold, "ADDON_ROOT_HIDE",
  scope.STACK.setup, scope.STACK.apply(scope.ROOT, scope.ROOT.Show),
  scope.STACK.clear, scope.STACK.apply(scope.ROOT, scope.ROOT.Hide),
  scope.STACK.enqueue, "ADDON_ACTION_UPDATED", scope.UpdateActionBinding,
  scope.STACK.once, function(next, ...)
    scope.PANEL = scope.CreatePanelFrame()
    scope.KEYBOARD = scope.CreateKeyboardFrame()
    scope.EDITOR = scope.CreateEditorFrame()
    scope:dispatch("ADDON_KEYBOARD_SHOW")
    --scope:dispatch("ADDON_EDITOR_SHOW")
    --scope:dispatch("ADDON_EDITOR_SELECT", "3")
    return next(...)
  end
))

scope.enqueue("ADDON_KEYBOARD_SHOW", scope.poolAcquire(scope.STACK,
  scope.STACK.fold, "ADDON_KEYBOARD_HIDE",
  scope.STACK.setup, scope.STACK.apply(scope, scope.dispatch, "ADDON_EDITOR_HIDE"),
  scope.STACK.setup, scope.STACK.apply(scope, scope.read, "KEYBOARD", scope.ROOT.Show),
  scope.STACK.clear, scope.STACK.apply(scope, scope.read, "KEYBOARD", scope.ROOT.Hide),
  scope.STACK.once, scope.UpdateUnknownSpells,
  scope.STACK.once, function(next, ...)
    scope.STANCE_OFFSET  = 1   -- stance offset to the proper ACTIONBUTTON position
    scope.STANCE_BUTTONS = nil -- stance buttons
    scope.ACTION_BUTTONS = nil -- keyboard buttons for binding spells
    scope.PORTAL_BUTTONS = nil -- keyboard buttons for moving buttons on main actionbar
    scope.MODIFIER       = nil -- current pressed modifier
    scope.InitializeKeyboardStanceButtons()
    scope.InitializeKeyboardModifierListener()
    return next(scope.DEFAULT_KEYBOARD_LAYOUT, ...)
  end,
  scope.STACK.once,    scope.UpdateKeyboardLayout,
  scope.STACK.setup,   scope.UpdateKeyboardStanceButtons,
  scope.STACK.setup,   scope.UpdateKeyboardMainbarIndices,
  scope.STACK.setup,   scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "ADDON_UPDATE_LAYOUT",            scope.UpdateKeyboardLayout,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateKeyboardStanceButtons,
  scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.UpdateKeyboardStanceButtons,
  scope.STACK.enqueue, "UPDATE_BINDINGS",                scope.UpdateKeyboardMainbarIndices,
  scope.STACK.enqueue, "ACTIONBAR_SLOT_CHANGED",         scope.UpdateKeyboardMainbarSlots,
  scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.UpdateKeyboardMainbarOffsets,
  scope.STACK.enqueue, "ADDON_MODIFIER_CHANGED",         scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "UPDATE_MACROS",                  scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "ADDON_SHOW_TOOLTIP",             scope.UpdateTooltip,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.RefreshTooltip,
  scope.STACK.enqueue, "ADDON_MODIFIER_CHANGED",         scope.RefreshTooltip,
  scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.RefreshTooltip,
  scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.RefreshTooltip,
  scope.STACK.enqueue, "UPDATE_BINDINGS",                scope.RefreshTooltip,
  scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.UpdateUnknownSpells,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateUnknownSpells,
  scope.STACK.enqueue, "ADDON_SHOW_DROPDOWN",            scope.UpdateDropdown,
  scope.STACK.enqueue, "ADDON_ACTION_UPDATED",           scope.UpdateChangedActionButtons
))

scope.enqueue("ADDON_EDITOR_SHOW", scope.poolAcquire(scope.STACK,
  scope.STACK.fold, "ADDON_EDITOR_HIDE",
  scope.STACK.setup, scope.STACK.apply(scope, scope.dispatch, "ADDON_KEYBOARD_HIDE"),
  scope.STACK.setup, scope.STACK.apply(scope, scope.read, "EDITOR", scope.ROOT.Show),
  scope.STACK.clear, scope.STACK.apply(scope, scope.read, "EDITOR", scope.ROOT.Hide),
  scope.STACK.once, function(next, ...)
    scope.EDITOR.DIRTY = nil          -- state of the editor, if there are unsaved changes
    scope.EDITOR.ACTION = nil         -- current action being edited
    scope.EDITOR.BINDING = nil        -- binding the the action
    scope.EDITOR.iconScroller = nil   -- scrollframe (IconListTemplate) for changing icons
    scope.EDITOR.iconFiles = nil      -- huge table of macro icons
    scope.EDITOR.iconButton,          -- toggle the icon selection gui
    scope.EDITOR.nameInput,           -- name of the macro
    scope.EDITOR.scriptToggle,        -- toggle on/off script behavious for macro's
    scope.EDITOR.saveButton,
    scope.EDITOR.cancelButton,
    scope.EDITOR.closeButton,
    scope.EDITOR.bodyScroller,
    scope.EDITOR.bodyInput = scope.CreateEditorComponentFrames()
    return next(...)
  end,
  scope.STACK.enqueue, "ADDON_EDITOR_SELECT",        scope.EditorSelect,
  scope.STACK.enqueue, "ADDON_EDITOR_BODY_CHANGED",  scope.EditorUpdateButtons,
  scope.STACK.enqueue, "ADDON_EDITOR_NAME_CHANGED",  scope.EditorUpdateButtons,
  scope.STACK.enqueue, "ADDON_EDITOR_CHANGE_SCRIPT", scope.EditorUpdateButtons,
  scope.STACK.enqueue, "ADDON_EDITOR_ICONS",         scope.EditorToggleIcons,
  scope.STACK.enqueue, "ADDON_EDITOR_CHANGE_ICON",   scope.EditorChangeIcon,
  scope.STACK.enqueue, "ADDON_EDITOR_SAVE",          scope.EditorSave,
  scope.STACK.enqueue, "ADDON_EDITOR_UNDO",          scope.EditorUndo,
  scope.STACK.clear, scope.EditorCleanup,
  scope.STACK.setup, function(next, ...)
    scope.EDITOR.__height = scope.ROOT:GetHeight()
    scope.ROOT:SetHeight(500)
    return next(...)
  end,
  scope.STACK.clear, function(next, ...)
    scope.ROOT:SetHeight(scope.EDITOR.__height)
    scope.EDITOR.__height = nil
    return next(...)
  end
))
