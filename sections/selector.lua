local scope = select(2, ...)

local function bg(frame, ...)
  frame.bg = frame:CreateTexture(nil, "BACKGROUND")
  frame.bg:SetAllPoints()
  frame.bg:SetColorTexture(...)
end

function scope.InitializeSelector(e, ...)
  scope.selector:ClearAllPoints()
  scope.selector:SetPoint("TOPLEFT", scope.panel, "TOPRIGHT", 0, 0)
  scope.selector:SetPoint("BOTTOMLEFT", scope.panel, "BOTTOMRIGHT", 0, 0)
  scope.selector:SetWidth(200)

  --bg(scope.selector, 0.5, 0.2, 0.4, 1)

  local button = CreateFrame("CheckButton", nil, scope.selector, "OBroBindsTabsTemplate")
  button:ClearAllPoints()
  button:SetPoint("TOPLEFT", scope.selector, "TOPRIGHT", 0, -32)
  button:Show()
  button:SetScript("OnClick", nil)
  button.tooltip = "ok"
  local _, texture = GetSpellTabInfo(1)
  button:SetNormalTexture(texture)
  button:SetChecked(true)

  --bg(button, 0.5, 0.8, 0.9, 0.5)

  return e(...)
end
