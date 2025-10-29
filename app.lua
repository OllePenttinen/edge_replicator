json = require("json")
edge = require("edge")
lynx = require("edge.lynx")
log  = require("log")

local cfg = cfg or {}
local destination = cfg.destination_installation
local patterns = cfg.function_patterns or {}

local function wildcard_to_pattern(w)
  local p = w:gsub("([%%%^%$%(%)%.%[%]%+%-%?])", "%%%1")
  p = p:gsub("%%%*", ".*")
  p = p:gsub("%%%?", ".")
  return "^" .. p .. "$"
end 

local compiled_patterns = {}
for _, pat in ipairs(patterns) do
  table.insert(compiled_patterns, wildcard_to_pattern(pat))
  log.info("EdgeApp", "Watching pattern: %s", pat)
end

local function matches_pattern(func_name)
  for _, p in ipairs(compiled_patterns) do
    if func_name:match(p) then return true end
  end
  return false
end

local function copy_function_to_destination(fn)
  if not destination then
    log.error("EdgeApp", "Destination installation not configured")
    return
  end

  local url = string.format("/api/v2/installation/%s/functions/%s", destination, fn.id)
  local payload = {
    value = fn.value,
    name = fn.name,
    type = fn.type,
    meta = fn.meta
  }

  log.info("EdgeApp", "Copying function %s (value=%s) to %s", fn.name, tostring(fn.value), destination)
  local res, code, err = lynx.apiCall("PUT", url, payload)
  if code and code >= 200 and code < 300 then
    log.info("EdgeApp", "Successfully updated function %s on %s", fn.name, destination)
  else
    log.error("EdgeApp", "Failed to copy function %s: %s (%s)", fn.name, tostring(err), tostring(code))
  end
end

local function delete_function_from_destination(fn)
  if not destination then
    log.error("EdgeApp", "Destination installation not configured")
    return
  end

  local url = string.format("/api/v2/installation/%s/functions/%s", destination, fn.id)
  log.info("EdgeApp", "Deleting function %s from %s", fn.name, destination)
  local _, code, err = lynx.apiCall("DELETE", url)
  if code and code >= 200 and code < 300 then
    log.info("EdgeApp", "Function %s removed from %s", fn.name, destination)
  else
    log.error("EdgeApp", "Failed to delete %s: %s (%s)", fn.name, tostring(err), tostring(code))
  end
end

local function onFunctionValueUpdated(f)
  if not f or not f.name then return end
  if not matches_pattern(f.name) then return end

  log.info("EdgeApp", "Function %s updated -> %s", f.name, tostring(f.value))
  local numval = tonumber(f.value) or 0
  if numval > 0 then
    copy_function_to_destination(f)
  else
    delete_function_from_destination(f)
  end
end

function onCreate()
  log.info("EdgeApp", "Created Function Replicator (wildcard support)")
end

function onStart()
  log.info("EdgeApp", "Starting Function Replicator (wildcard support)")
  edge.on("functionValue", onFunctionValueUpdated)
end

function onDestroy()
  log.info("EdgeApp", "Stopping Function Replicator")
  edge.off("functionValue", onFunctionValueUpdated)
end
