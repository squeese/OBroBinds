local scope = select(2, ...)
scope.ROOT = scope.CreateRootFrame()

--local chain = scope.poolAcquire(scope.CHAIN)
--local stack = scope.poolAcquire(scope.STACK,
  --scope.STACK.enqueue, "ADDON_TEST", function(next, ...)
    --print("ok", ...)
    --return next(...)
  --end,
  --scope.STACK.once, function(next, ...)
    --print("init", ...)
    --return next(...)
  --end
--)

--local n = 0
--C_Timer.NewTicker(0.5, function()
  --n = n + 1
  --scope:dispatch("ADDON_TEST", n)
--end)

--C_Timer.NewTicker(2, function()
  --scope.push(chain, stack)(3, 2, 1)
--end)


  --local tbl = {button, }
  --local function update(text)
    --print("update", text)
  --end


do

  local function update(text)
    print("update", text)
  end

  local macro = [[
    return
      STACK.enqueue, "ADDON_TEST", function(next, ...)
        update("hello world")
        return next(...)
      end,
      STACK.once, function(next, ...)
        print("init", ...)
        return next(...)
      end
  ]]

  local init, err = loadstring([[
    local STACK, update = ...
  ]]..macro)

  local stack = scope.poolAcquire(scope.STACK, init(scope.STACK, update))
  local chain = scope.poolAcquire(scope.CHAIN)

  -- enable
  print(scope.push(chain, stack)(1, 2, 3))
  scope:dispatch("ADDON_TEST", 1, 2, 3)
  scope:dispatch("ADDON_TEST", 1, 2, 3)

end


local MACROBUTTONS = {}
MACROBUTTONS.index = 0

function MACROBUTTONS:Create()
  self.index = self.index+1
  local button = CreateFrame("Button", "OBroBindsSecureBlobButton"..self.index, nil, "SecureActionButtonTemplate")
  button:RegisterForClicks("AnyUp")
  button:SetAttribute("type", "macro")
  button.command = "CLICK "..button:GetName()..":LeftButton"
  table.insert(self, button)




  return button
end

function scope.UpdatePlayerBindings(next, ...)
  ClearOverrideBindings(scope.ROOT)
  return next(...)
end

scope.enqueue("ADDON_ACTION_UPDATED", function(next, event, binding, ...)
  -- SetOverrideBinding(scope.ROOT, false, binding, nil)
  --local index = string.match(GetBindingAction(binding, true), "CLICK OBroBindsSecureBlobButton(%d+):LeftButton")
  local action = scope.GetAction(binding)
  print("update", binding, action.kind)
  return next(...)
end)

scope.enqueue("PLAYER_LOGIN", scope.poolAcquire(scope.STACK,
  scope.STACK.fold, nil,
  scope.STACK.once, scope.UpdatePlayerVariables,
  scope.STACK.once, scope.UpdatePlayerBindings,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED", scope.UpdatePlayerVariables,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED", scope.UpdatePlayerBindings,
  scope.STACK.once, function(next, ...)
    if scope.dbRead("GUI", "open") then
      scope:dispatch("ADDON_ROOT_SHOW")
    end
    --local v = OBroBindsDB.__tmp[1]["SHIFT-3"][3]
    --OBroBindsDB[scope.CLASS][scope.SPECC]["3"][3] = v
    return next(...)
  end
))

scope.enqueue("ADDON_ROOT_SHOW", scope.poolAcquire(scope.STACK,
  scope.STACK.fold, "ADDON_ROOT_HIDE",
  scope.STACK.setup, scope.STACK.apply(scope.ROOT, scope.ROOT.Show),
  scope.STACK.clear, scope.STACK.apply(scope.ROOT, scope.ROOT.Hide),
  scope.STACK.once, function(next, ...)
    scope.PANEL = scope.CreatePanelFrame()
    scope.KEYBOARD = scope.CreateKeyboardFrame()
    scope.EDITOR = scope.CreateEditorFrame()
    scope:dispatch("ADDON_KEYBOARD_SHOW")
    scope:dispatch("ADDON_EDITOR_SHOW")
    scope:dispatch("ADDON_EDITOR_SELECT", "3")
    return next(...)
  end
))

