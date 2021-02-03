local scope = select(2, ...)

local function OnShow(self)
  scope:dispatch(self.NAME .. "_SHOW")
end

local function OnHide(self)
  scope:dispatch(self.NAME .. "_HIDE")
end

function scope.CreateRootFrame()
  -- movable true
  scope.root = CreateFrame("frame", "OBroBindsRoot", UIParent, nil)
  scope.root:Hide()
  scope.root.NAME = "ADDON_ROOT"
  scope.root:SetScript("OnShow", OnShow)
  scope.root:SetScript("OnHide", OnHide)
  scope.root:SetScript("OnEvent", scope.dispatch)
  function _G.OBroBinds_Toggle()
    scope.root[scope.root:IsVisible() and 'Hide' or 'Show'](scope.root)
  end
  scope.root:SetSize(400, 200)
  scope.root:SetPoint("CENTER", 0, 0)
  scope.CreateRootFrame = nil
end

local function bg(frame, ...)
  frame.bg = frame:CreateTexture(nil, "BACKGROUND")
  frame.bg:SetAllPoints()
  frame.bg:SetColorTexture(...)
end

function scope.CreatePanelFrame(event, ...)
  --scope.panel: mouse enabled
  scope.panel = CreateFrame("frame", nil, scope.root, "UIPanelDialogTemplate")
  scope.panel:SetAllPoints()
  scope.panel:RegisterForDrag("LeftButton")
  scope.panel.Title:SetText("OBroBinds")
  scope.panel:GetChildren():SetScript("OnClick", _G.OBroBinds_Toggle)
  scope.panel:SetScript("OnDragStart", function()
    scope.root:StartMoving()
  end)
  scope.panel:SetScript("OnDragStop", function()
    scope.root:StopMovingOrSizing()
  end)

  scope.keyboard = CreateFrame("frame", nil, scope.panel, nil)
  scope.keyboard:Hide()
  scope.keyboard.NAME = "ADDON_KEYBOARD"
  scope.keyboard:SetAllPoints()
  scope.keyboard:SetScript("OnShow", OnShow)
  scope.keyboard:SetScript("OnHide", OnHide)
  scope.keyboard:Show()

  --scope.spellScroll = CreateFrame("frame", nil, scope.panel, "OListTemplate")

  scope.selector = CreateFrame("frame", nil, scope.panel, nil)
  scope.selector:Hide()
  scope.selector.NAME = "ADDON_SELECTOR"
  scope.selector:SetScript("OnShow", OnShow)
  scope.selector:SetScript("OnHide", OnHide)
  scope.selector:SetPoint("TOPLEFT", scope.panel, "TOPRIGHT", 0, 0)
  scope.selector:SetPoint("BOTTOMLEFT", scope.panel, "BOTTOMRIGHT", 0, 0)
  scope.selector:SetWidth(200)

  scope.selector.button = CreateFrame("CheckButton", nil, scope.panel, "OBroBindsTabsTemplate")
  scope.selector.button:ClearAllPoints()
  scope.selector.button:SetPoint("TOPLEFT", scope.panel, "TOPRIGHT", 0, -32)
  scope.selector.button:Show()
  scope.selector.button:SetScript("OnClick", nil)
  scope.selector.button.tooltip = "ok"
  --local _, texture = GetSpellTabInfo(1)
  --button:SetNormalTexture(texture)
  --button:SetChecked(true)

  bg(scope.selector, 0.5, 0.2, 0.4, 1)

  scope.CreatePanelFrame = nil
  OnShow = nil
  OnHide = nil
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
