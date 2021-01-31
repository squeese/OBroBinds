local scope = select(2, ...)


  --local function dbRead(self, ...)
    --return read(OBroBindsDB, ...)
  --end
  --local function dbWrite(self, ...)
    --OBroBindsDB = write(OBroBindsDB, ...)
  --end
  --local function dbGetOverride(self, binding)
    --return setmetatable(read(OBroBindsDB, self.class, self.spec, binding) or empty, OVERRIDE)
  --end
  --local function dbDeleteOverride(self, binding)
    --OBroBindsDB = write(OBroBindsDB, self.class, self.spec, binding, nil)
  --end
  --local function iter(...)
    --local binding, override = next(...)
    --return binding, setmetatable(override or empty, OVERRIDE)
  --end
  --local function dbMapOverrides(self)
    --return iter, read(OBroBindsDB, self.class, self.spec) or empty, nil
  --end
