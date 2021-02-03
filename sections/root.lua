local scope = select(2, ...)

function scope.CreateRootFrame()
  scope.secureButtons = {index = 0}
  scope.root = CreateFrame("frame", "OBroBindsRoot", UIParent, nil)
  scope.root:SetMovable(true)
  scope.root:Hide()
  scope.root:SetScript("OnEvent", scope.dispatch)
  function _G.OBroBinds_Toggle()
    local visible = scope.root:IsVisible()
    print("visible", visible)
    scope.dbWrite("GUI", "open", not visible and true or nil)
    scope:dispatch(visible and 'ADDON_ROOT_HIDE' or 'ADDON_ROOT_SHOW')
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
  scope.panel:EnableMouse(true)
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
  scope.keyboard:SetAllPoints()

  scope.editor = CreateFrame("frame", nil, scope.panel, nil)
  scope.editor:Hide()
  scope.editor:SetAllPoints()

  --scope.selector = CreateFrame("frame", nil, scope.panel, nil)
  --scope.selector:Hide()
  --scope.selector:SetPoint("TOPLEFT", scope.panel, "TOPRIGHT", 0, -4)
  --scope.selector:SetPoint("BOTTOMLEFT", scope.panel, "BOTTOMRIGHT", 0, 4)
  --scope.selector:SetWidth(200)

  scope.CreatePanelFrame = nil
  return event(...)
end

function scope.UpdatePlayerBindings(next, ...)
  ClearOverrideBindings(scope.root)
  scope.secureButtons.index = 0
  scope.class = select(2, UnitClass("player"))
  scope.spec = GetSpecialization()
  for binding, action in scope.GetActions() do
    action:SetOverrideBinding(binding)
  end
  return next(...)
end
