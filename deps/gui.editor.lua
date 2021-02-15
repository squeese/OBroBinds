local scope = select(2, ...)
local EDITOR
OBroBindsLineMixin = {}
OBroBindsListMixin = {}

function scope.EditorSelect(next, event, binding, ...)
  EDITOR = scope.EDITOR
  if not EDITOR.DIRTY then
    EDITOR.ACTION = scope.GetAction(binding)
    if EDITOR.ACTION == scope.NIL then
      scope:dispatch("ADDON_KEYBOARD_SHOW")
      return next, event, binding, ...
    end
    EDITOR.BINDING = binding
    EDITOR.iconButton.icon:SetTexture(EDITOR.ACTION.icon)
    EDITOR.bodyInput:SetText(EDITOR.ACTION.body)
    EDITOR.nameInput:SetText(EDITOR.ACTION.id)
    EDITOR.scriptToggle:SetChecked(EDITOR.ACTION.script)
    EDITOR.saveButton:SetEnabled(false)
    EDITOR.cancelButton:SetEnabled(false)
    EDITOR.closeButton:SetEnabled(true)
    return next(event, binding, ...)
  end
  return next, event, binding, ...
end

function scope.EditorUpdateButtons(next, ...)
  if EDITOR.ACTION then
    EDITOR.DIRTY = (EDITOR.ACTION.body   ~= EDITOR.bodyInput:GetText())
                or (EDITOR.ACTION.id     ~= EDITOR.nameInput:GetText())
                or (EDITOR.ACTION.script ~= (EDITOR.scriptToggle:GetChecked() and true or nil))
    EDITOR.saveButton:SetEnabled(EDITOR.DIRTY)
    EDITOR.cancelButton:SetEnabled(EDITOR.DIRTY)
    EDITOR.closeButton:SetEnabled(not EDITOR.DIRTY)
  end
  return next(...)
end

function scope.EditorUndo(next, ...)
  EDITOR.DIRTY = false
  scope:dispatch("ADDON_KEYBOARD_HIDE")
  scope:dispatch("ADDON_EDITOR_SELECT", EDITOR.BINDING)
  return next(...)
end

function scope.EditorCleanup(next, ...)
  EDITOR.DIRTY = false
  EDITOR.ACTION = nil
  EDITOR.BINDING = nil
  EDITOR.nameInput:SetText("")
  EDITOR.bodyInput:SetText("")
  return next(...)
end

function scope.EditorSave(next, ...)
  local binding = EDITOR.BINDING
  if scope.match(true,
      scope.dbWriteAction(binding, scope.ACTION.id, EDITOR.nameInput:GetText()),
      scope.dbWriteAction(binding, scope.ACTION.body, EDITOR.bodyInput:GetText()),
      scope.dbWriteAction(binding, scope.ACTION.script, EDITOR.scriptToggle:GetChecked() and true or nil)) then
    scope:dispatch("ADDON_ACTION_UPDATED", binding, scope.bindingModifiers(binding))
  end
  EDITOR.DIRTY = false
  scope:dispatch("ADDON_EDITOR_SELECT", EDITOR.BINDING)
  return next(...)
end

function scope.EditorToggleIcons(next, event, open, ...)
  if not EDITOR.iconScroller then
    EDITOR.iconFiles = {134400}
    GetMacroIcons(EDITOR.iconFiles)
    EDITOR.iconScroller = CreateFrame("frame", nil, EDITOR, "OBroBindsListTemplate")
  end
  if open then
    EDITOR.iconScroller:Show()
    EDITOR.bodyScroller:SetPoint("TOPLEFT", EDITOR.iconScroller, "TOPRIGHT", 8, 0)
  else
    EDITOR.iconScroller:Hide()
    EDITOR.bodyScroller:SetPoint("TOPLEFT", EDITOR, "TOPLEFT", 18, -68)
  end
  return next(event, open, ...)
end

function scope.EditorChangeIcon(next, event, row, col, ...)
  local icon = EDITOR.iconFiles[(row-1)*5+col]
  if icon == 134400 then
    local macro = CreateMacro("__TMP", "INV_MISC_QUESTIONMARK", EDITOR.bodyInput:GetText())
    _, icon = GetMacroInfo(macro)
    DeleteMacro(macro)
  end
  EDITOR.iconButton.icon:SetTexture(icon)
  if scope.dbWriteAction(EDITOR.BINDING, scope.ACTION.icon, icon) then
    scope:dispatch("ADDON_ACTION_UPDATED", EDITOR.BINDING, scope.bindingModifiers(EDITOR.BINDING))
  end
  return next(event, row, col, ...)
end

hooksecurefunc("ChatEdit_InsertLink", function(text)
  if not text then return end
  if not scope.EDITOR:IsVisible() then return end
  if not scope.EDITOR.nameInput then return end
  if ChatEdit_GetActiveWindow() then return end
  if BrowseName and BrowseName:IsVisible() then return end
  if MacroFrameText and MacroFrameText:IsVisible() then return end
  local info, name = string.match(text, "^|c%x+|H([^|]+)|h%[([^%]]+)%].*$")
  local kind, id = strsplit(":", info)
  if kind == "item" then
    text = GetItemInfo(text)
  elseif kind == "spell" and id then
    text = GetSpellInfo(id)
  elseif kind == "talent" and name then
    text = GetSpellInfo(name) or name
  elseif kind == "pvptal" and name then
    text = name
  end
  if scope.EDITOR.bodyInput:GetText() == "" then
    if kind == "item" then
      if GetItemSpell(text) then
        return scope.EDITOR.bodyInput:Insert(SLASH_USE1.." "..text);
      end
      return scope.EDITOR.bodyInput:Insert(SLASH_EQUIP1.." "..text);
    elseif kind == "spell" or kind == "talent" or kind == "pvptal" then
      return scope.EDITOR.bodyInput:Insert(SLASH_CAST1.." "..text);
    end
  end
  scope.EDITOR.bodyInput:Insert(text)
end)

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
  local count = #scope.EDITOR.iconFiles
  local base = self.listIndex-1
  for i = 1, 5 do
    local index = base*5+i
    if index > count then
      self.Icons[i]:Hide()
    else
      self.Icons[i]:Show()
      self.Icons[i].icon:SetTexture(scope.EDITOR.iconFiles[index])
    end
  end
end

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
    return math.ceil(#scope.EDITOR.iconFiles / 5)
  end)
end
