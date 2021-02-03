local scope = select(2, ...)
local mixin

local function OnShow(self)
  scope:dispatch("ADDON_"..self.keyName.."_SHOW")
end
local function OnHide(self)
  scope:dispatch("ADDON_"..self.keyName.."_HIDE")
end

do
  local function OnLoad(self)
    function _G.OBroBinds_Toggle()
      self[self:IsVisible() and 'Hide' or 'Show'](self)
    end
  end
  function scope.createRootFrame()
    scope.createRootFrame = nil
    OBroBindsMixin = mixin or {}
    OBroBindsMixin.OnEvent = scope.dispatch
    OBroBindsMixin.keyName = "ROOT"
    OBroBindsMixin.OnShow = OnShow
    OBroBindsMixin.OnHide = OnHide
    OBroBindsMixin.OnLoad = OnLoad
    local frame = CreateFrame("frame", "OBroBindsRoot", UIParent, "OBroBindsRootTemplate")
    mixin = scope.clean(OBroBindsMixin)
    OBroBindsMixin = nil
    return frame
  end
end

do
  local function OnDragStart(self)
    scope.root:StartMoving()
  end
  local function OnDragStop(self)
    scope.root:StopMovingOrSizing()
  end
  local function OnClick(self)
    local parent, id = self:GetParent(), self:GetID()
    PanelTemplates_SetTab(parent, id)
    for index, page in ipairs(parent.Pages) do
      page[index == id and "Show" or "Hide"](page)
    end
  end

  function scope.createRootPanels(event, ...)
    scope.createRootPanels = nil

    OBroBindsMixin = mixin or {}
    OBroBindsMixin.OnDragStart = OnDragStart
    OBroBindsMixin.OnDragStop = OnDragStop
    scope.panel = CreateFrame("frame", nil, scope.root, "OBroBindsPanelTemplate")
    --scope.panel.numTabs = 2
    scope.panel.Title:SetText("OBroBinds")
    scope.panel:RegisterForDrag("LeftButton")
    local button = scope.panel:GetChildren()
    button:SetScript("OnClick", _G.OBroBinds_Toggle)

    --OBroBindsMixin = scope.clean(mixin)
    --OBroBindsMixin.OnClick = OnClick
    --scope.tabKeyboard = CreateFrame("button", "OBroTabKeybaord", scope.panel, "OBroBindsTabsTemplate")
    --scope.tabKeyboard:SetID(1)
    --scope.tabKeyboard:SetText("Keyboard")
    --scope.tabKeyboard:SetPoint("TOPLEFT", scope.panel, "BOTTOMLEFT", 16, 8)

    --scope.tabSettings = CreateFrame("button", "OBroTabSettings", scope.panel, "OBroBindsTabsTemplate")
    --scope.tabSettings:SetID(2)
    --scope.tabSettings:SetText("Settings")
    --scope.tabSettings:SetPoint("LEFT", scope.tabKeyboard, "RIGHT", -12, 0)

    OBroBindsMixin = scope.clean(mixin)
    OBroBindsMixin.OnShow = OnShow
    OBroBindsMixin.OnHide = OnHide
    OBroBindsMixin.keyName = "PAGE_KEYBOARD"
    scope.pageKeyboard = CreateFrame("frame", "OBroPageKeyboard", scope.panel, "OBroBindsPageTemplate")

    --local button = CreateFrame("button", nil, scope.pageKeyboard, "UIPanelButtonTemplate")
    --button:SetSize(100, 36)
    --button:SetPoint("TOPRIGHT")
    --button:SetText("Toggle Pause")
    --local on = false
    --button:SetScript("OnClick", function(self)
      --scope.CLICK()
    --end)

    OBroBindsMixin.keyName = "PAGE_SETTINGS"
    scope.pageSettings = CreateFrame("frame", "OBroPageSettings", scope.panel, "OBroBindsPageTemplate")

    --local v = scope.dbRead("GUI", "page") or scope.tabKeyboard:GetID()
    --PanelTemplates_SetTab(scope.panel, 1)
    --PanelTemplates_TabResize(scope.tabKeyboard, 10)
    --PanelTemplates_TabResize(scope.tabSettings, 10)

    mixin = scope.clean(OBroBindsMixin)
    OBroBindsMixin = nil
    return event(...)
  end
end

do
  local function OnClick(self)
    scope.offset = self.offset ~= scope.offset and self.offset or 1
    scope:dispatch("ADDON_OFFSET_CHANGED")
  end
  function scope.createStanceButton(offset, icon, ...)
    OBroBindsMixin = mixin or {}
    OBroBindsMixin.OnClick = OnClick
    local button = CreateFrame("button", nil, scope.pageKeyboard, "OBroBindsStanceButtonTemplate")
    button.offset = offset
    button:RegisterForClicks("AnyUp")
    button.icon:SetTexture("Interface/Icons/"..icon)
    mixin = scope.clean(OBroBindsMixin)
    OBroBindsMixin = nil
    return scope.push(button, ...)
  end
