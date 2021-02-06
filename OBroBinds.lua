local scope = select(2, ...)

function scope.CreateRootFrame()
  scope.CreateRootFrame = nil
  local root = CreateFrame("frame", "OBroBindsRoot", UIParent, nil)
  root:Hide()
  root:SetMovable(true)
  root:SetSize(400, 200)
  root:SetPoint("CENTER")
  root:SetScript("OnEvent", scope.dispatch)
  function _G.OBroBinds_Toggle()
    local visible = root:IsVisible()
    scope.dbWrite("GUI", "open", not visible and true or nil)
    scope:dispatch(visible and 'ADDON_ROOT_HIDE' or 'ADDON_ROOT_SHOW')
  end
  return root
end

function scope.CreatePanelFrame()
  scope.CreatePanelFrame = nil
  local panel = CreateFrame("frame", nil, scope.ROOT, "UIPanelDialogTemplate")
  panel.Title:SetText("OBroBinds")
  panel:EnableMouse(true)
  panel:SetAllPoints()
  panel:RegisterForDrag("LeftButton")
  panel:GetChildren():SetScript("OnClick", _G.OBroBinds_Toggle)
  panel:SetScript("OnDragStart", function()
    scope.ROOT:StartMoving()
  end)
  panel:SetScript("OnDragStop", function()
    scope.ROOT:StopMovingOrSizing()
  end)
  return panel
end

function scope.CreateKeyboardFrame()
  scope.CreateKeyboardFrame = nil
  local keyboard = CreateFrame("frame", nil, scope.PANEL, nil)
  keyboard:SetAllPoints()
  keyboard:Hide()
  local bg = keyboard:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(1, 0.5, 0.25, 0.5)
  return keyboard
end

function scope.CreateEditorFrame()
  scope.CreateEditorFrame = nil
  local editor = CreateFrame("frame", nil, scope.PANEL, nil)
  editor:SetAllPoints()
  editor:Hide()
  return editor
end

scope.ROOT = scope.CreateRootFrame()

function scope.UpdatePlayerBindings(next, ...)
  print("UpdatePlayerBindings")
  return next(...)
end

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
  scope.STACK.once, function(next, ...)
    scope.PANEL = scope.CreatePanelFrame()
    scope.KEYBOARD = scope.CreateKeyboardFrame()
    scope.EDITOR = scope.CreateEditorFrame()
    scope:dispatch("ADDON_KEYBOARD_SHOW")
    scope:dispatch("ADDON_EDITOR_SHOW")
    scope:dispatch("ADDON_EDITOR_SELECT", "SHIFT-3")
    return next(...)
  end
))

scope.enqueue("ADDON_KEYBOARD_SHOW", scope.poolAcquire(scope.STACK,
  scope.STACK.fold, "ADDON_KEYBOARD_HIDE",
  scope.STACK.setup, scope.STACK.apply(scope, scope.dispatch, "ADDON_EDITOR_HIDE"),
  scope.STACK.setup, scope.STACK.apply(scope, scope.read, "KEYBOARD", scope.ROOT.Show),
  scope.STACK.clear, scope.STACK.apply(scope, scope.read, "KEYBOARD", scope.ROOT.Hide),
  scope.STACK.once, function(next, ...)
    scope.MODIFIER = nil -- current pressed modifier
    scope.STANCES = nil  -- stance buttons
    scope.BUTTONS = nil  -- keyboard buttons for binding spells
    scope.MAINBAR = nil  -- keyboard buttons for moving buttons on main actionbar
    scope.OFFSET = 1     -- stance offset to the proper ACTIONBUTTON position
    scope.InitializeKeyboardStanceButtons()
    scope.InitializeKeyboardModifierListener()
    return next(...)
  end
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
  --scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.UpdateAllKeyboardButtons,
  --scope.STACK.enqueue, "UPDATE_MACROS",            scope.UpdateAllKeyboardButtons,
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
  --end
))

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
