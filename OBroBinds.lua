local scope = select(2, ...)
scope.root = scope.createFrame("frame", nil, UIParent, "OBroBindsRootFrameTemplate", {
  OnEvent = scope.dispatch,
  OnShow = function()
    scope:dispatch("ADDON_ROOT_SHOW")
  end,
  OnHide = function()
    scope:dispatch("ADDON_ROOT_HIDE")
  end,
  OnLoad = function(self)
    function _G.OBroBinds_Toggle()
      if self:IsVisible() then
        self:Hide()
      else
        self:Show()
      end
    end
  end,
})

scope.ACTION = { kind = 1, id = 2, name = 3, icon = 4, locked = 5, SPELL = 6, MACRO = 6, ITEM = 6, BLOB = 6 }

function scope.ACTION:__index(key)
  if self == scope.empty then return end
  local val = scope.ACTION[key]
  if type(val) ~= 'number' then
    return val
  elseif val == 6 then
    return rawget(self, 1) == key
  else
    return rawget(self, val)
  end
  return value
end
function scope.ACTION:SetOverrideBinding(binding)
  if self.SPELL then
    SetOverrideBindingSpell(scope.root, false, binding, GetSpellInfo(self.id) or self.name)
  elseif self.MACRO then
    SetOverrideBindingMacro(scope.root, false, binding, self.name)
  elseif self.ITEM then
    SetOverrideBindingItem(scope.root, false, binding, self.name)
  elseif self.BLOB then
  end
end
function scope.ACTION:Icon()
  if self.SPELL then
    return select(3, GetSpellInfo(self.id)) or self.icon 
  elseif self.MACRO then
    return select(2, GetMacroInfo(self.name)) or self.icon
  elseif self.ITEM then
    return select(10, GetItemInfo(self.id or 0)) or self.icon
  elseif self.BLOB then
    return 441148
  end
  return self.icon or nil
end

function scope.dbActionIterator(...)
  local k, v = next(...)
  return k, setmetatable(v or scope.empty, scope.ACTION)
end

function scope.dbActions()
  return scope.dbActionIterator, scope.read(OBroBindsDB, scope.class, scope.spec) or scope.empty
end

function scope.dbRead(...)
  return scope.read(OBroBindsDB, ...)
end

function scope.dbWrite(...)
  OBroBindsDB = scope.write(OBroBindsDB, ...)
end

function scope.UpdatePlayerBindings(next, ...)
  print("UpdatePlayerBindings", next.key)
  ClearOverrideBindings(scope.root)
  scope.class = select(2, UnitClass("player"))
  scope.spec = GetSpecialization()
  for binding, action in scope.dbActions() do
    action:SetOverrideBinding(binding)
  end
  return next(...)
end


scope.enqueue("PLAYER_LOGIN", setmetatable({
  scope.STACK.fold, nil,
  scope.STACK.call, scope.UpdatePlayerBindings,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED", scope.UpdatePlayerBindings,
  scope.STACK.init, function(next, ...)
    scope.root[scope.dbRead('GUI', 'open') and 'Show' or 'Hide'](scope.root)
    return next(...)
  end,
}, scope.STACK))

scope.enqueue("ADDON_ROOT_SHOW", setmetatable({
  scope.STACK.fold, "ADDON_ROOT_HIDE",
  scope.STACK.init, function(next, ...)
    scope.panel = CreateFrame("frame", nil, scope.root, "OBroBindsRootFramePanelTemplate")
    scope.tab1 = CreateFrame("button", "asdasTab1", scope.panel, "OBroBindsRootFramePanelTabsTemplate")
    scope.tab2 = CreateFrame("button", "asdfaTab2", scope.panel, "OBroBindsRootFramePanelTabsTemplate")
    scope.tab1:SetPoint("TOPLEFT", scope.panel, "BOTTOMLEFT", 16, 8)
    scope.tab2:SetPoint("LEFT", scope.tab1, "RIGHT", -12, 0)
  end,
  scope.STACK.both, function(next, ...)
    if next.key == "ADDON_ROOT_SHOW" then
      scope.dbWrite('GUI', 'open', true)
      --root.Pages[PanelTemplates_GetSelectedTab(root)]:Show()
    else
      scope.dbWrite('GUI', 'open', nil)
      --root.Pages[PanelTemplates_GetSelectedTab(root)]:Hide()
    end
    return next(...)
  end,
}, scope.STACK))

--listen("ADDON_PAGE_KEYBOARD_SHOW", setmetatable({
  --STACK.fold, "ADDON_PAGE_KEYBOARD_HIDE",
  --STACK.init, _A.InitializePageKeyboard,
  --STACK.init, _A.UpdateKeyboardLayout,
  --STACK.call, _A.UpdateKeyboardStanceButtons,
  --STACK.call, _A.UpdateKeyboardMainbarIndices,
  --STACK.call, _A.UpdateAllKeyboardButtons,
  --STACK.listen, "ADDON_UPDATE_LAYOUT",            _A.UpdateKeyboardLayout,
  --STACK.listen, "UPDATE_BINDINGS",                _A.UpdateKeyboardMainbarIndices,
  --STACK.listen, "ACTIONBAR_SLOT_CHANGED",         _A.UpdateKeyboardMainbarSlots,
  --STACK.listen, "ADDON_OFFSET_CHANGED",           _A.UpdateKeyboardMainbarOffsets,
  --STACK.listen, "ADDON_MODIFIER_CHANGED",         _A.UpdateAllKeyboardButtons,
  --STACK.listen, "ADDON_PLAYER_TALENT_UPDATE",     _A.UpdateAllKeyboardButtons,
  --STACK.listen, "ADDON_UPDATE_MACROS",            _A.UpdateAllKeyboardButtons,
  --STACK.listen, "PLAYER_SPECIALIZATION_CHANGED",  _A.UpdateAllKeyboardButtons,
  --STACK.listen, "ADDON_OFFSET_CHANGED",           _A.UpdateKeyboardStanceButtons,
  --STACK.listen, "PLAYER_SPECIALIZATION_CHANGED",  _A.UpdateKeyboardStanceButtons,
  --STACK.listen, "ADDON_SHOW_TOOLTIP",             _A.UpdateTooltip,
  --STACK.listen, "PLAYER_SPECIALIZATION_CHANGED",  _A.RefreshTooltip,
  --STACK.listen, "ADDON_MODIFIER_CHANGED",         _A.RefreshTooltip,
  --STACK.listen, "PLAYER_TALENT_UPDATE",           _A.RefreshTooltip,
  --STACK.listen, "ADDON_OFFSET_CHANGED",           _A.RefreshTooltip,
  --STACK.listen, "UPDATE_BINDINGS",                _A.RefreshTooltip,
  --STACK.listen, "PLAYER_TALENT_UPDATE",           _A.UpdateUnknownSpells,
  --STACK.listen, "PLAYER_SPECIALIZATION_CHANGED",  _A.UpdateUnknownSpells,
--}, STACK))

--function dispatch(key, ...)
  --print("dispatch", key, ...)
--end


--local mixin = {}
--function mixin:OnShow()
  --print("OnShow")
--end
--function mixin:OnLoad()
  --print("OnLoad")
--end
--function mixin:OnEvent(...)
  --dispatch(...)
--end

--OBroBindsMixin = mixin
--local f = CreateFrame("frame", nil, UIParent, "OBroBindsFrame")
--OBroBindsMixin = nil

--f:SetPoint("CENTER", 1, 1)
--f:SetSize(100, 100)
--f:RegisterEvent("PLAYER_LOGIN")
