local scope = select(2, ...)

local function RemoveOverride(self, button, binding)
  scope.dbDeleteAction(binding)
  button:UpdateButton()
  CloseDropDownMenus()
end
local function RemoveBinding(self, button, binding)
  SetBinding(binding, nil)
  SaveBindings(GetCurrentBindingSet())
  button:UpdateButton()
  CloseDropDownMenus()
end
local function PromoteBinding(self, button, binding)
  scope.dbPromoteToAction(binding)
  SetBinding(binding, nil)
  SaveBindings(GetCurrentBindingSet())
  button:UpdateButton()
  CloseDropDownMenus()
end
local function LockBinding(self, button, binding)
  scope.dbToggleActionLock(binding)
  button:UpdateButton()
  CloseDropDownMenus()
end
local function CreateBlob(self, button, binding)
  scope.dbSaveAction(binding, "BLOB", "noname", "/cast Fade", 3615513)
  button:UpdateButton()
  CloseDropDownMenus()
end
local function EditBlob(self, button, binding)
  scope:dispatch("ADDON_EDIT_BLOB", binding)
  CloseDropDownMenus()
end

local drop, info
local function reset()
  info.hasArrow = false
  info.menuList = nil
  info.isTitle = false
  info.disabled = false
  info.notCheckable = true
  info.checked = false
  info.func = nil
end

local function InitializeDropdown(self, _, section)
  local button = info.arg1
  local binding = scope.modifier..button.key
  info.arg2 = binding
  if section == "root" then
    local action = scope.dbGetAction(binding)
    local command = GetBindingAction(binding, false)

    reset()
    info.text = "Override"
    info.isTitle = true
    UIDropDownMenu_AddButton(info, 1)

    reset()
    info.text = not action.kind and 'none' or action.kind.." "..action.name
    info.hasArrow = not action.locked
    info.menuList = "override"
    info.disabled = action.locked
    UIDropDownMenu_AddButton(info, 1)
    UIDropDownMenu_AddSeparator(1)

    reset()
    info.text = "Binding"
    info.isTitle = true
    UIDropDownMenu_AddButton(info, 1)

    reset()
    info.text = command == "" and "none" or command
    info.hasArrow = not action.locked and command ~= ""
    info.menuList = "binding"
    info.disabled = not info.hasArrow
    UIDropDownMenu_AddButton(info, 1)

    reset()
    info.text = action.locked and "Unlock" or "Lock"
    info.notCheckable = false
    info.checked = action.locked
    info.func = LockBinding
    UIDropDownMenu_AddButton(info, 1)

  elseif section == "override" then
    local action = scope.dbGetAction(binding)

    if action.BLOB then
      reset()
      info.text = "Edit blob"
      info.func = EditBlob
      UIDropDownMenu_AddButton(info, 2)
    end

    if action.kind then
      reset()
      info.text = "Clear override"
      info.func = RemoveOverride
      UIDropDownMenu_AddButton(info, 2)
    else
      reset()
      info.text = "Create blob"
      info.func = CreateBlob
      UIDropDownMenu_AddButton(info, 2)
    end

  elseif section == "binding" then
    local command = GetBindingAction(binding, false)
    local kind, name = string.match(command, "^(%w+) (.*)$")
    if kind == 'SPELL' or kind == 'MACRO' or kind == 'ITEM' then
      reset()
      info.text = "Promote to override"
      info.func = PromoteBinding
      UIDropDownMenu_AddButton(info, 2)
    end
    reset()
    info.text = "Clear binding"
    info.func = RemoveBinding
    UIDropDownMenu_AddButton(info, 2)
  end
end

function scope.UpdateDropdown(e, button, ...)
  if not drop then
    info = UIDropDownMenu_CreateInfo()
    drop = CreateFrame("frame", nil, UIParent, "UIDropDownMenuTemplate")
    drop.displayMode = "MENU"
    drop.initialize = InitializeDropdown
  end
  info.arg1 = button
  ToggleDropDownMenu(1, nil, drop, "cursor", 0, 0, "root")
  return e(button, ...)
end
