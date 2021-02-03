local scope = select(2, ...)

local function OnShow(self)
  scope:dispatch(self.NAME .. "_SHOW")
end

local function OnHide(self)
  scope:dispatch(self.NAME .. "_HIDE")
end

do
  OBroBindsRootMixin = {}
  OBroBindsRootMixin.NAME = "ADDON_ROOT"
  OBroBindsRootMixin.OnEvent = scope.dispatch
  OBroBindsRootMixin.OnShow = OnShow
  OBroBindsRootMixin.OnHide = OnHide
  function OBroBindsRootMixin:OnLoad()
    function _G.OBroBinds_Toggle()
      self[self:IsVisible() and 'Hide' or 'Show'](self)
    end
  end
  function scope.CreateRootFrame()
    scope.root = CreateFrame("frame", "OBroBindsRoot", UIParent, "OBroBindsRootTemplate")
    OBroBindsRootMixin = nil
    scope.CreateRootFrame = nil
  end
end

function scope.CreateRootPanel(event, ...)
  OBroBindsPanelMixin = {}
  function OBroBindsPanelMixin:OnDragStart(self)
    scope.root:StartMoving()
  end
  function OBroBindsPanelMixin:OnDragStop(self)
    scope.root:StopMovingOrSizing()
  end
  scope.panel = CreateFrame("frame", nil, scope.root, "OBroBindsPanelTemplate")
  scope.panel.Title:SetText("OBroBinds")
  scope.panel:RegisterForDrag("LeftButton")
  scope.panel:GetChildren():SetScript("OnClick", _G.OBroBinds_Toggle)
  OBroBindsPanelMixin.OnDragStart = nil
  OBroBindsPanelMixin.OnDragStop = nil
  OBroBindsPanelMixin.OnShow = OnShow
  OBroBindsPanelMixin.OnHide = OnHide
  OBroBindsPanelMixin.NAME = "ADDON_KEYBOARD"
  scope.keyboard = CreateFrame("frame", nil, scope.panel, "OBroBindsPageTemplate")
  scope.keyboard:Show()
  OBroBindsPanelMixin.NAME = "ADDON_SELECTOR"
  scope.selector = CreateFrame("frame", nil, scope.panel, "OBroBindsPageTemplate")
  scope.selector:Show()
  OBroBindsPanelMixin.NAME = "ADDON_EDITOR"
  scope.editor = CreateFrame("frame", "OBroPageEditor", scope.panel, "OBroBindsPageTemplate")
  OBroBindsPanelMixin = nil
  OnShow = nil
  OnHide = nil
  scope.CreateRootPanel = nil
  return event(...)
end

function scope.UpdatePlayerBindings(next, ...)
  ClearOverrideBindings(scope.root)
  scope.class = select(2, UnitClass("player"))
  scope.spec = GetSpecialization()
  for binding, action in scope.GetActions() do
    action:SetOverrideBinding(binding)
  end
  return next(...)
end

  --OBroBindsMixin = scope.clean(mixin)
  --OBroBindsMixin.OnShow = OnShow
  --OBroBindsMixin.OnHide = OnHide
  --OBroBindsMixin.keyName = "PAGE_KEYBOARD"

  --local button = CreateFrame("button", nil, scope.pageKeyboard, "UIPanelButtonTemplate")
  --button:SetSize(100, 36)
  --button:SetPoint("TOPRIGHT")
  --button:SetText("Toggle Pause")
  --local on = false
  --button:SetScript("OnClick", function(self)
    --scope.CLICK()
  --end)

  --OBroBindsMixin.keyName = "PAGE_SETTINGS"
  --scope.pageSettings = CreateFrame("frame", "OBroPageSettings", scope.panel, "OBroBindsPageTemplate")

  --local v = scope.dbRead("GUI", "page") or scope.tabKeyboard:GetID()
  --PanelTemplates_SetTab(scope.panel, 1)
  --PanelTemplates_TabResize(scope.tabKeyboard, 10)
  --PanelTemplates_TabResize(scope.tabSettings, 10)
  --mixin = scope.clean(OBroBindsMixin)
