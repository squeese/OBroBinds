

    --return push(e, ):once(frame)

--do
  --local OnHide
  --local function OnShow(e, frame)
    --frame:RegisterEvent("UPDATE_BINDINGS")
    --frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    --frame:RegisterEvent("UPDATE_MACROS")
    --frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    --frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    --frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    --listen("GET_OVERRIDE_ENTRY", _A.GetOverrideEntry)
    --listen("DEL_OVERRIDE_ENTRY", _A.DelOverrideEntry)
    --listen("PICKUP_OVERRIDE_ENTRY", _A.PickupOverrideEntry)
    --listen("RECEIVE_OVERRIDE_ENTRY", _A.ReceiveOverrideEntry)
    --listen("PROMOTE_OVERRIDE_ENTRY", _A.PromoteOverrideEntry)
    --listen("LOCK_OVERRIDE_ENTRY", _A.LockOverrideEntry)

    --listen("UPDATE_LAYOUT", _A.UpdateKeyboardLayout)
    --listen("UPDATE_BINDINGS", _A.UpdateKeyboardMainbarBindings)
    --listen("UPDATE_BINDINGS", _A.UpdateKeyboardButtons)
    --listen("UPDATE_BINDINGS", _A.RefreshTooltip)
    --listen("OFFSET_CHANGED", _A.UpdateStanceButtons)
    --listen("OFFSET_CHANGED", _A.UpdateKeyboardButtons)
    --listen("OFFSET_CHANGED", _A.RefreshTooltip)
    --listen("UPDATE_MACROS", _A.UpdateKeyboardButtons)
    --listen("MODIFIER_CHANGED", _A.UpdateKeyboardButtons)
    --listen("MODIFIER_CHANGED", _A.RefreshTooltip)
    --listen("PLAYER_TALENT_UPDATE", _A.UpdateUnknownSpells)
    --listen("PLAYER_TALENT_UPDATE", _A.UpdateKeyboardButtons)
    --listen("PLAYER_TALENT_UPDATE", _A.RefreshTooltip)
    --listen("UPDATE_MACROS", _A.UpdateKeyboardButtons)
    --listen("PLAYER_SPECIALIZATION_CHANGED", _A.UpdateUnknownSpells)
    --listen("PLAYER_SPECIALIZATION_CHANGED", _A.UpdateStanceButtons)
    --listen("PLAYER_SPECIALIZATION_CHANGED", _A.UpdateKeyboardButtons)
    --listen("PLAYER_SPECIALIZATION_CHANGED", _A.RefreshTooltip)
    --listen("SHOW_TOOLTIP", _A.UpdateTooltip)
    --listen("SHOW_DROPDOWN", _A.UpdateDropdown)
    --listen("ACTIONBAR_SLOT_CHANGED", _A.UpdateKeyboardMainbarSlots)
    --listen("GUI_HIDE", OnHide)
    --return push(e, _A.UpdateKeyboardButtons, _A.UpdateKeyboardMainbarBindings, _A.UpdateStanceButtons):once(frame)
  --end
  --function OnHide(e, frame)
    --frame:UnregisterEvent("UPDATE_BINDINGS")
    --frame:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
    --frame:UnregisterEvent("UPDATE_MACROS")
    --frame:UnregisterEvent("PLAYER_TALENT_UPDATE")
    --frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
    --frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    --release("GET_OVERRIDE_ENTRY", _A.GetOverrideEntry)
    --release("DEL_OVERRIDE_ENTRY", _A.DelOverrideEntry)
    --release("PICKUP_OVERRIDE_ENTRY", _A.PickupOverrideEntry)
    --release("RECEIVE_OVERRIDE_ENTRY", _A.ReceiveOverrideEntry)
    --release("PROMOTE_OVERRIDE_ENTRY", _A.PromoteOverrideEntry)
    --release("LOCK_OVERRIDE_ENTRY", _A.LockOverrideEntry)
    --release("UPDATE_LAYOUT", _A.UpdateKeyboardLayout)
    --release("UPDATE_BINDINGS", _A.UpdateKeyboardMainbarBindings)
    --release("UPDATE_BINDINGS", _A.UpdateKeyboardButtons)
    --release("UPDATE_BINDINGS", _A.RefreshTooltip)
    --release("OFFSET_CHANGED", _A.UpdateStanceButtons)
    --release("OFFSET_CHANGED", _A.UpdateKeyboardButtons)
    --release("OFFSET_CHANGED", _A.RefreshTooltip)
    --release("UPDATE_MACROS", _A.UpdateKeyboardButtons)
    --release("MODIFIER_CHANGED", _A.UpdateKeyboardButtons)
    --release("MODIFIER_CHANGED", _A.RefreshTooltip)
    --release("PLAYER_TALENT_UPDATE", _A.UpdateUnknownSpells)
    --release("PLAYER_TALENT_UPDATE", _A.UpdateKeyboardButtons)
    --release("PLAYER_TALENT_UPDATE", _A.RefreshTooltip)
    --release("UPDATE_MACROS", _A.UpdateKeyboardButtons)
    --release("PLAYER_SPECIALIZATION_CHANGED", _A.UpdateUnknownSpells)
    --release("PLAYER_SPECIALIZATION_CHANGED", _A.UpdateStanceButtons)
    --release("PLAYER_SPECIALIZATION_CHANGED", _A.UpdateKeyboardButtons)
    --release("PLAYER_SPECIALIZATION_CHANGED", _A.RefreshTooltip)
    --release("SHOW_TOOLTIP", _A.UpdateTooltip)
    --release("SHOW_DROPDOWN", _A.UpdateDropdown)
    --release("ACTIONBAR_SLOT_CHANGED", _A.UpdateKeyboardMainbarSlots)
    --listen("GUI_SHOW", OnShow)
    --collectgarbage("collect")
    --return e:once(frame)
  --end
  --listen("GUI_SHOW", function(e, frame)
    ----frame:SetScript("OnUpdate", _A.UpdateCurrentModifier)
    ----frame.modifier = (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")
    ----frame.edit = frame.drawer.scroll.edit
    ----frame.mainbar = {}
    ----frame.buttons = {}
    ----frame.offset = 1
    ----frame.stances = nil 
    ----if frame.class == "ROGUE" then
      ----write(frame, 'stances', push, _A.CreateStanceButton(frame, 73, 'ability_stealth', 1, 2, 3))
    ----elseif frame.class == "DRUID" then
      ----write(frame, 'stances', push, _A.CreateStanceButton(frame, 97,  'ability_racial_bearform',    1, 2, 3, 4))
      ----write(frame, 'stances', push, _A.CreateStanceButton(frame, 73,  'ability_druid_catform',      1, 2, 3, 4))
      ----write(frame, 'stances', push, _A.CreateStanceButton(frame, 109, 'spell_nature_forceofnature', 1))
    ----else
      ----_A.UpdateStanceButtons = nil
    ----end
    ----_A.CreateStanceButton = nil
    --return e:once(frame)
    ----return push(e, OnShow, _A.UpdateKeyboardLayout):once(frame, _A.DEFAULT_KEYBOARD_LAYOUT)
  --end)
--end


do
end

--do
  --listen("EDIT_BLOB", function(e, frame, binding)
    --frame.drawer:Show()
    --frame.edit:SetFocus()
    --return e:next(frame, binding)
  --end)
--end


--do
  --local function ChatEditInsertLinkHook(text)
    --if not text then return end
    --if ChatEdit_GetActiveWindow() then return end
    --if BrowseName and BrowseName:IsVisible() then return end
    --if MacroFrameText and MacroFrameText:IsVisible() then return end
    ----if BindPadMacroFrameText and BindPadMacroFrameText:IsVisible() then
    --print("OK", text)
    --local kind, id = select(3, string.find(text, "^|c%x+|H(%a+):(%d+)[|:]"))
    --if kind == "spell" then
      --text = GetSpellInfo(id)
    --elseif kind == "item" then
      --print("??", kind, id, text)
      --text = GetItemInfo(text)
    --end
    --local edit = frame.drawer.scroll.edit
    --if edit:GetText() == "" then
      --if kind == "item" then
        --if GetItemSpell(text) then
          --edit:Insert(SLASH_USE1.." "..text)
        --else
          --edit:Insert(SLASH_EQUIP1.." "..text)
        --end
      --elseif kind == "spell" then
        --edit:Insert(SLASH_CAST1.." "..text)
      --else
        --edit:Insert(text)
      --end
    --else
      --edit:Insert(text)
    --end
  --end
  --hooksecurefunc("ChatEdit_InsertLink", ChatEditInsertLinkHook);
--end


--do
  --local state = setmetatable({
  --}, STATE)
  --local OFF
  --local function ON(e, frame, ...)
    --print("ON")
    --listen("HIDE_STANCE_BUTTONS", OFF)
    --state(e, frame, ...)
    --return e:once(frame, ...)
  --end
  --function OFF(e, frame, ...)
    --print("OFF")
    --listen("SHOW_STANCE_BUTTONS", ON)
    --state(e, frame, ...)
    --return e:once(frame, ...)
  --end
  --listen("SHOW_STANCE_BUTTONS", ON)
--end

--local test = CreateFrame("frame", "shit", UIParent, "UIPanelDialogTemplate")
--test.numTabs = 2
--test:SetSize(500, 300)
--test:SetPoint("CENTER", 0, 0)

--local tabs = {}
--for i = 1, 2 do
  --local tab = CreateFrame("Button", "shitTab"..i, test, "CharacterFrameTabButtonTemplate")
  --tab:SetID(i)
  --tab:SetText("Tab"..i)
  --tab:SetPoint("TOPLEFT", test, "BOTTOMLEFT", (i-1) * 60, 8)
  --tab:SetScript("OnClick", function(self)
    --PanelTemplates_SetTab(self:GetParent(), self:GetID())
  --end)
  --table.insert(tabs, tab)
--end





----local page1, page2 = SetTabs(test, 2, "One", "Two")

--do
  --local function log(message)
    --return function(...)
      --print(message, ...)
    --end
  --end

  --listen("SHOW", setmetatable({
    --STATE.call, log("listen1"), log("release1"),
    --STATE.call, log("listen2"), log("release2"),
    --STATE.call, log("listen3"), log("release3"),
    --STATE.call, log("listen4"), log("release4"),
    --STATE.call, log("listen5"), log("release5"),
    --STATE.final,
    --function(self, e, frame)
      --listen("HIDE", self)
      --return e:once(frame)
    --end,
    --function(self, e, frame)
      --print("ok2")
      --return e:once(frame)
    --end
  --}, STATE))

  --C_Timer.NewTicker(1, function()
    --frame:dispatch("SHOW")
  --end, 2)
  --C_Timer.After(3, function()
    --frame:dispatch("HIDE")
  --end)
--end
  --do
    --local btn = CreateFrame("Button", "OBroBindsTestButton", nil, "SecureActionButtonTemplate")
    --btn:RegisterForClicks("AnyUp")
    --btn:SetAttribute("type", "macro")
    --btn:SetAttribute("macrotext", "/cast Fade")
    --SetOverrideBinding(frame, false, "7", "CLICK OBroBindsTestButton:LeftButton")
  --end
