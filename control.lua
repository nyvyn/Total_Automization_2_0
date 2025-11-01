names = require("shared")

local libraries = {
  require("script/unit_deployment"),
  -- require("script/killcam")
}

local events = {}
local nth_tick_events = {}

for _, lib in ipairs(libraries) do
  if lib.events then
    for event_id, handler in pairs(lib.events) do
      if events[event_id] then
        table.insert(events[event_id], handler)
      else
        events[event_id] = {handler}
      end
    end
  end
  if lib.on_nth_tick then
    for interval, handler in pairs(lib.on_nth_tick) do
      if nth_tick_events[interval] then
        table.insert(nth_tick_events[interval], handler)
      else
        nth_tick_events[interval] = {handler}
      end
    end
  end
end

for event_id, handlers in pairs(events) do
  if #handlers == 1 then
    script.on_event(event_id, handlers[1])
  else
    local callbacks = handlers
    script.on_event(event_id, function(event)
      for _, handler in ipairs(callbacks) do
        handler(event)
      end
    end)
  end
end

for interval, handlers in pairs(nth_tick_events) do
  if #handlers == 1 then
    script.on_nth_tick(interval, handlers[1])
  else
    local callbacks = handlers
    script.on_nth_tick(interval, function(event)
      for _, handler in ipairs(callbacks) do
        handler(event)
      end
    end)
  end
end

local function call_lib_method(method_name, ...)
  for _, lib in ipairs(libraries) do
    local method = lib[method_name]
    if method then
      method(...)
    end
  end
end

script.on_init(function()
  call_lib_method("on_init")
end)

script.on_load(function()
  call_lib_method("on_load")
end)

script.on_configuration_changed(function(event)
  call_lib_method("on_configuration_changed", event)
end)
