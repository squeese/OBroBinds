local scope = select(2, ...)

OBroBindsLineMixin = {}

local function OnClickIcon(self)
  scope:dispatch("ADDON_EDITOR_CHANGE_ICON", self:GetParent().listIndex, self.index)
end

function OBroBindsLineMixin:InitElement(...)
  self.HighlightTexture:Hide()
  self:SetNormalTexture(nil)
  local prev
  for index, icon in ipairs(self.Icons) do
    icon.index = index
    icon:SetScript("OnClick", OnClickIcon)
    if prev then
      icon:SetPoint("LEFT", prev, "RIGHT", 4, 0)
    else
      icon:SetPoint("LEFT", 4, 0)
    end
    prev = icon
  end
end

function OBroBindsLineMixin:UpdateDisplay()
  local count = #scope.editor.iconFiles
  local base = self.listIndex-1
  for i = 1, 5 do
    local index = base*5+i
    if index > count then
      self.Icons[i]:Hide()
    else
      self.Icons[i]:Show()
      self.Icons[i].icon:SetTexture(scope.editor.iconFiles[index])
    end
  end
end

OBroBindsListMixin = {}

function OBroBindsListMixin:OnLoad()
  self.ArtOverlay.SelectedHighlight:SetAlpha(0)
  self.InsetFrame:Hide()
  self.ScrollFrame.scrollBar.Background:Hide()
  self.ScrollFrame.scrollBar.ScrollBarTop:Hide()
  self.ScrollFrame.scrollBar.ScrollBarMiddle:Hide()
  self.ScrollFrame.scrollBar.ScrollBarBottom:Hide()
  self:SetPoint("TOPLEFT", 18, -68)
  self:SetPoint("BOTTOMRIGHT", self:GetParent(), "BOTTOMLEFT", 256, 52)
  self:SetElementTemplate("OBroBindsLineTemplate")
  self:SetGetNumResultsFunction(function(...)
    return math.ceil(#scope.editor.iconFiles / 5)
  end)
end

function scope.InitializeEditor(e, ...)
  scope.editor.iconFiles = nil
  scope.editor.iconScroll = nil

  scope.editor.scroll = CreateFrame("ScrollFrame", nil, scope.editor, "OBroBindsEditorTemplate")
  scope.editor.scroll:SetPoint("TOPLEFT", 18, -68)
  --scope.editor.scroll:SetPoint("TOPLEFT", scope.editor:GetWidth()/2, -68)

  scope.editor.body = scope.editor.scroll.edit
  scope.editor.body:SetPoint("TOPLEFT", 0, 0)
  scope.editor.body:SetSize(scope.editor.scroll:GetWidth(), scope.editor.scroll:GetHeight())
  scope.editor.body:SetScript("OnTextChanged", function(self)
    ScrollingEdit_OnTextChanged(self, self:GetParent())
    scope:dispatch("ADDON_EDITOR_BODY_CHANGED")
  end)

  local button = CreateFrame("button", nil, scope.editor)
  button:SetAllPoints(scope.editor.scroll)
  button:SetScript("OnClick", function()
    scope.editor.body:SetFocus()
  end)

  local top = scope.editor:CreateTexture(nil, "BACKGROUND")
  top:SetPoint("TOPLEFT", 8, -22)
  top:SetPoint("BOTTOMRIGHT", scope.editor, "TOPRIGHT", -8, -62)
  top:SetColorTexture(0, 0, 0, 0.5)

  scope.editor.icon = CreateFrame("checkbutton", nil, scope.editor, "ActionButtonTemplate")
  scope.editor.icon.icon:SetTexture(136202)
  scope.editor.icon:SetSize(40, 40)
  scope.editor.icon:SetScript("OnClick", function(self)
    scope:dispatch("ADDON_EDITOR_ICONS", self:GetChecked())
  end)

  scope.editor.name = CreateFrame("editbox", nil, scope.editor, "InputBoxTemplate")
  scope.editor.name:SetHeight(24)
  scope.editor.name:SetAutoFocus(false)
  scope.editor.name:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  scope.editor.name:SetScript("OnTextChanged", function(self)
    scope:dispatch("ADDON_EDITOR_NAME_CHANGED")
  end)
  local line = scope.editor.name:CreateTexture(nil, "BACKGROUND")
  line:SetPoint("BOTTOMLEFT", 0, 0)
  line:SetPoint("TOPRIGHT", scope.editor.name, "BOTTOMRIGHT", 0, 1)
  line:SetColorTexture(1, 1, 1, 0.25)
  scope.editor.name.Left:Hide()
  scope.editor.name.Right:Hide()
  scope.editor.name.Middle:Hide()

  scope.editor.save = CreateFrame("button", nil, scope.editor, "UIPanelButtonTemplate")
  scope.editor.save:SetText("Save")
  scope.editor.save:SetSize(80, 24)
  scope.editor.save:SetEnabled(false)
  scope.editor.save:SetScript("OnClick", function()
    scope:dispatch("ADDON_EDITOR_SAVE")
  end)

  scope.editor.undo = CreateFrame("button", nil, scope.editor, "UIPanelButtonTemplate")
  scope.editor.undo:SetText("Cancel")
  scope.editor.undo:SetSize(80, 24)
  scope.editor.undo:SetEnabled(false)
  scope.editor.undo:SetScript("OnClick", function()
    scope:dispatch("ADDON_EDITOR_UNDO")
  end)

  scope.editor.icon:SetPoint("TOPLEFT", 16, -14)
  scope.editor.name:SetPoint("TOPLEFT", 64, -31)
  scope.editor.name:SetPoint("TOPRIGHT", -180, -31)
  scope.editor.undo:SetPoint("TOPRIGHT", scope.editor.save, "TOPLEFT", -4, 0)
  scope.editor.save:SetPoint("TOPRIGHT", -12, -31)

  local bg = scope.editor:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", scope.editor, "BOTTOMLEFT", 8, 48)
  bg:SetPoint("BOTTOMRIGHT", -8, 8)
  bg:SetColorTexture(0, 0, 0, 0.5)

  scope.editor.done = CreateFrame("button", nil, scope.editor, "UIPanelButtonTemplate")
  scope.editor.done:SetText("Close")
  scope.editor.done:SetSize(80, 24)
  scope.editor.done:SetEnabled(true)
  scope.editor.done:SetScript("OnClick", function()
    scope:dispatch("ADDON_KEYBOARD_SHOW")
  end)
  scope.editor.done:SetPoint("BOTTOMRIGHT", -12, 16)

  return e(...)
end

function scope.EditorSelect(e, binding, index, ...)
  if not scope.editor.dirty then
    scope.editor.dirty = false
    scope.editor.action = scope.GetAction(binding)
    scope.editor.binding = binding
    scope.editor.body:SetText(scope.editor.action.text)
    scope.editor.name:SetText(scope.editor.action.id)
    scope.editor.icon.icon:SetTexture(scope.editor.action.icon)
    scope.editor.save:SetEnabled(false)
    scope.editor.undo:SetEnabled(false)
    scope.editor.done:SetEnabled(true)
    return e(binding, index, ...)
  end
end

function scope.EditorUpdateButtons(e, ...)
  if scope.editor.action then
    scope.editor.dirty = (scope.editor.action.text ~= scope.editor.body:GetText()) or (scope.editor.action.id ~= scope.editor.name:GetText())
    scope.editor.save:SetEnabled(scope.editor.dirty)
    scope.editor.undo:SetEnabled(scope.editor.dirty)
    scope.editor.done:SetEnabled(not scope.editor.dirty)
    --scope.SetSelectorListLocked(dirty)
  end
  return e(...)
end

function scope.EditorSave(e, ...)
  scope.editor.dirty = false
  scope.editor.action[scope.ACTION.id] = scope.editor.name:GetText()
  scope.editor.action[scope.ACTION.text] = scope.editor.body:GetText()
  scope.SaveAction(scope.editor.binding, unpack(scope.editor.action, 1, 4))
  scope:dispatch("ADDON_EDITOR_SELECT", scope.editor.binding)
  return e(...)
end

function scope.EditorUndo(e, ...)
  scope.editor.dirty = false
  scope:dispatch("ADDON_KEYBOARD_HIDE")
  scope:dispatch("ADDON_EDITOR_SELECT", scope.editor.binding)
  return e(...)
end

function scope.EditorCleanup(e, ...)
  scope.editor.dirty = false
  scope.editor.action = nil
  scope.editor.binding = nil
  scope.editor.body:SetText("")
  scope.editor.name:SetText("")
  return e(...)
end

function scope.EditorToggleIcons(e, open, ...)
  if not scope.editor.iconScroll then
    scope.editor.iconFiles = {134400}
    GetMacroIcons(scope.editor.iconFiles)
    scope.editor.iconScroll = CreateFrame("frame", nil, scope.editor, "OBroBindsListTemplate")
  end
  if open then
    scope.editor.iconScroll:Show()
    scope.editor.scroll:SetPoint("TOPLEFT", scope.editor.iconScroll, "TOPRIGHT", 8, 0)
  else
    scope.editor.iconScroll:Hide()
    scope.editor.scroll:SetPoint("TOPLEFT", scope.editor, "TOPLEFT", 18, -68)
  end
  return e(open, ...)
end

function scope.EditorChangeIcon(e, row, col, ...)
  local icon = scope.editor.iconFiles[(row-1)*5+col]
  if icon == 134400 then
    local macro = CreateMacro("__TMP", "INV_MISC_QUESTIONMARK", scope.editor.body:GetText())
    _, icon = GetMacroInfo(macro)
    DeleteMacro(macro)
  end
  scope.editor.icon.icon:SetTexture(icon)
  scope.dbWrite(scope.class, scope.spec, scope.editor.binding, scope.ACTION.icon, icon)
  scope:dispatch("ADDON_BINDING_UPDATED", scope.editor.binding)
  return e(row, col, ...)
end

--/script DEFAULT_CHAT_FRAME:AddMessage("\124cffffd000\124Hspell:214621\124h[Schism]\124h\124r");
--  |cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r

hooksecurefunc("ChatEdit_InsertLink", function(text)
  if not text then return end
  if not scope.editor.body then return end
  if not scope.editor:IsVisible() then return end
  if ChatEdit_GetActiveWindow() then return end
  if BrowseName and BrowseName:IsVisible() then return end
  if MacroFrameText and MacroFrameText:IsVisible() then return end
  local info, name = string.match(text, "^|c%x+|H([^|]+)|h%[([^%]]+)%].*$")
  local kind, id = strsplit(":", info)
  --local kind, id, name = string.match(text, "^|c%x+|H(%a+):(%d+)[|:]");
  --print(text, kind, id, type(id))
  --print("test", test)
  --print("name", name)
  --print("split", )

  if kind == "item" then
    text = GetItemInfo(text)
  elseif kind == "spell" and id then
    text = GetSpellInfo(id)
  elseif kind == "talent" and name then
    text = GetSpellInfo(name) or name
  end
  if scope.editor.body:GetText() == "" then
    if kind == "item" then
      if GetItemSpell(text) then
        return scope.editor.body:Insert(SLASH_USE1.." "..text);
      end
      return scope.editor.body:Insert(SLASH_EQUIP1.." "..text);
    elseif kind == "spell" or kind == "talent" then
      return scope.editor.body:Insert(SLASH_CAST1.." "..text);
    end
  end
  scope.editor.body:Insert(text)
end)
