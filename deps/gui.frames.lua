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
    scope:dispatch("ADDON_ROOT_MOVED")
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

function scope.CreateSelectorFrame()
  scope.CreateSelectorFrame = nil
  local selector = CreateFrame("frame", nil, scope.ROOT, nil)
  selector:SetPoint("TOPLEFT", scope.PANEL, "TOPRIGHT", -6, 0)
  selector:SetWidth(200)
  selector:Hide()
  selector:Lower()

  local function texture(left, right, ...)
    local texture = selector:CreateTexture(nil, "OVERLAY")
    texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    texture:SetTexCoord(left, right, 0, 1)
    texture:SetSize(64, 64)
    for i = 1, select("#", ...), 5 do
      texture:SetPoint(select(i, ...))
    end
    return texture
  end

  local TOPR = texture(0.625, 0.507953125, "TOPRIGHT")
  local BOTR = texture(0.875, 1, "BOTTOMRIGHT")
  texture(0.25, 0.369140625, "TOPLEFT", selector, "TOPLEFT", 0, 0, "TOPRIGHT", TOPR, "TOPLEFT", 0, 0)
  texture(0.376953125, 0.498046875, "BOTTOMLEFT", selector, "BOTTOMLEFT", 0, 0, "BOTTOMRIGHT", BOTR, "BOTTOMLEFT", 0, 0)
  texture(0.1171875, 0.2421875, "TOPRIGHT", TOPR, "BOTTOMRIGHT", 0, 0, "BOTTOMRIGHT", BOTR, "TOPRIGHT", 0, 0)

  local titleBG = selector:CreateTexture(nil, "BACKGROUND")
  titleBG:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background")
  titleBG:SetPoint("TOPLEFT", 0, -6)
  titleBG:SetPoint("BOTTOMRIGHT", selector, "TOPRIGHT", -6, -24)

  local bodyBG = selector:CreateTexture(nil, "BACKGROUND")
  bodyBG:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1")
  bodyBG:SetTexCoord(0.255, 1, 0.39, 1)
  bodyBG:SetPoint("TOPLEFT", 0, -24)
  bodyBG:SetPoint("BOTTOMRIGHT", -6, 8)

  local title = selector:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 4, -8)
  title:SetPoint("BOTTOMRIGHT", selector, "TOPRIGHT", -8, -24)
  title:SetText("Blobs")

  local toggle = CreateFrame("CheckButton", nil, scope.PANEL, "SpellBookSkillLineTabTemplate")
  toggle:ClearAllPoints()
  toggle:SetPoint("TOPLEFT", scope.PANEL, "TOPRIGHT", -2, -32)
  toggle:Show()
  toggle:SetScript("OnClick", function(self)
    if self:GetChecked() then
      scope:dispatch("ADDON_SELECTOR_SHOW")
    else
      scope:dispatch("ADDON_SELECTOR_HIDE")
    end
  end)
  toggle.tooltip = "Blobs"
  toggle:SetNormalTexture(3615513)
  toggle:SetChecked(false)
  selector.toggle = toggle
  return selector
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
  gutterBot:SetPoint("TOPLEFT", scope.EDITOR, "BOTTOMLEFT", 8, 42)
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

  local deleteButton = CreateFrame("button", nil, scope.EDITOR, "UIPanelButtonTemplate")
  deleteButton:SetPoint("LEFT", gutterBot, "LEFT", 2, 0)
  deleteButton:SetText("x")
  deleteButton:SetSize(24, 24)
  deleteButton:SetEnabled(true)
  deleteButton:SetScript("OnClick", function()
    scope:dispatch("ADDON_EDITOR_DELETE")
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
    deleteButton, bodyScroller, bodyInput
end
