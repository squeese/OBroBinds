local scope = select(2, ...)

--[[
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

  scope.CreatePanelFrame = nil
  return event(...)
end

function scope.UpdatePlayerBindings(next, ...)
  if not InCombatLockdown() then
    ClearOverrideBindings(scope.root)
    scope.secureButtons.index = 0
    scope.class = select(2, UnitClass("player"))
    scope.spec = GetSpecialization()
    for binding, action in scope.GetActions() do
      action:SetOverrideBinding(binding)
    end
  end
  return next(...)
end
]]
