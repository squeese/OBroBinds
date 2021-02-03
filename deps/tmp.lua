local arr = {}
local moist
local function hoist(self, event, ...)
  scope.push(arr, event)
  return scope.next(scope.shift(self, moist, event), ...)
end
function moist(self, event, ...)
  local result = table.remove(arr)
  print(event, result, event == result)
  return scope.next(scope.shift(self, hoist, event), ...)
end
function toist(self, fn, ...)
  fn()
  return scope.next(scope.shift(self, toist, fn), ...)
end

local test = setmetatable({
  hoist, "ONE",
  hoist, "TWO",
  toist, setmetatable({
    moist, "TWO",
    moist, "ONE",
  }, scope.STACK),
  hoist, "THREE",
  hoist, "FOUR",
}, scope.STACK)

print(">>", unpack(arr))
function scope.CLICK()
  test()
  print(">>", unpack(arr))
end

OBRO_emixin = CreateFromMixins(TemplatedListElementMixin)
OBRO_lmixin = CreateFromMixins(TemplatedListMixin)
function OBRO_lmixin:OnLoad()
  self:SetElementTemplate("OBRO_elem", self);
end

function OBRO_lmixin:CanInitialize()
  print("CanInitialize")
  return true
end

function OBRO_lmixin:InitializeList()
  print("InitializeList")
end

function OBRO_lmixin:GetNumElementFrames()
  print("GetNumElementFrames")
  return 4
end

function OBRO_lmixin:GetElementFrame(index)
  print("GetElementFrame")
end

function OBRO_lmixin:GetListOffset()
  print("GetListOffset")
end

function OBRO_lmixin:ResetDisplay()
  print("ResetDisplay")
end

OBRO_emixin = CreateFromMixins(TemplatedListElementMixin)

--do
--local function log(msg, ...)
  --print(msg, ...)
  --return ...
--end

--OLineMixin = {}

--function OLineMixin:InitElement(parent)
  --self.Text:SetText("hello")
  ----print("init", self, self:GetPoint())
  ----self.Text:SetText("adfasdfasdf")
  ----print("inint", self:GetSize())
  ----parent:SetSize(200, 400)
  ----print(parent:GetSize())
  ----self.bg = self:CreateTexture(nil, "BACKGROUND")
  ----self.bg:SetAllPoints()
  ----self.bg:SetColorTexture(1, 0.5, 0, 0.6)
  ----self:Show()
  ----self:SetSize(200, 50)
--end

--function OLineMixin:UpdateDisplay(...)
  --print("updatedisplay", self:GetPoint(), ...)
--end

--function OListMixin:InitializeList(...)
  --return log("InitializeList", ScrollListMixin.InitializeList(self, ...))
--end

--function OListMixin:GenNumElementFrames(...)
  --return log("GenNumElementFrames", ScrollListMixin.GenNumElementFrames(self, ...))
--end

--function OListMixin:GetElementFrame(...)
  --return log("GetElementFrame", ScrollListMixin.GetElementFrame(self, ...))
--end

--function OListMixin:GetListOffset(...)
  --return log("GetListOffset", ScrollListMixin.GetListOffset(self, ...))
--end

--function OListMixin:ResetDisplay(...)
  --return log("ResetDisplay", ScrollListMixin.ResetDisplay(self, ...))
--end

--function OListMixin:DisplayList(...)
  --return log("DisplayList", ScrollListMixin.DisplayList(self, ...))
--end
