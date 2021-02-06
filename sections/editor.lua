local scope = select(2, ...)

--[[
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
]]


function scope.EditorSelect(e, binding, index, ...)
  if not scope.editor.dirty then
    scope.editor.dirty = false
    scope.editor.action = scope.GetAction(binding)
    scope.editor.binding = binding
    scope.editor.body:SetText(scope.editor.action.text)
    scope.editor.name:SetText(scope.editor.action.id)
    scope.editor.icon.icon:SetTexture(scope.editor.action.icon)
    scope.editor.script:SetChecked(scope.editor.action.script)
    scope.editor.save:SetEnabled(false)
    scope.editor.undo:SetEnabled(false)
    scope.editor.done:SetEnabled(true)
    return e(binding, index, ...)
  end
end

--[[
function scope.EditorUpdateButtons(e, ...)
  if scope.editor.action then
    scope.editor.dirty
      = (scope.editor.action.text ~= scope.editor.body:GetText())
      or (scope.editor.action.id ~= scope.editor.name:GetText())
      or (scope.editor.action.script ~= (scope.editor.script:GetChecked() and true or nil))
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
  scope.editor.action[scope.ACTION.script] = scope.editor.script:GetChecked() and true or nil
  scope.SaveAction(scope.editor.binding, unpack(scope.editor.action, 1, 6))
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
]]

hooksecurefunc("ChatEdit_InsertLink", function(text)
  if not text then return end
  if not scope.editor.body then return end
  if not scope.editor:IsVisible() then return end
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
