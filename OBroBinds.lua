local _, addon = ...
local next = unpack(addon)
local InitializeGUI, UpdateStanceButtons, UpdateActionButtons

BINDING_HEADER_OBROBINDS = 'OBroBinds'
BINDING_NAME_TOGGLE_CONFIG = 'Toggle Config Panel'
function OBroBinds_Toggle()
  local root = InitializeGUI()
  local open = false
  OBroBinds_Toggle = function()
    if not open then
      root:Show()
      -- next(addon, addon.UpdateStanceButtons)
      -- next(addon, addon.UpdateActionButtons, addon.DEFAULT_KEYBOARD_LAYOUT)
      -- next(frame, frame.UpdateStanceButtonsLayout)
      -- next(frame, frame.UpdateActionButtonsLayout, addon.DEFAULT_KEYBOARD_LAYOUT)
      -- dispatch("MODIFIER_CHANGED", GetModifier())
    else
      root:Hide()
    end
    open = not open
  end
  OBroBinds_Toggle()
end


do -- TMP, open on loading
  local frame = CreateFrame("frame")
  frame:RegisterEvent("VARIABLES_LOADED")
  frame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("VARIABLES_LOADED")
    self:SetScript("OnEvent", nil)
    print("click toggle")
    OBroBinds_Toggle()
  end)
end

function InitializeGUI()
  local subscribe, dispatch, unsubscribe = select(6, unpack(addon))

  -- create and style the main window
  local frame = CreateFrame("frame", nil, UIParent, "BackdropTemplate")
  frame:SetFrameStrata("DIALOG")
  frame:SetSize(750, 290)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 32)
  frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })


  -- create the stance buttons and an update handler for when the player changes specc
  do
    local function OnStanceButtonClick(self)
      dispatch("STANCE_OFFSET", self.Border:IsVisible() and 1 or self.__offset)
    end
    local function OnStanceButtonUpdate(self, offset)
      next(self.Border, self.__offset == offset and self.Border.Show or self.Border.Hide)
    end
    local function CreateStanceButton(offset, texture, anchor)
      local button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
      button.__offset = offset
      button.icon:SetTexture("Interface/Icons/"..texture)
      button:SetPoint("TOPLEFT", 16, 34)
      button:RegisterForClicks("AnyUp")
      button:SetScript("OnClick", OnStanceButtonClick)
      subscribe("STANCE_OFFSET", button, OnStanceButtonUpdate)
      if anchor then
        button:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
      else
        button:SetPoint("TOPLEFT", 16, 34)
      end
      return button
    end

    local class = select(2, UnitClass("player"))
    if class == "ROGUE" then
      CreateStanceButton(72, "ability_stealth", nil)

    elseif class == "DRUID" then
      local stanceButtonBear = CreateStanceButton(97, 'ability_racial_bearform', nil)
      local stanceButtonCat = CreateStanceButton(72, 'ability_druid_catform', stanceButtonBear)
      local stanceButtonBoom = nil
      function UpdateStanceButtons()
        if GetSpecialization() == 1 then
          stanceButtonBoom = stanceButtonBoom or CreateStanceButton(109, 'spell_nature_forceofnature', stanceButtonCat)
          if not stanceButtonBoom:IsVisible() then
            stanceButtonBoom:Show()
            subscribe("STANCE_OFFSET", stanceButtonBoom, OnStanceButtonUpdate)
          end
        elseif stanceButtonBoom then
          if stanceButtonBoom.Border:IsVisible() then
            dispatch("STANCE_OFFSET", 1)
          end
          unsubscribe("STANCE_OFFSET", stanceButtonBoom)
          stanceButtonBoom:Hide()
        end
      end
    end
  end

  -- create the action buttons
  --[[
  do
    local current, buttons
    self.UpdateActionButtons = function(self, layout)
      if current == layout then return end
      current = layout
      buttons = next(buttons or {}, init, frame, rcat, layout, cleanup)
    end
  end
  ]]

  -- remove refence to this function and let the GC collect it, since it's only run once
  InitializeGUI = nil

  return frame
end




--[[
do
  local elapsed
  local function OnUpdate(self, delta)
    elapsed = elapsed + delta
    if elapsed > 0.15 then
      self:SetScript("OnUpdate", nil)
      if self:IsVisible() then
        next(frame, frame.UpdateActionButtonsLayout)
      end
    end
  end
  frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
  frame:SetScript("OnEvent", function(self)
    elapsed = 0
    self:SetScript("OnUpdate", OnUpdate)
  end)
end
]]


