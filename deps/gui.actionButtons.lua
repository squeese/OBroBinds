local _, addon = ...
local next, _, rpush, clean, _, subscribe, dispatch, unsubscribe, write, read, dbWrite, dbRead, getModifier, match = unpack(addon)
local tinsert = table.insert
local tremove = table.remove
local mmax = math.max
local mmin = math.min
local SPELL, MACRO, ITEM = 1, 2, 3

local function increment(value)
  return type(value) == 'number' and (value + 1) or 1
end

subscribe("INITIALIZE", function(self, parent)
  local function OnActionButtonDragStart(self)
  end

  local function OnActionButtonReceiveDrag(self)
    local kind, id, _, arg1, arg2 = GetCursorInfo()
    print(kind, id, arg1, arg2)
    ClearCursor()
    if kind == "spell" then
      --dispatch("CREATE_BINDING", { self.key, getModifier(), self.offset, SPELL, arg2 or arg1 })
    elseif kind == "macro" then
      -- dispatch("CREATE_BINDING", { self.key, getModifier(), self.offset, MACRO, id })
    elseif kind == "item" then
      -- dispatch("CREATE_BINDING", { self.key, getModifier(), self.offset, ITEM, id })
    elseif kind then
      assert(false, 'uncatched type: '..kind)
    end
  end

  local function OnActionButtonClick(self, button)
    if button == "RightButton" then
    elseif button == "LeftButton" then
    end
  end

  local function OnActionButtonUpdate(self, modifier)
    --local binding = modifier..self.key
    --local index = dbRead(nil, "mainbar", binding)
    --if index then
      --self.Border:Show()
      --self.Border:SetAlpha(1.0)
      --self.Name:SetText(index)
    --else
      --self.Border:Hide()
    --end
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
      button.Update = OnActionButtonUpdate
      tinsert(self, button)
    else
      button = self[self.index]
    end
    self['key__'..key] = button
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
  end

  subscribe("LAYOUT_CHANGED", self, function(_, layout)
    if self.layout == layout then return end
    self.layout = layout
    self.index = 0 -- index of the next button to use
    self.size = 40 -- size of the button
    self.x, self.xmin, self.xmax = 0, UIParent:GetRight(), UIParent:GetLeft()
    self.y, self.ymin, self.ymax = 0, UIParent:GetTop(), UIParent:GetBottom()
    self.CreateActionButton = CreateActionButton
    next(self, unpack(layout))

    local width = self.xmax - self.xmin + 32
    local height = self.ymax - self.ymin + 32
    parent:SetSize(width, height)

    self.size, self.x, self.y, self.xmin, self.xmax, self.ymin, self.ymax = nil
    for i = self.index+1, #self do
      local button = self[i]
      button:Hide()
    end

    local regex = "[.*-]?([^-]*.)$"
    for index = 1, 12 do
      local binding = GetBindingKey("ACTIONBUTTON"..index)
      if binding then
        local key = string.match(binding, regex)
        local button = self['key__'..key]
        write(button, 'bindings', increment)
        write(button, binding, index)

        --OnActionButtonUpdate(button)
        button.Border:Show()
        --button.HotKey:SetText(red(button, 'bindings'))
        button.Name:SetText(read(button, binding))
      end
    end
    local bindings = dbRead(nil, GetSpecialization(), 'bindings')
    if bindings then
      for binding in pairs(bindings) do
        local key = string.match(binding, regex)
        --print("ACTION_BINDING", key, binding)
        --write(self['key__'..key], 'binds', increment)
      end
    end
  end)

  do
    --local regex = "^([^%d ]+)(%d?)%s?(.*)$"
    local regex = "^(%w+) (.*)$"
    local mods = {"", "ALT-", "CTRL-", "SHIFT-", "ALT-CTRL-", "ALT-SHIFT-", "ALT-CTRL-SHIFT-", "CTRL-SHIFT-"}
    subscribe("SCAN", self, function()
      OBroBindsDB = nil
      local spec = GetSpecialization()
      for i = 1, self.index do
        local button = self[i]
        for _, modifier in ipairs(mods) do
          local binding = modifier..button.key
          local action = GetBindingAction(binding)
          local kind, info = string.match(action, regex)
          if not kind then
          elseif kind == "SPELL" then
            local name, _, icon, _, _, _, id = GetSpellInfo(info)
            if name == info then
              dbWrite(nil, spec, 'bindings', binding, { SPELL, id, name = name })
            end
          elseif kind == "MACRO" then
            local name, icon = GetMacroInfo(info)
            if name == info then
              dbWrite(nil, spec, 'bindings', binding, { MACRO, name })
            end
          elseif kind == "ITEM" then
          end
        end
      end
      ReloadUI()
    end)
  end

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
    self:CreateActionButton(key)
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
