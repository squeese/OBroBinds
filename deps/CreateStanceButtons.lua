local _, addon = ...
local next, _, _, _, _, subscribe, dispatch, unsubscribe = unpack(addon)

local function OnClick(self)
  dispatch("STANCE_OFFSET", self.Border:IsVisible() and 1 or self.__offset)
end

local function OnUpdate(self, offset)
  next(self.Border, self.__offset == offset and self.Border.Show or self.Border.Hide)
end

function addon:CreateStanceButtonsHandler(parent)
  -- this function will only ever run once to set up the stance buttons, if/when the main
  -- gui window is opened, it will return a handler that will update the buttons if the
  -- player has stance buttons and changes specc
  addon.CreateStanceButtonsHandler = nil

  local class = select(2, UnitClass("player"))
  if class == "ROGUE" then
    local button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
    button.__offset = 72
    button.icon:SetTexture("Interface/Icons/ability_stealth")
    button:SetPoint("TOPLEFT", 16, 34)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", OnClick)
    subscribe("STANCE_OFFSET", button, OnUpdate)
    return nil

  elseif class == "DRUID" then
    local buttons = {}
    local function CreateButton(index, offset, texture)
      local button = buttons[index]
      if not button then
        button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
        button.__offset = offset
        button.icon:SetTexture("Interface/Icons/"..texture)
        button:RegisterForClicks("AnyUp")
        button:SetScript("OnClick", OnClick)
        if index == 1 then
          button:SetPoint("TOPLEFT", 16, 34)
        else
          button:SetPoint("LEFT", buttons[index-1], "RIGHT", 4, 0)
        end
        buttons[index] = button
      end
      subscribe("STANCE_OFFSET", button, OnUpdate)
    end
    CreateButton(1, 97, 'ability_racial_bearform')
    CreateButton(2, 72, 'ability_druid_catform')
    return function()
      if GetSpecialization() == 1 then
        CreateButton(3, 109, 'spell_nature_forceofnature')
      elseif buttons[3] then
        if buttons[3].Border:IsVisible() then
          dispatch("STANCE_OFFSET", 1)
        end
        unsubscribe("STANCE_OFFSET", buttons[3])
        buttons[3]:Hide()
      end
    end

  else
    -- for all other classes that dont need stance buttons, we have no use to keep these references
    -- around anymore, not really a big deal, but why take up memory when it's not required
    next, subscribe, dispatch, unsubscribe, OnClick, OnUpdate = nil
  end
end