scope.enqueue("ADDON_KEYBOARD_SHOW", scope.poolAcquire(scope.STACK,
  scope.STACK.fold, "ADDON_KEYBOARD_HIDE",
  scope.STACK.setup, scope.STACK.apply(scope, scope.dispatch, "ADDON_EDITOR_HIDE"),
  scope.STACK.setup, scope.STACK.apply(scope, scope.read, "KEYBOARD", scope.ROOT.Show),
  scope.STACK.clear, scope.STACK.apply(scope, scope.read, "KEYBOARD", scope.ROOT.Hide),
  scope.STACK.once, scope.UpdateUnknownSpells,
  scope.STACK.once, function(next, ...)
    scope.STANCE_OFFSET  = 1   -- stance offset to the proper ACTIONBUTTON position
    scope.STANCE_BUTTONS = nil -- stance buttons
    scope.ACTION_BUTTONS = nil -- keyboard buttons for binding spells
    scope.PORTAL_BUTTONS = nil -- keyboard buttons for moving buttons on main actionbar
    scope.MODIFIER       = nil -- current pressed modifier
    scope.InitializeKeyboardStanceButtons()
    scope.InitializeKeyboardModifierListener()
    return next(scope.DEFAULT_KEYBOARD_LAYOUT, ...)
  end,
  scope.STACK.once,    scope.UpdateKeyboardLayout,
  scope.STACK.setup,   scope.UpdateKeyboardStanceButtons,
  scope.STACK.setup,   scope.UpdateKeyboardMainbarIndices,
  scope.STACK.setup,   scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "ADDON_UPDATE_LAYOUT",            scope.UpdateKeyboardLayout,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateKeyboardStanceButtons,
  scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.UpdateKeyboardStanceButtons,
  scope.STACK.enqueue, "UPDATE_BINDINGS",                scope.UpdateKeyboardMainbarIndices,
  scope.STACK.enqueue, "ACTIONBAR_SLOT_CHANGED",         scope.UpdateKeyboardMainbarSlots,
  scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.UpdateKeyboardMainbarOffsets,
  scope.STACK.enqueue, "ADDON_MODIFIER_CHANGED",         scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "UPDATE_MACROS",                  scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateKeyboardActionButtons,
  scope.STACK.enqueue, "ADDON_SHOW_TOOLTIP",             scope.UpdateTooltip,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.RefreshTooltip,
  scope.STACK.enqueue, "ADDON_MODIFIER_CHANGED",         scope.RefreshTooltip,
  scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.RefreshTooltip,
  scope.STACK.enqueue, "ADDON_OFFSET_CHANGED",           scope.RefreshTooltip,
  scope.STACK.enqueue, "UPDATE_BINDINGS",                scope.RefreshTooltip,
  scope.STACK.enqueue, "PLAYER_TALENT_UPDATE",           scope.UpdateUnknownSpells,
  scope.STACK.enqueue, "PLAYER_SPECIALIZATION_CHANGED",  scope.UpdateUnknownSpells,
  scope.STACK.enqueue, "ADDON_SHOW_DROPDOWN",            scope.UpdateDropdown,
  scope.STACK.enqueue, "ADDON_ACTION_UPDATED",           scope.UpdateChangedActionButtons
))

scope.enqueue("ADDON_EDITOR_SHOW", scope.poolAcquire(scope.STACK,
  scope.STACK.fold, "ADDON_EDITOR_HIDE",
  scope.STACK.setup, scope.STACK.apply(scope, scope.dispatch, "ADDON_KEYBOARD_HIDE"),
  scope.STACK.setup, scope.STACK.apply(scope, scope.read, "EDITOR", scope.ROOT.Show),
  scope.STACK.clear, scope.STACK.apply(scope, scope.read, "EDITOR", scope.ROOT.Hide),
  scope.STACK.once, function(next, ...)
    scope.EDITOR.DIRTY = nil          -- state of the editor, if there are unsaved changes
    scope.EDITOR.ACTION = nil         -- current action being edited
    scope.EDITOR.BINDING = nil        -- binding the the action
    scope.EDITOR.iconScroller = nil   -- scrollframe (IconListTemplate) for changing icons
    scope.EDITOR.iconFiles = nil      -- huge table of macro icons
    scope.EDITOR.iconButton,          -- toggle the icon selection gui
    scope.EDITOR.nameInput,           -- name of the macro
    scope.EDITOR.scriptToggle,        -- toggle on/off script behavious for macro's
    scope.EDITOR.saveButton,
    scope.EDITOR.cancelButton,
    scope.EDITOR.closeButton,
    scope.EDITOR.bodyScroller,
    scope.EDITOR.bodyInput = scope.CreateEditorComponentFrames()
    return next(...)
  end,
  scope.STACK.enqueue, "ADDON_EDITOR_SELECT",        scope.EditorSelect,
  scope.STACK.enqueue, "ADDON_EDITOR_BODY_CHANGED",  scope.EditorUpdateButtons,
  scope.STACK.enqueue, "ADDON_EDITOR_NAME_CHANGED",  scope.EditorUpdateButtons,
  scope.STACK.enqueue, "ADDON_EDITOR_CHANGE_SCRIPT", scope.EditorUpdateButtons,
  scope.STACK.enqueue, "ADDON_EDITOR_ICONS",         scope.EditorToggleIcons,
  scope.STACK.enqueue, "ADDON_EDITOR_CHANGE_ICON",   scope.EditorChangeIcon,
  scope.STACK.enqueue, "ADDON_EDITOR_SAVE",          scope.EditorSave,
  scope.STACK.enqueue, "ADDON_EDITOR_UNDO",          scope.EditorUndo,
  scope.STACK.clear, scope.EditorCleanup,
  scope.STACK.setup, function(next, ...)
    scope.EDITOR.__height = scope.ROOT:GetHeight()
    scope.ROOT:SetHeight(500)
    return next(...)
  end,
  scope.STACK.clear, function(next, ...)
    scope.ROOT:SetHeight(scope.EDITOR.__height)
    scope.EDITOR.__height = nil
    return next(...)
  end
))
