local _, addon = ...
local next, _, rpush, clean, _, subscribe, dispatch, unsubscribe, write, read, dbWrite, dbRead, getModifier, match = unpack(addon)
local tinsert = table.insert
local tremove = table.remove
local mmax = math.max
local mmin = math.min
local SPELL, MACRO, ITEM = 1, 2, 3

local tmp = {}
local function CreateBinding(key)
  if IsAltKeyDown() then rpush(tmp, "ALT") end
  if IsControlKeyDown() then rpush(tmp, "CTRL") end
  if IsShiftKeyDown() then rpush(tmp, "SHIFT") end
  rpush(tmp, key)
  local binding = strjoin("-", unpack(tmp))
  next(tmp, clean, tmp)
  return binding
end

local regex = "[.*-]?([^-]*.)$"
local function GetKeyFromBinding(binding)
  return string.match(binding, regex)
end

--local function increment(value)
  --return type(value) == 'number' and (value + 1) or 1
--end

--local function decrement(value)
  --if type(value) == 'number' and value > 1 then
    --return value - 1
  --end
--end

subscribe("INITIALIZE", function(self, parent)

  local function OnActionButtonDragStart(self)
  end

  local function OnActionButtonReceiveDrag(self)
    local kind, id, _, arg1, arg2 = GetCursorInfo()
    ClearCursor()
    if kind == "spell" then
      dispatch("CREATE_BINDING", { self.key, getModifier(), self.offset, SPELL, arg2 or arg1 })
    elseif kind == "macro" then
      dispatch("CREATE_BINDING", { self.key, getModifier(), self.offset, MACRO, id })
    elseif kind == "item" then
      dispatch("CREATE_BINDING", { self.key, getModifier(), self.offset, ITEM, id })
    elseif kind then
      assert(false, 'uncatched type: '..kind)
    end
  end

  local function OnActionButtonClick(self, button)
    if button == "RightButton" then
      local binding = CreateBinding(self.key)
      print("?", self.key, binding)
    elseif button == "LeftButton" then
    end
  end

  local function OnActionButtonUpdate(self)
  end

  local function CreateActionButton(self, key)
    self.index = self.index + 1
    local button
    if self.index > #self then
      button = CreateFrame("button", nil, parent, "ActionButtonTemplate")
      button:SetScript("OnDragStart", OnActionButtonDragStart)
      button:SetScript("OnReceiveDrag", OnActionButtonReceiveDrag)
      button:SetScript("OnClick", OnActionButtonClick)
      button:RegisterForDrag("LeftButton")
      button:RegisterForClicks("AnyUp")
      --button.MODIFIER_CHANGED = OnModifierChanged
      --button.OFFSET_CHANGED = OnOffsetChanged
      --button.ORDER_CHANGED = OnOrderChanged
      button.Update = OnActionButtonUpdate
      tinsert(self, button)
    else
      button = self[self.index]
    end
    button.key = key
    button:SetPoint("TOPLEFT", 16 + self.x, -self.y - 16)
    button.Border:Hide()
    button.Border:SetAlpha(1)
    button.HotKey:SetText(key)
    button.Name:SetText()
    self.xmin = mmin(self.xmin, button:GetLeft())
    self.xmax = mmax(self.xmax, button:GetRight())
    self.ymin = mmin(self.ymin, button:GetBottom())
    self.ymax = mmax(self.ymax, button:GetTop())

    subscribe("STANCE_BUTTON_APPEND", button, function(self, key, binding, index)
      if key == self.key then
        print("STANCE_BUTTON_APPEND", self.key, "//", key, binding, index)
      end
    end)

    subscribe("MODIFIER_CHANGED", button, function(self, modifier)
      --local binding = modifier and (modifier.."-"..self.key) or self.key
      --local action = GetBindingAction(binding)
      --if action:match("^SPELL") then
        --local spell = strsub(action, 7)
        --print(binding, action, spell, GetSpellInfo(spell))
      --end
      ----local spell = GetBindingSpell(binding)
      ---- print(binding, action)
    end)

  end

  subscribe("LAYOUT_CHANGED", self, function(_, layout)
    if self.layout == layout then return end
    self.layout = layout
    self.index = 0 -- index of the next button to use
    self.size = 40 -- size of the button
    self.x, self.xmin, self.xmax = 0, UIParent:GetRight(), UIParent:GetLeft()
    self.y, self.ymin, self.ymax = 0, UIParent:GetTop(), UIParent:GetBottom()
    self.modifier = getModifier()
    subscribe("CREATE_ACTION_BUTTON", self, CreateActionButton)
    next(self, unpack(layout))
    unsubscribe("CREATE_ACTION_BUTTON", self)
    local width = self.xmax - self.xmin + 32
    local height = self.ymax - self.ymin + 32
    parent:SetSize(width, height)
    self.size, self.x, self.y, self.xmin, self.xmax, self.ymin, self.ymax, self.modifier = nil
    for i = self.index+1, #self do
      local button = self[i]
      button:Hide()
      -- unsubscribe("MODIFIER_CHANGED", button)
      -- unsubscribe("OFFSET_CHANGED", button)
    end

    C_Timer.After(1, function()
      OBroBindsDB = nil
      --dbWrite(nil, 'stance', rpush, "SHIFT-1", "1", "2", "CTRL-3")
      --dbWrite(nil, 'binding', rpush, { "5", SPELL, 123 })
      --dbWrite(nil, 'binding', rpush, { "8", SPELL, 234 })
      --dbWrite(nil, 'binding', rpush, { "ALT-5", SPELL, 456 })
      --local stance = dbRead(nil, 'stance')
      --for index, binding in ipairs(stance) do
        --dispatch("STANCE_BUTTON_APPEND", GetKeyFromBinding(binding), binding, index)
      --end
      --local bindings = dbRead(nil, 'bindings')
      --for index, binding in ipairs(stance) do
        ---- dispatch("BINDING", )
      --end

      --local action = GetBindingAction(binding)
      --if action:match("^SPELL") then
        --local spell = strsub(action, 7)
        --print(binding, action, spell, GetSpellInfo(spell))
      --end
      ----local spell = GetBindingSpell(binding)
      ---- print(binding, action)

      for i = 1, GetNumBindings() do
        -- print(i, GetBindInfo(i))
        -- print(">", i, GetBinding(i))
      end
    end)
  end)
  unsubscribe("INITIALIZE", self, true)
end)


local function colSet(self, x, ...)
  self.x = mmax(0, self.size * x)
  return next(self, ...)
end
tinsert(addon, colSet)

local function colAdd(self, x, ...)
  self.x = mmax(0, self.x + self.size * x)
  return next(self, ...)
end
tinsert(addon, colAdd)

local function rowSet(self, y, ...)
  self.y = mmax(0, self.size * y)
  return next(self, ...)
end
tinsert(addon, rowSet)

local function rowAdd(self, y, ...)
  self.y = mmax(0, self.y + self.size * y)
  return next(self, ...)
end
tinsert(addon, rowAdd)

do
  local function button(self, key, ...)
    dispatch("CREATE_ACTION_BUTTON", key)
    return next(self, ...)
  end
  tinsert(addon, button)

  do
    local __tmp = {}
    local function buttonRow(self, motion, amount, keys, ...)
      for key in string.gmatch(keys, "[^ ]+") do
        rpush(__tmp, button, strupper(key), motion or colAdd, amount or 1)
      end
      rpush(__tmp, ...)
      return next(self, clean, __tmp, unpack(__tmp))
    end
    tinsert(addon, buttonRow)
  end
end
