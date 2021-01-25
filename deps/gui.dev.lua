local _, addon = ...
local subscribe, dispatch, dbWrite = addon:get("subscribe", "dispatch", "dbWrite")

-- GameMenuFrame

local prev
local function panel(frame, text, func)
  local button = CreateFrame("button", nil, frame, "UIPanelButtonTemplate")
  --local button = CreateFrame("button", nil, frame, "TabButtonTemplate")
  --button:SetSize(100, 32)
  --button.minWidth = 300
  button:SetText(text)
  --button.Text:SetText(text)
  button:RegisterForClicks("AnyUp")
  button:SetScript("OnClick", func)
  if not prev then
    button:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
  else
    button:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, 0)
  end
  prev = button
  --C_Timer.After(3, function()
    --print("ok")
    --PanelTemplates_TabResize(button, 0, nil, 300)
  --end)
end

subscribe("TOGGLE_GUI", function(event, frame)
  --panel(frame, "reset", function()
    --OBroBindsDB = nil
    --ReloadUI()
  --end)

  panel(frame, "reload", ReloadUI)

  panel(frame, "import", function(self, button)
    --while true do
      --local binding, action, kind, info = dispatch("IMPORT_BINDS", frame)
      --if not kind then break
      --elseif kind == "spell" then
        --local name, _, _, _, _, _, id = GetSpellInfo(info)
        --if id or name == info then
          --print(binding, kind, binding, info, name, id, "ADDED")
          --dbWrite(nil, frame.spec, binding, { kind, id })
        --else
          --print(binding, kind, binding, info, "SKIPPED")
        --end

      --elseif kind == "macro" then
        --local name = GetMacroInfo(info)
        --if name == info then
          --print(binding, kind, binding, info, "ADDED")
          --dbWrite(nil, frame.spec, binding, { kind, name })
        --else
          --print(binding, kind, binding, info, "SKIPPED")
        --end

      --elseif kind == "item" then
        --print(binding, kind, binding, info)
      --end
      --SetBinding(binding, nil)
    --end
    --print("save")
    --SaveBindings(2)
  end)

  return event:unsub():next(frame)
end)

subscribe("PLAYER_LOGIN", function(event, frame, ...)
  C_Timer.After(1, OBroBinds_Toggle)
  --dbWrite(nil, frame.spec, nil)
  return event:unsub():next(frame, ...)
end)
