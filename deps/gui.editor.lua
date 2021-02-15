local scope = select(2, ...)
local EDITOR
OBroBindsIconLineMixin = {}
OBroBindsIconListMixin = {}

function scope.EditorSelect(next, event, index, ...)
  EDITOR = scope.EDITOR
  if not EDITOR.DIRTY then
    EDITOR.DIRTY = false
    EDITOR.BLOB = scope.dbRead("BLOBS", index)
    if not EDITOR.BLOB then
      scope:dispatch("ADDON_KEYBOARD_SHOW")
      return next, event, index, ...
    end
    EDITOR.index = index
    EDITOR.iconButton.icon:SetTexture(EDITOR.BLOB.icon)
    EDITOR.bodyInput:SetText(EDITOR.BLOB.body)
    EDITOR.nameInput:SetText(EDITOR.BLOB.name)
    EDITOR.scriptToggle:SetChecked(EDITOR.BLOB.script)
    EDITOR.saveButton:SetEnabled(false)
    EDITOR.cancelButton:SetEnabled(false)
    EDITOR.closeButton:SetEnabled(true)
    return next(event, index, ...)
  end
  return next, event, index, ...
end

function scope.EditorUpdateButtons(next, ...)
  if EDITOR.BLOB then
    local dirty = (EDITOR.BLOB.body   ~= EDITOR.bodyInput:GetText())
               or (EDITOR.BLOB.name   ~= EDITOR.nameInput:GetText())
               or (EDITOR.BLOB.script ~= (EDITOR.scriptToggle:GetChecked() and true or nil))
    EDITOR.saveButton:SetEnabled(dirty)
    EDITOR.cancelButton:SetEnabled(dirty)
    EDITOR.closeButton:SetEnabled(not dirty)
    --if EDITOR.DIRTY ~= dirty then
      --scope:dispatch("ADDON_SELECTOR_LOCK", dirty)
    --end
    EDITOR.DIRTY = dirty
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
  --if EDITOR.DIRTY then
    --scope:dispatch("ADDON_SELECTOR_LOCK", false)
  --end
  EDITOR.DIRTY = false
  EDITOR.ACTION = nil
  EDITOR.BINDING = nil
  EDITOR.nameInput:SetText("")
  EDITOR.bodyInput:SetText("")
  return next(...)
end

function scope.EditorSave(next, ...)
  local binding = EDITOR.BINDING
  --if scope.match(true,
      --scope.dbWriteAction(binding, scope.ACTION.id, EDITOR.nameInput:GetText()),
      --scope.dbWriteAction(binding, scope.ACTION.body, EDITOR.bodyInput:GetText()),
      --scope.dbWriteAction(binding, scope.ACTION.script, EDITOR.scriptToggle:GetChecked() and true or nil)) then
  --end
  scope.dbWrite("BLOBS", EDITOR.index, "name", EDITOR.nameInput:GetText())
  scope.dbWrite("BLOBS", EDITOR.index, "body", EDITOR.bodyInput:GetText())
  scope.dbWrite("BLOBS", EDITOR.index, "script", EDITOR.scriptToggle:GetChecked() and true or nil)
  for binding, action in scope.GetActions() do
    if action.blob and action.id == EDITOR.index then
      scope:dispatch("ADDON_ACTION_UPDATED", binding, scope.bindingModifiers(binding))
    end
  end

  if scope.SELECTOR.list then
    scope.SELECTOR.list:RefreshListDisplay()
  end
  EDITOR.DIRTY = false
  --scope:dispatch("ADDON_SELECTOR_LOCK", false)
  scope:dispatch("ADDON_EDITOR_SELECT", EDITOR.index)
  return next(...)
end

function scope.EditorToggleIcons(next, event, open, ...)
  if not EDITOR.iconScroller then
    EDITOR.iconFiles = {134400}
    GetMacroIcons(EDITOR.iconFiles)
    EDITOR.iconScroller = CreateFrame("frame", nil, EDITOR, "OBroBindsIconListTemplate")
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
  scope.dbWrite("BLOBS", EDITOR.index, "icon", icon)
  if scope.SELECTOR.list then
    scope.SELECTOR.list:RefreshListDisplay()
  end
  return next(event, row, col, ...)
end

function scope.EditorDelete(next, ...)
  scope.dbWrite("BLOBS", scope.splice, EDITOR.index)
  for class in pairs(OBroBindsDB) do
    if class ~= "GUI" and class ~= "BLOBS" then
      for spec in pairs(OBroBindsDB[class]) do
        for binding in pairs(OBroBindsDB[class][spec]) do
          local action = setmetatable(OBroBindsDB[class][spec][binding], scope.ACTION)
          if action.blob then
            if action.id == EDITOR.index then
              scope.dbWrite(class, spec, binding, nil)
              if class == scope.CLASS and spec == scope.SPECC then
                scope:dispatch("ADDON_ACTION_UPDATED", binding, scope.bindingModifiers(binding))
              end
            elseif action.id > EDITOR.index then
              scope.dbWrite(class, spec, binding, scope.ACTION.id, action.id - 1)
              if class == scope.CLASS and spec == scope.SPECC then
                scope:dispatch("ADDON_ACTION_UPDATED", binding, scope.bindingModifiers(binding))
              end
            end
          end
          setmetatable(action, nil)
        end
      end
    end
  end
  if scope.SELECTOR.list then
    scope.SELECTOR.list:SetSelectedListIndex(nil, false)
    scope.SELECTOR.list:RefreshListDisplay()
  end
  scope:dispatch("ADDON_KEYBOARD_SHOW")
  return next(...)
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

function OBroBindsIconLineMixin:InitElement(...)
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

function OBroBindsIconLineMixin:UpdateDisplay()
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

function OBroBindsIconListMixin:OnLoad()
  self.ArtOverlay.SelectedHighlight:SetAlpha(0)
  self.InsetFrame:Hide()
  self.ScrollFrame.scrollBar.Background:Hide()
  self.ScrollFrame.scrollBar.ScrollBarTop:Hide()
  self.ScrollFrame.scrollBar.ScrollBarMiddle:Hide()
  self.ScrollFrame.scrollBar.ScrollBarBottom:Hide()
  self:SetPoint("TOPLEFT", 18, -68)
  self:SetPoint("BOTTOMRIGHT", self:GetParent(), "BOTTOMLEFT", 256, 52)
  self:SetElementTemplate("OBroBindsIconLineTemplate")
  self:SetGetNumResultsFunction(function(...)
    return math.ceil(#scope.EDITOR.iconFiles / 5)
  end)
end
