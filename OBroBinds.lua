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
  return keyboard
end

function scope.CreateEditorFrame()
  scope.CreateEditorFrame = nil
  local editor = CreateFrame("frame", nil, scope.PANEL, nil)
  editor:SetAllPoints()
  editor:Hide()
  return editor
end

function scope.CreateEditorComponentFrames()
  local gutterTop = scope.EDITOR:CreateTexture(nil, "BACKGROUND")
  gutterTop:SetPoint("TOPLEFT", 8, -22)
  gutterTop:SetPoint("BOTTOMRIGHT", scope.EDITOR, "TOPRIGHT", -8, -62)
  gutterTop:SetColorTexture(0, 0, 0, 0.5)

  local iconButton = CreateFrame("checkbutton", nil, scope.EDITOR, "ActionButtonTemplate")
  --scope.EDITOR.iconButton = iconButton
  iconButton.icon:SetTexture(136202)
  iconButton:SetPoint("TOPLEFT", gutterTop, "TOPLEFT", 12, 6)
  iconButton:SetSize(40, 40)
  iconButton:SetScript("OnClick", function(self)
    scope:dispatch("ADDON_EDITOR_ICONS", self:GetChecked())
  end)

  local nameInput = CreateFrame("editbox", nil, scope.EDITOR, "InputBoxTemplate")
  --scope.EDITOR.nameInput = nameInput
  nameInput:SetPoint("LEFT", gutterTop, "LEFT", 64, 2)
  nameInput:SetPoint("RIGHT", gutterTop, "RIGHT", -245, 2)
  nameInput:SetHeight(24)
  nameInput:SetAutoFocus(false)
  nameInput.Left:Hide()
  nameInput.Right:Hide()
  nameInput.Middle:Hide()
  nameInput:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  nameInput:SetScript("OnTextChanged", function(self)
    scope:dispatch("ADDON_EDITOR_NAME_CHANGED")
  end)

  local line = nameInput:CreateTexture(nil, "BACKGROUND")
  line:SetPoint("BOTTOMLEFT", 0, 0)
  line:SetPoint("TOPRIGHT", nameInput, "BOTTOMRIGHT", 0, 1)
  line:SetColorTexture(1, 1, 1, 0.4)

  local scriptToggle = CreateFrame("checkbutton", nil, scope.EDITOR, "UICheckButtonTemplate")
  --scope.EDITOR.scriptToggle = scriptToggle
  scriptToggle:SetPoint("LEFT", nameInput, "RIGHT", 8, -4)
  scriptToggle.text:SetText("Script")
  scriptToggle:SetScript("OnClick", function(self)
    scope:dispatch("ADDON_EDITOR_CHANGE_SCRIPT", self:GetChecked())
  end)

  local saveButton = CreateFrame("button", nil, scope.EDITOR, "UIPanelButtonTemplate")
  --scope.EDITOR.saveButton = saveButton
  saveButton:SetPoint("RIGHT", gutterTop, "RIGHT", -2, 0)
  saveButton:SetText("Save")
  saveButton:SetSize(80, 24)
  saveButton:SetEnabled(false)
  saveButton:SetScript("OnClick", function()
    scope:dispatch("ADDON_EDITOR_SAVE")
  end)

  local cancelButton = CreateFrame("button", nil, scope.EDITOR, "UIPanelButtonTemplate")
  --scope.EDITOR.cancelButton = cancelButton
  cancelButton:SetPoint("RIGHT", saveButton, "LEFT", -4, 0)
  cancelButton:SetText("Cancel")
  cancelButton:SetSize(80, 24)
  cancelButton:SetEnabled(false)
  cancelButton:SetScript("OnClick", function()
    scope:dispatch("ADDON_EDITOR_UNDO")
  end)

  local gutterBot = scope.EDITOR:CreateTexture(nil, "BACKGROUND")
  gutterBot:SetPoint("TOPLEFT", scope.EDITOR, "BOTTOMLEFT", 8, 48)
  gutterBot:SetPoint("BOTTOMRIGHT", -8, 8)
  gutterBot:SetColorTexture(0, 0, 0, 0.5)

  local closeButton = CreateFrame("button", nil, scope.EDITOR, "UIPanelButtonTemplate")
  --scope.EDITOR.closeButton = closeButton
  closeButton:SetPoint("RIGHT", gutterBot, "RIGHT", -2, 0)
  closeButton:SetText("Close")
  closeButton:SetSize(80, 24)
  closeButton:SetEnabled(true)
  closeButton:SetScript("OnClick", function()
    scope:dispatch("ADDON_KEYBOARD_SHOW")
  end)

  local bodyScroller = CreateFrame("ScrollFrame", nil, scope.EDITOR, "OBroBindsEditorTemplate")
  scope.EDITOR.bodyScroller = bodyScroller
  bodyScroller:SetPoint("TOPLEFT", 18, -68)

  local bodyInput = bodyScroller.edit
  --scope.EDITOR.bodyInput = bodyInput
  bodyInput:SetPoint("TOPLEFT", 0, 0)
  bodyInput:SetSize(bodyScroller:GetWidth(), scope.EDITOR:GetHeight())
  bodyInput:SetScript("OnTextChanged", function(self)
    ScrollingEdit_OnTextChanged(self, self:GetParent())
    scope:dispatch("ADDON_EDITOR_BODY_CHANGED")
  end)

  local editButton = CreateFrame("button", nil, scope.EDITOR)
  editButton:SetAllPoints(bodyScroller)
  editButton:SetScript("OnClick", function()
    bodyInput:SetFocus()
  end)

  return iconButton, nameInput, scriptToggle,
    saveButton, cancelButton, closeButton,
    cancelButton, bodyScroller, bodyInput
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
    scope.EDITOR.DIRTY = nil
    scope.EDITOR.ACTION = nil
    scope.EDITOR.BINDING = nil
    scope.EDITOR.iconScroller = nil
    scope.EDITOR.iconFiles = nil
    scope.EDITOR.iconButton,
    scope.EDITOR.nameInput,
    scope.EDITOR.scriptToggle,
    scope.EDITOR.saveButton,
    scope.EDITOR.cancelButton,
    scope.EDITOR.closeButton,
    scope.EDITOR.bodyScroller,
    scope.EDITOR.bodyInput = scope.CreateEditorComponentFrames()


    return next(...)
  end

  --scope.STACK.clear, scope.EditorCleanup,
  --scope.STACK.setup, function(e, ...)
    --scope.editor.__height = scope.ROOT:GetHeight()
    --scope.ROOT:SetHeight(500)
    --return e(...)
  --end,
  --scope.STACK.undo, function(e, ...)
    --scope.ROOT:SetHeight(scope.editor.__height)
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
  --scope.STACK.enqueue, "ADDON_EDITOR_UNDO",          scope.EditorUndo
))
