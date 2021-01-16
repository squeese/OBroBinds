local _, addon = ...
local tinsert = table.insert

local function dbWrite(tbl, key, ...)
  if not tbl then
    return dbWrite({}, key, ...)
  elseif type(key) == 'function' then
    tbl = key(tbl, ...)
  elseif select("#", ...) > 1 then
    tbl[key] = dbWrite(tbl[key], ...)
  else
    tbl[key] = select(1, ...)
  end
  if tbl then
    for _ in pairs(tbl) do
      return tbl
    end
  end
  return nil
end
tinsert(addon, dbWrite)

function dbRead(tbl, key, ...)
  if not tbl then return nil end
  if not key then return tbl end
  return dbRead(tbl[key], ...)
end

tinsert(addon, dbRead)
