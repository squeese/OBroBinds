local _, addon = ...
local _, next, _, _, _, rcat, _, _, _, _, _, init, cleanup = unpack(addon)

function addon:CreateActionButtonsHandler(parent)
  addon.CreateActionButtonsHandler = nil
  local current
  local buttons = nil
  return function(self, layout)
    if buttons and current == layout then return end
    current = layout
    buttons = next(buttons or {}, init, parent, rcat, layout, cleanup)
  end
end

--[[
local function TMP_PARSE_LAYOUT(...)
  local length = select("#", ...)
  for i = 1, length, 3 do
    local x, y, keystring = select(i, ...)
    local offset = 0
    for key in string.gmatch(keystring, "[^ ]+") do
      local button = CreateFrame("button", nil, frame, "ActionButtonTemplate")
      button.key = key
      button.HotKey:SetText(key)
      button:SetPoint("TOPLEFT", 16 + x + offset * (32 + 8), y - 16)
      button:SetScript("OnDragStart", TMP_ON_DRAG_START)
      button:SetScript("OnReceiveDrag", TMP_ON_DRAG_END)
      button:SetScript("OnClick", TMP_ON_CLICK)
      button:RegisterForDrag("LeftButton")
      button:RegisterForClicks("AnyUp")
      Subscribe(button, "BUTTON_UPDATE_ICON", TMP_UPDATE_BUTTON_ICON)
      offset = offset + 1
    end
  end
end

local function init(self, parent, ...)
  self.__cursor, self.__parent, self.__size, self.__x, self.__y, self.__w, self.__h = 0, parent, 40, 0, 0, 0, 0
  return next(self, ...)
end

local function cleanup(self, ...)
  print("cleanup")
  self.__parent, self.__size, self.__x, self.__y, self.__w, self.__h = nil
  for i = self.__cursor+1, #self do
    print("cleanup")
  end
  return next(self, ...)
end
]]