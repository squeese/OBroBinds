local scope = select(2, ...)



function scope.UpdateUnknownSpells(e, ...)
  for binding, action in scope.dbActions() do
    if action.SPELL and not action.id then
      local icon, _, _, _, id = select(3, GetSpellInfo(action.name))
      action[1], action[4] = id, icon or action.icon
    end
  end
  return e(...)
end