end

do
  local function OnEnter(self)
    scope:dispatch("ADDON_SHOW_TOOLTIP", self)
  end
  local function OnLeave(self)
    GameTooltip:Hide()
  end
  local function OnDragStart(self)
    if InCombatLockdown() then return end
    scope:dispatch("ADDON_PICKUP_OVERRIDE_BINDING", self)
    self:UpdateButton()
  end
  local function OnReceiveDrag(self)
    if InCombatLockdown() then return end
    scope:dispatch("ADDON_RECEIVE_OVERRIDE_BINDING", self)
    self:UpdateButton()
  end
  local function OnClick(self, button)
    if InCombatLockdown() then return end
    if button == "RightButton" then
      local binding = scope.modifier..self.key
      if not scope.mainbar[binding] then
        scope:dispatch("ADDON_SHOW_DROPDOWN", self)
      end
    elseif GetCursorInfo() then
      scope:dispatch("ADDON_RECEIVE_OVERRIDE_BINDING", self)
      self:UpdateButton()
    end
  end
  function scope.createActionButton()
    OBroBindsMixin = mixin or {}
    OBroBindsMixin.OnEnter = OnEnter
    OBroBindsMixin.OnLeave = OnLeave
    OBroBindsMixin.OnClick = OnClick
    OBroBindsMixin.OnDragStart = OnDragStart
    OBroBindsMixin.OnReceiveDrag = OnReceiveDrag
    local button = CreateFrame("button", nil, scope.pageKeyboard, "OBroBindsActionButtonTemplate")
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("AnyUp")
    button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    button.AutoCastable:SetTexCoord(0.15, 0.6, 0.6, 0.15)
    button.AutoCastable:ClearAllPoints()
    button.AutoCastable:SetPoint("BOTTOMLEFT", -14, -12)
    button.AutoCastable:SetScale(0.4)
    button.AutoCastable:SetAlpha(0.75)
    mixin = scope.clean(OBroBindsMixin)
    OBroBindsMixin = nil
    return button
  end
end


do
  OBroBindsLineMixin = {}

  local tmp

  function OBroBindsLineMixin:InitElement(...)
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("AnyUp")
    self.Icon:ClearAllPoints()
    self.Icon:SetPoint("TOPRIGHT", -2, -2)
    self.Icon:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -30, 2)
    self.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    if tmp then
      tmp:Cancel()
    end
    tmp = C_Timer.NewTicker(1, function()
      self:OnSelected()
      tmp = nil
    end, 1)
  end

  function OBroBindsLineMixin:UpdateDisplay()
    local binding = self:GetList().bindings[self.listIndex]
    local action = scope.dbGetAction(binding)
    self.Text:SetText(binding)
    self.TextMiddle:SetText(action.name)
    self.Icon:SetTexture(action:Icon())
  end

  function OBroBindsLineMixin:OnSelected()
    local binding = self:GetList().bindings[self.listIndex]
    scope:dispatch("ADDON_EDIT_BLOB", binding)
  end

  function OBroBindsLineMixin:OnDragStart()
    PickupSpell(204019)
  end

  function OBroBindsLineMixin:OnReceiveDrag()
  end

  OBroBindsListMixin = {}

  function OBroBindsListMixin:OnLoad()
    self.bindings = {}
    scope.clean(self.bindings)
    local n = 0
    for binding, action in scope.dbActions() do
      if action.kind and action.BLOB then
        n = n + 1
        table.insert(self.bindings, binding)
      end
    end
    self:SetSize(200, scope.panel:GetHeight()+24)
    self:SetPoint("RIGHT", scope.panel, "LEFT", 0, 0)
    self:SetElementTemplate("OLineTemplate")
    self:SetGetNumResultsFunction(function(...)
      return #self.bindings
    end)
  end

  function scope.createScrollbar(e, ...)
    scope.spellScroll = CreateFrame("frame", nil, scope.panel, "OListTemplate")
    return e(...)
  end
end

do
  function scope.createEditbox(e, ...)
    scope.editScroll = CreateFrame("ScrollFrame", nil, scope.pageSettings, "OBroBindsScrollTemplate")
    --scope.editScroll.edit:SetSize(scope.panel:GetWidth()-40, scope.panel:GetHeight()-40)
    scope.editScroll.edit:SetPoint("TOPLEFT", 8, -8)
    scope.editScroll.edit:SetSize(100, 100)
    local button = CreateFrame("button", nil, scope.pageSettings)
    button:SetAllPoints(scope.editScroll)
    button:SetScript("OnClick", function()
      scope.editScroll.edit:SetFocus()
    end)
    local bg = scope.editScroll.edit:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.5, 0.2, 0.4, 0.5)
    return e(...)
  end
end
