local _, addon = ...
local next, _, _, _, _, subscribe, dispatch, _, _, _, dbWrite, _, _, _ = unpack(addon)

      --local offsets = {1}
      --local a, b, c = dispatch("GET_STANCES", function(buttons)
        --for _, button in ipairs(buttons) do
          --if button:IsVisible() then
            --table.insert(offsets, button.offset)
          --end
        --end
      --end)

      --for i = 1, 12 do
        --local binding = GetBindingKey("ACTIONBUTTON"..i)
        --if binding then
          --dbWrite(nil, "mainbar", binding, i)
          --for _, offset in ipairs(offsets) do
            --local num = (offset + i - 1)
            --local kind, id = GetActionInfo(num)
            --if not kind then
            --elseif kind == "spell" then
              --dbWrite(nil, "offsets", num, { SPELL, id })
            --elseif kind == "macro" then
              --local name = GetMacroInfo(id)
              --dbWrite(nil, "offsets", num, { MACRO, name })
            --elseif kind == "item" then
              --dbWrite(nil, "offsets", num, { ITEM, id })
            --end
          --end
        --end
      --end
      --
