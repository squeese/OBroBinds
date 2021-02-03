local scope = select(2, ...)

OBroBindsLineMixin = {}

function OBroBindsLineMixin:InitElement(...)
  self:RegisterForDrag("LeftButton")
  self:RegisterForClicks("AnyUp")
  self.Text:SetFontObject("GameFontHighlight")
  self.Text:ClearAllPoints()
  self.Text:SetPoint("CENTER", self, "LEFT", 16, 0)
  self.Icon:ClearAllPoints()
  self.Icon:SetPoint("TOPLEFT", 2, -2)
  self.Icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 32, 2)
  self.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  self.Icon:SetVertexColor(1, 1, 1, 0.5)
end

function OBroBindsLineMixin:UpdateDisplay()
  local binding = scope.selector.bindings[self.listIndex]
  local action = scope.GetAction(binding)
  self.Text:SetText(binding)
  self.Upper:SetText(action.id)
  --self.Lower:SetText(action.name)
  self.Icon:SetTexture(action:Icon())
end

--function OBroBindsLineMixin:OnEnter(...)
  --print("OnEnter", ...)
--end

--function OBroBindsLineMixin:OnSelected()
  --print("OnSelected")
  ----local binding = scope.selector.bindings[self.listIndex]
  ----scope:dispatch("ADDON_EDITOR_SHOW")
  ----scope:dispatch("ADDON_EDITOR_LOAD", binding)
--end

function OBroBindsLineMixin:OnDragStart()
  local binding = scope.selector.bindings[self.listIndex]
  scope.PickupAction(binding)
end

OBroBindsListMixin = {}

function OBroBindsListMixin:OnLoad()
  self:SetPoint("TOPLEFT", 0, 0)
  self:SetPoint("BOTTOMRIGHT", 0, 0)
  self:SetElementTemplate("OBroBindsLineTemplate")
  self:SetGetNumResultsFunction(function(...)
    return #scope.selector.bindings
  end)
end

--function OBroBindsListMixin:AttachHighlightToElementFrame(...)
  --print("Attach", ...)
  --return TemplatedListMixin.AttachHighlightToElementFrame(self, ...)
--end


--function OBroBindsListMixin:RefreshListDisplay(...)
  --print("RefreshListDisplay", ...)
  --return TemplatedListMixin.RefreshListDisplay(self, ...)
--end

function OBroBindsListMixin:SetSelectedListIndex(index, ...)
  local binding = scope.selector.bindings[index]
  scope:dispatch("ADDON_EDITOR_SHOW")
  scope:dispatch("ADDON_EDITOR_SELECT", binding, index)
end

function scope.InitializeSelector(e, ...)
  scope.selector.locked = false
  scope.selector.bindings = {}
  scope.selector.list = CreateFrame("frame", nil, scope.selector, "OBroBindsListTemplate")
  scope.selector.list:SetAllPoints()
  OBroBindsListMixin = nil
  return e(...)
end

function scope.UpdateSelectorList(e, ...)
  scope.clean(scope.selector.bindings)
  for binding, action in scope.GetActions() do
    if action.kind and action.BLOB then
      table.insert(scope.selector.bindings, binding)
    end
  end
  scope.selector.list:RefreshListDisplay()
  return e(...)
end

do
  local function lock()
    for frame in scope.selector.list:EnumerateElementFrames() do
      frame.HighlightTexture:Hide()
    end
  end
  local function unlock()
    for frame in scope.selector.list:EnumerateElementFrames() do
      frame.HighlightTexture:Show()
    end
  end
  function scope.SetSelectorListLocked(value)
    if value == scope.selector.locked then return end
    scope.selector.locked = value
    if value then lock()
    else unlock()
    end
  end
end