--[[
  do
  local StanceButtons = {}
  local prevSpec = nil

  local function Create(index)
		local button = buttons[index]
    if button then return button end
      button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
      button:RegisterForClicks("AnyUp")
      button:SetScript("OnClick", ClickStanceButton)
      buttons[index] = button
    end
    -- button:Show()
    -- button.icon:SetTexture("Interface/Icons/" .. texture)
		-- button.offset = offset
    -- Subscribe(button, "STANCE_CHANGED", UpdateStanceButton)
		if index == 1 then
			button:SetPoint("TOPLEFT", 16, 34)
		else
			button:SetPoint("LEFT", buttons[index-1], "RIGHT", 4, 0)
    end
  end

  local function Reset(button)
    button:Hide()
    button.Border:Hide()
    -- Unsubscribe(buttons[i], "STANCE_CHANGED")
  end

  local function Stances(class, spec)
    if class == "ROGUE" then
      Dispatch("STANCE", 72, 'ability_stealth')
		elseif class == "DRUID" then
			Dispatch("STANCE", 97, 'ability_racial_bearform')
      Dispatch("STANCE", 72, 'ability_druid_catform')
      if spec == 1 then -- boomkin
        Dispatch("STANCE", 109, 'spell_nature_forceofnature')
      end
    end
  end

  local function Update(self)
    local nextSpec = GetSpecialization()
    if prevSpec == nextSpec then return end
    map(Reset, unpack(StanceButtons))
    -- next(s, fn, ...)


    print("UpdateSpec", spec)
  end

  Subscribe("TOGGLE", StanceButtons, function(self, visibility)
    if visibility == "Show" then
      print("toggle", self, visibility)
      Subscribe("SPECIALIZATION", self, Update)
    else
      Unsubscribe("SPECIALIZATION", self)
    end
  end)

  Subscribe("SPECIALIZATON", StanceButtons, function(self, visibility)

    print("UpdateStanceButtons", self)
    if self.__spec == spec then return end
    self.__spec = spec
    if buttons then
      for i = 1, #buttons do
        buttons[i]:Hide()
        buttons[i].Border:Hide()
        Unsubscribe(buttons[i], "STANCE_CHANGED")
      end
    end
		if self.__class == "ROGUE" then
			ShowStanceButton(1, 72, 'ability_stealth')
		elseif self.__class == "DRUID" then
			ShowStanceButton(1, 97, 'ability_racial_bearform')
      ShowStanceButton(2, 72, 'ability_druid_catform')
      if spec == 1 then -- boomkin
        ShowStanceButton(3, 109, 'spell_nature_forceofnature')
      end
    end
  end)
end
  ]]


--[[
do
  local anchor = nil
  local function ClickStanceButton(self)
    if not self.Border:IsVisible() then
      Dispatch("STANCE_CHANGED", self.offset)
    else
      Dispatch("STANCE_CHANGED", 1)
    end
  end
  local function UpdateStanceButton(self, offset)
    if self.offset == offset then
      self.Border:Show()
    else
      self.Border:Hide()
    end
  end
  local buttons = nil
  local function ShowStanceButton(index, offset, texture)
    if not buttons then
      buttons = {}
    end
		local button = buttons[index]
    if not button then
      button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
      button:RegisterForClicks("AnyUp")
      button:SetScript("OnClick", ClickStanceButton)
      buttons[index] = button
    end
    button:Show()
    button.icon:SetTexture("Interface/Icons/" .. texture)
		button.offset = offset
    Subscribe(button, "STANCE_CHANGED", UpdateStanceButton)
		if index == 1 then
			button:SetPoint("TOPLEFT", 16, 34)
		else
			button:SetPoint("LEFT", buttons[index-1], "RIGHT", 4, 0)
    end
  end
  function frame:UpdateStanceBar()
    local spec = GetSpecialization()
    if self.__spec == spec then return end
    self.__spec = spec
    if buttons then
      for i = 1, #buttons do
        buttons[i]:Hide()
        buttons[i].Border:Hide()
        Unsubscribe(buttons[i], "STANCE_CHANGED")
      end
    end
		if self.__class == "ROGUE" then
			ShowStanceButton(1, 72, 'ability_stealth')
		elseif self.__class == "DRUID" then
			ShowStanceButton(1, 97, 'ability_racial_bearform')
      ShowStanceButton(2, 72, 'ability_druid_catform')
      if spec == 1 then -- boomkin
        ShowStanceButton(3, 109, 'spell_nature_forceofnature')
      end
    end
	end
end




local function TMP_ON_DRAG_END(self, button)
  local kind, arg1, _, arg2, arg3 = GetCursorInfo()
  ClearCursor()
  if kind == 'spell' then
    self.icon:SetTexture(select(3, GetSpellInfo(arg3 or arg2)))
    OBroBindsDB = DBWrite(OBroBindsDB, frame.__class, self.key, GetCurrentModifier(), { kind, arg3 or arg2 })
  elseif kind == 'macro' then
    self.icon:SetTexture(select(2, GetMacroInfo(arg1)))
    OBroBindsDB = DBWrite(OBroBindsDB, frame.__class, self.key, GetCurrentModifier(), { kind, arg1 })
  elseif kind == 'item' then
    self.icon:SetTexture(select(10, GetItemInfo(self.id)))
    OBroBindsDB = DBWrite(OBroBindsDB, frame.__class, self.key, GetCurrentModifier(), { kind, arg1 })
  end
end

local function TMP_ON_DRAG_START(self)
  local modifier = GetCurrentModifier()
  local kind, id = unpack(DBRead(OBroBindsDB, frame.__class, self.key, modifier) or {})
  if kind == 'spell' then
    PickupSpell(id)
  elseif kind == 'macro' then
    PickupMacro(id)
  elseif kind == 'item' then
    PickupItem(id)
  end
  OBroBindsDB = DBWrite(OBroBindsDB, frame.__class, self.key, modifier, nil)
  self.icon:SetTexture(nil)
end

local function TMP_TOGGLE_MAINBAR_BUTTON(self)
  print("toggle", self)
end

local function TMP_ON_CLICK(self, button)
  if button == "RightButton" then
    TMP_TOGGLE_MAINBAR_BUTTON(self)
  else
    TMP_ON_DRAG_END(self)
  end
end

do
  local EMPTY = {}
  local function TMP_UPDATE_BUTTON_ICON(self)
    local kind, id = unpack(DBRead(OBroBindsDB, frame.__class, self.key, GetCurrentModifier()) or EMPTY)
    if kind == 'spell' then
      self.icon:SetTexture(select(3, GetSpellInfo(id)))
    elseif kind == 'macro' then
      self.icon:SetTexture(select(2, GetMacroInfo(id)))
    elseif kind == 'item' then
      self.icon:SetTexture(select(10, GetItemInfo(id)))
    else
      self.icon:SetTexture(nil)
    end
  end

  local function TMP_CREATE_BUTTON(x, y, key)
    local button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
    button.key = key
    button.HotKey:SetText(key)
    button:SetPoint("TOPLEFT", x, y)
    button:SetScript("OnDragStart", TMP_ON_DRAG_START)
    button:SetScript("OnReceiveDrag", TMP_ON_DRAG_END)
    button:SetScript("OnClick", TMP_ON_CLICK)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("AnyUp")
    Subscribe(button, "BUTTON_UPDATE_ICON", TMP_UPDATE_BUTTON_ICON)
  end
  local function TMP_PARSE_LAYOUT(...)
    local length = select("#", ...)
    for i = 1, length, 3 do
      local x, y, keystring = select(i, ...)
      -- print("row", x, y)
      local offset = 0
      for key in string.gmatch(keystring, "[^ ]+") do
        -- print("?", offset, key)
        TMP_CREATE_BUTTON(16 + x + offset * (32 + 8), y - 16, key)
        offset = offset + 1
      end
    end
  end
  TMP_PARSE_LAYOUT(unpack({
    0,   0,    "F1 F2 F3 F4", -- F5 F6 F7 F8 F9 F10 F11 F12",
    --0,   -50,  "` 1 2 3 4 5 6 7 8 9 0 - =",
    --60,  -90,  "q w e r t y u i o p [ ]",
    -- 80,  -130, "a s d f g h j k l ; '",
    -- 50,  -170, "\\ z x c v b n m , . /",
    -- 570, 0,    "INSERT HOME PAGEUP",
    -- 570, -40,  "DELETE END PAGEDOWN",
    -- 610, -90,  "MOUSEWHEELUP",
    -- 610, -130, "BUTTON3",
    -- 610, -170, "MOUSEWHEELDOWN",
  }))
end
]]



