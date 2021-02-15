local scope = select(2, ...)

function scope.UpdateRootPosition(next, ...)
  local point, _, relPoint, x, y = scope.ROOT:GetPoint()
  if point == "CENTER" then
    scope.ROOT:ClearAllPoints()
    scope.ROOT:SetPoint("TOP", UIParent, relPoint, x, y+scope.ROOT:GetHeight()/2)
  elseif point == "RIGHT" then
    scope.ROOT:ClearAllPoints()
    scope.ROOT:SetPoint("TOPRIGHT", UIParent, relPoint, x, y+scope.ROOT:GetHeight()/2)
  elseif point == "LEFT" then
    scope.ROOT:ClearAllPoints()
    scope.ROOT:SetPoint("TOPLEFT", UIParent, relPoint, x, y+scope.ROOT:GetHeight()/2)
  elseif point == "BOTTOMRIGHT" then
    scope.ROOT:ClearAllPoints()
    scope.ROOT:SetPoint("TOPRIGHT", UIParent, relPoint, x, y+scope.ROOT:GetHeight())
  elseif point == "BOTTOMLEFT" then
    scope.ROOT:ClearAllPoints()
    scope.ROOT:SetPoint("TOPLEFT", UIParent, relPoint, x, y+scope.ROOT:GetHeight())
  end
  return next(...)
end

function scope.UpdateUnknownSpells(next, ...)
  for binding, action in scope.GetActions() do
    if action.spell and not action.id then
      local icon, _, _, _, id = select(3, GetSpellInfo(action.name))
      action[2], action[4] = id, icon or action.icon
    elseif action.blob and not action.script and action.icon == 134400 then
      local macro = CreateMacro("__TMP__", "INV_MISC_QUESTIONMARK", action.body)
      _, icon = GetMacroInfo(macro)
      DeleteMacro(macro)
      action[4] = icon or action.icon
    end
  end
  return next(...)
end
