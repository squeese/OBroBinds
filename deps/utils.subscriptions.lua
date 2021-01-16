local _, addon = ...
local _, next = unpack(addon)
local tinsert = table.insert
local tremove = table.remove
local subscriptions = {}

local function subscribe(key, tbl, func)
  tbl[key] = func or tbl[key] or next
  if not subscriptions[key] then
    subscriptions[key] = {}
  end
  local subs = subscriptions[key]
  for i = 1, #subs do
    if tbl == subs[i] then return end
  end
  tinsert(subs, 1, tbl)
end
print("?", subscribe)
tinsert(addon, subscribe)

local function dispatch(key, ...)
  print("dispatch", key, ...)
  local subs = subscriptions[key]
  if not subs then return end
  for i = #subs, 1, -1 do
    local tbl = subs[i]
    next(tbl, tbl[key], ...)
  end
end
print("!", dispatch)
tinsert(addon, dispatch)

local function unsubscribe(key, tbl)
  local subs = subscriptions[key]
  if not subs then return end
  for i = #subs, 1, -1 do
    if subs[i] == tbl then
      tremove(subs, i)
      return
    end
  end
end
tinsert(addon, unsubscribe)