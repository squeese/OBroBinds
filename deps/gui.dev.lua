local _, addon = ...
local subscribe, dispatch, dbRead, dbWrite, spread = addon:get("subscribe", "dispatch", "dbRead", "dbWrite", "spread")

-- GameMenuFrame

local prev
local function panel(frame, text, func)
  local button = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
  --local button = CreateFrame("button", nil, frame, "TabButtonTemplate")
  --button:SetSize(100, 32)
  --button.minWidth = 300
  button:SetText(text)
  button:RegisterForClicks("AnyUp")
  button:SetScript("OnClick", func)
  if not prev then
    button:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
  else
    button:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, 0)
  end
  prev = button
end




hooksecurefunc("ChatEdit_InsertLink", function(text)
    if not text then return end
    if ChatEdit_GetActiveWindow() then return end
    if BrowseName and BrowseName:IsVisible() then return end
    if MacroFrameText and MacroFrameText:IsVisible() then return end
    local _, _, kind, id = string.find(text, "^|c%x+|H(%a+):(%d+)[|:]");
    print("?", kind, id)


    --if BindPadMacroFrameText and BindPadMacroFrameText:IsVisible() then
        --local _, _, kind, spellid = string.find(text, "^|c%x+|H(%a+):(%d+)[|:]");

        --if kind == "item" then
            --text = GetItemInfo(text);
        --elseif kind == "spell" and spellid then
            --local name, rank = GetSpellInfo(spellid);
            --text = name;
        --end
        --if BindPadMacroFrameText:GetText() == "" then
            --if kind == "item" then
                --if GetItemSpell(text) then
                    --BindPadMacroFrameText:Insert(SLASH_USE1.." "..text);
                --else
                    --BindPadMacroFrameText:Insert(SLASH_EQUIP1.." "..text);
                --end
            --elseif kind == "spell" then
                --BindPadMacroFrameText:Insert(SLASH_CAST1.." "..text);
            --else
                --BindPadMacroFrameText:Insert(text);
            --end
        --else
            --BindPadMacroFrameText:Insert(text);
        --end
    --end
end)

do

  --local function bindingIsValid(binding)
    --local action = GetBindingAction(binding)
    --if not action or action == "" then return false end
    --local kind, info = string.match(action, actionPattern)
    --if kind == "SPELL" then
      --local id = select(7, GetSpellInfo(info))
      --return id ~= nil
    --elseif kind == "MACRO" then
      --return false
    --elseif kind == "ITEM" then
      --return false
    --end
  --end

  local actionPattern = "^(%w+) (.*)$"
  local function parseRemoteBinding(binding)
    local action = GetBindingAction(binding)
    if not action or action == "" then return nil end
    local kind, info = string.match(action, actionPattern)
    if kind == "SPELL" then
      local id = select(7, GetSpellInfo(info))
      if id then
        return 'spell', id
      end
      return nil
    elseif kind == "MACRO" then
      if GetMacroInfo(info) == info then
        return 'macro', info
      end
      return nil
    elseif kind == "ITEM" then
      return nil
    end
  end

  local function bindingSynced(spec, binding)
    local aKind, aId = spread(dbRead(nil, spec, binding))
    local bKind, bId = parseRemoteBinding(binding)
    print("??", binding, aKind, bKind, aId, bId)
    return aKind == bKind and aId == bId
  end

  local function optionImportFunc(self, button, binding)
    local kind, id = parseRemoteBinding(binding)
    dbWrite(nil, button:GetParent().spec, binding, { kind, id })
    --SetBinding(binding, nil)
    --SaveBindings(2)
  end

  local function optionCustomFunc(self, button, binding)
    --dbWrite(nil, button:GetParent().spec, binding, { 'blob', 'somename' })
  end

  local function optionRemoveFunc(self, button, binding)
    dbWrite(nil, button:GetParent().spec, binding, nil)
    SetBinding(binding, nil)
  end

  local dropdown, info
  subscribe("SHOW_DROPDOWN", function(event, button)
    if not dropdown then
      dropdown = CreateFrame("frame", nil, UIParent, "UIDropDownMenuTemplate")
      dropdown.displayMode = "MENU"
      info = UIDropDownMenu_CreateInfo()

      function dropdown:initialize()
        local frame = info.arg1:GetParent()
        local binding = frame.modifier..info.arg1.key
        local hasRemoteBinding = parseRemoteBinding(binding) ~= nil
        local hasLocalBinding = dbRead(nil, frame.spec, binding) ~= nil

        info.arg2 = binding
        info.text = binding
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info)

        info.text = "Binding:  " .. GetBindingAction(binding)
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info)

        info.text = "Override: " .. GetBindingAction(binding, true)
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info)

        --info.text = "Synced"
        --info.isTitle = true
        --info.isNotRadio = true
        --info.notCheckable = false
        --info.checked = bindingSynced(frame.spec, binding)
        --UIDropDownMenu_AddButton(info)

        if hasRemoteBinding and not bindingSynced(frame.spec, binding) then
          info.text = "Import"
          info.disabled = false
          info.isTitle = false
          info.notCheckable = true
          info.isNotRadio = false
          info.checked = false
          info.func = optionImportFunc
          UIDropDownMenu_AddButton(info)

          info.text = "Remove"
          info.isTitle = false
          info.func = nil
          UIDropDownMenu_AddButton(info)

        elseif not hasRemoteBinding and not hasRemoteBinding then
          info.text = "Custom macro"
          info.disabled = false
          info.isTitle = false
          info.notCheckable = true
          info.isNotRadio = false
          info.checked = false
          info.func = optionCustomFunc
          UIDropDownMenu_AddButton(info)
        end

        if hasLocalBinding then
          info.text = "Remove"
          info.disabled = false
          info.isTitle = false
          info.notCheckable = true
          info.isNotRadio = false
          info.checked = false
          info.func = optionRemoveFunc
          UIDropDownMenu_AddButton(info)
        end
      end
    end
    info.arg1 = button
    ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
    return event:next(button)
  end)
end

subscribe("PLAYER_LOGIN", function(event, frame, ...)
  if dbRead('GUI', 'open') then
    OBroBinds_Toggle()
  end
  return event:unsub():next(frame, ...)
end)