--[[
local CreateStanceButtonLayoutHandler
do
  local function OnClickStanceButton(self)
    Dispatch("STANCE_OFFSET", self.Border:IsVisible() and 1 or self.__offset)
  end
  local function OnUpdateStanceButton(self, offset)
    call(self.Border, self.__offset == offset and "Show" or "Hide")
  end

  function CreateStanceButtonLayoutHandler()
    local class = select(2, UnitClass("player"))
    if class == "ROGUE" then
      local button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
      button.icon:SetTexture("Interface/Icons/ability_stealth")
      button:SetPoint("TOPLEFT", 16, 34)
      button:RegisterForClicks("AnyUp")
      button:SetScript("OnClick", OnClickStanceButton)
      Subscribe("STANCE_OFFSET", button, OnUpdateStanceButton)
      button.__offset = 72

    elseif class == "DRUID" then
      local buttons = {}
      local function CreateButton(index, offset, texture)
        local button = buttons[index]
        if not button then
          button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
          button.icon:SetTexture("Interface/Icons/"..texture)
          button:RegisterForClicks("AnyUp")
          button:SetScript("OnClick", OnClickStanceButton)
          button.__offset = offset
          if index == 1 then
            button:SetPoint("TOPLEFT", 16, 34)
          else
            button:SetPoint("LEFT", buttons[index-1], "RIGHT", 4, 0)
          end
          buttons[index] = button
        end
        Subscribe("STANCE_OFFSET", button, OnUpdateStanceButton)
      end
      CreateButton(1, 97, 'ability_racial_bearform')
      CreateButton(2, 72, 'ability_druid_catform')
      return function(...)
        if GetSpecialization() == 1 then
          CreateButton(3, 109, 'spell_nature_forceofnature')
        elseif buttons[3] then
          if buttons[3].Border:IsVisible() then
            Dispatch("STANCE_OFFSET", 1)
          end
          Unsubscribe("STANCE_OFFSET", buttons[3])
          buttons[3]:Hide()
        end
      end
    else
      OnClickStanceButton = nil
      OnUpdateStanceButton = nil
    end
    CreateStanceButtonLayoutHandler = nil
  end
end
]]
