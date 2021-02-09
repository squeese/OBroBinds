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
  scope.CreateEditorComponentFrames = nil
  local gutterTop = scope.EDITOR:CreateTexture(nil, "BACKGROUND")
  gutterTop:SetPoint("TOPLEFT", 8, -22)
  gutterTop:SetPoint("BOTTOMRIGHT", scope.EDITOR, "TOPRIGHT", -8, -62)
  gutterTop:SetColorTexture(0, 0, 0, 0.5)

  local iconButton = CreateFrame("checkbutton", nil, scope.EDITOR, "ActionButtonTemplate")
  iconButton.icon:SetTexture(136202)
  iconButton:SetPoint("TOPLEFT", gutterTop, "TOPLEFT", 12, 6)
  iconButton:SetSize(40, 40)
  iconButton:SetScript("OnClick", function(self)
    scope:dispatch("ADDON_EDITOR_ICONS", self:GetChecked())
  end)

  local nameInput = CreateFrame("editbox", nil, scope.EDITOR, "InputBoxTemplate")
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
  scriptToggle:SetPoint("LEFT", nameInput, "RIGHT", 8, -4)
  scriptToggle.text:SetText("Script")
  scriptToggle:SetScript("OnClick", function(self)
    scope:dispatch("ADDON_EDITOR_CHANGE_SCRIPT", self:GetChecked())
  end)

  local saveButton = CreateFrame("button", nil, scope.EDITOR, "UIPanelButtonTemplate")
  saveButton:SetPoint("RIGHT", gutterTop, "RIGHT", -2, 0)
  saveButton:SetText("Save")
  saveButton:SetSize(80, 24)
  saveButton:SetEnabled(false)
  saveButton:SetScript("OnClick", function()
    scope:dispatch("ADDON_EDITOR_SAVE")
  end)

  local cancelButton = CreateFrame("button", nil, scope.EDITOR, "UIPanelButtonTemplate")
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
    bodyScroller, bodyInput
end
