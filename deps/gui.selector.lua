local scope = select(2, ...)

OBroBindsBlobListMixin = {}
function OBroBindsBlobListMixin:OnLoad()
  self.InsetFrame:Hide()
  self.ScrollFrame.scrollBar.Background:Hide()
  self.ScrollFrame.scrollBar.ScrollBarTop:Hide()
  self.ScrollFrame.scrollBar.ScrollBarMiddle:Hide()
  self.ScrollFrame.scrollBar.ScrollBarBottom:Hide()
  self:SetElementTemplate("OBroBindsBlobLineTemplate")
  self:SetGetNumResultsFunction(function(...)
    return #(scope.dbRead("BLOBS") or scope.NIL)
  end)
end

function OBroBindsBlobListMixin:AttachHighlightToElementFrame(selectedHighlight, elementFrame)
  selectedHighlight:SetPoint("TOPLEFT", elementFrame, "TOPLEFT", 0, 0);
  selectedHighlight:SetPoint("BOTTOMRIGHT", elementFrame, "BOTTOMRIGHT", 0, 0);
  selectedHighlight:Show();
end

local function OnDragStart(self)
  scope.PickupBlob(self.listIndex)
end

OBroBindsBlobLineMixin = {}
function OBroBindsBlobLineMixin:InitElement(...)
  local height = self:GetHeight()
  self.icon = self:CreateTexture(nil, "BACKGROUND")
  self.icon:SetPoint("TOPLEFT", 0, 0)
  self.icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", height-1, 1)
  self.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  self.Text:SetPoint("LEFT", height + 2, 0)
  self:SetScript("OnDragStart", OnDragStart)
  self:RegisterForDrag("LeftButton")
end

function OBroBindsBlobLineMixin:UpdateDisplay()
  local blob = scope.dbRead("BLOBS", self.listIndex)
  self.Text:SetText(blob.name)
  self.icon:SetTexture(blob.icon)
end

function OBroBindsBlobLineMixin:OnClick()
  if not scope.EDITOR.DIRTY then
    TemplatedListElementMixin.OnClick(self)
  end
end

function OBroBindsBlobLineMixin:OnSelected()
  scope:dispatch("ADDON_EDITOR_SHOW")
  scope:dispatch("ADDON_EDITOR_SELECT", self.listIndex)
end
