local constants = require("shared")

local deployer_names = constants.deployers

local script_data
local unit_spawned_event
local deployer_map

local function ensure_tables(data)
  data.machines = data.machines or {}
  data.tick_check = data.tick_check or {}
  data.next_check = data.next_check or {}
end

local function get_script_data()
  if script_data then
    return script_data
  end

  script_data = storage.unit_deployment

  if not script_data then
    script_data = {
      machines = {},
      tick_check = {},
      next_check = {},
      unit_spawned_event = nil
    }
    storage.unit_deployment = script_data
  else
    ensure_tables(script_data)
    script_data.unit_spawned_event = script_data.unit_spawned_event or nil
  end

  return script_data
end

local function get_deployer_map()
  if deployer_map then
    return deployer_map
  end

  deployer_map = {}
  for _, name in pairs(deployer_names) do
    deployer_map[name] = true
  end

  return deployer_map
end

local function refresh_unit_control_events()
  local data = get_script_data()
  unit_spawned_event = nil
  data.unit_spawned_event = nil

  local interface = remote.interfaces["unit_control"]
  if interface and interface.get_events then
    local ok, control_events = pcall(remote.call, "unit_control", "get_events")
    if ok and control_events and control_events.on_unit_spawned then
      unit_spawned_event = control_events.on_unit_spawned
      data.unit_spawned_event = unit_spawned_event
      return
    end

    local reason
    if not ok then
      reason = tostring(control_events)
    elseif control_events then
      reason = "missing on_unit_spawned"
    else
      reason = "nil response"
    end
    log("[Total Automization] Unable to subscribe to unit_control events: " .. reason)
  else
    log("[Total Automization] unit_control interface missing; deployment events disabled.")
  end
end

local function clear_pending_check(unit_number)
  local data = get_script_data()
  local scheduled_tick = data.next_check[unit_number]
  if not scheduled_tick then
    return
  end

  local bucket = data.tick_check[scheduled_tick]
  if bucket then
    bucket[unit_number] = nil
    if not next(bucket) then
      data.tick_check[scheduled_tick] = nil
    end
  end

  data.next_check[unit_number] = nil
end

local function schedule_check(entity, tick)
  if not (entity and entity.valid) then
    return
  end

  local data = get_script_data()
  local unit_number = entity.unit_number
  clear_pending_check(unit_number)

  local bucket = data.tick_check[tick]
  if not bucket then
    bucket = {}
    data.tick_check[tick] = bucket
  end

  data.next_check[unit_number] = tick
  bucket[unit_number] = entity
end

local direction_offsets = {
  [defines.direction.north] = {0, -1},
  [defines.direction.south] = {0, 1},
  [defines.direction.east] = {1, 0},
  [defines.direction.west] = {-1, 0}
}

local function deploy_unit(source, prototype, count)
  if not (source and source.valid) then
    return 0
  end

  local direction = source.direction
  local offset = direction_offsets[direction]
  if not offset then
    return 0
  end

  local name = prototype.name
  local deploy_bounding_box = prototype.collision_box
  if not deploy_bounding_box then
    return 0
  end

  local bounding_box = source.bounding_box
  local offset_x = offset[1] * ((bounding_box.right_bottom.x - bounding_box.left_top.x) / 2) + ((deploy_bounding_box.right_bottom.x - deploy_bounding_box.left_top.x) / 2)
  local offset_y = offset[2] * ((bounding_box.right_bottom.y - bounding_box.left_top.y) / 2) + ((deploy_bounding_box.right_bottom.y - deploy_bounding_box.left_top.y) / 2)
  local position = {source.position.x + offset_x, source.position.y + offset_y}
  local surface = source.surface
  local force = source.force
  local deployed = 0

  for _ = 1, count do
    if not (surface and surface.valid and source.valid) then
      break
    end

    local deploy_position = surface.can_place_entity {
      name = name,
      position = position,
      direction = direction,
      force = force,
      build_check_type = defines.build_check_type.manual
    } and position or surface.find_non_colliding_position(name, position, 0, 1)

    if deploy_position then
      local unit = surface.create_entity {
        name = name,
        position = deploy_position,
        force = force,
        direction = direction,
        raise_built = true
      }

      if unit and unit.valid and unit_spawned_event then
        script.raise_event(unit_spawned_event, {entity = unit, spawner = source})
      end

      deployed = deployed + 1
    end
  end

  return deployed
end

local no_recipe_check_again = 300

local function check_deployer(entity)
  if not (entity and entity.valid) then
    return
  end

  local data = get_script_data()
  data.machines[entity.unit_number] = entity

  local recipe = entity.get_recipe()
  if not recipe then
    schedule_check(entity, game.tick + no_recipe_check_again)
    return
  end

  local speed = entity.crafting_speed
  if speed == 0 then
    schedule_check(entity, game.tick + no_recipe_check_again)
    return
  end

  local progress = entity.crafting_progress
  local remaining_ticks = 1 + math.ceil(((recipe.energy * (1 - progress)) / speed) * 60)
  schedule_check(entity, game.tick + remaining_ticks)

  local inventory = entity.get_inventory(defines.inventory.assembling_machine_output)
  if not (inventory and inventory.valid) then
    return
  end

  local contents = inventory.get_contents()
  if not next(contents) then
    return
  end

  local prototypes = game.entity_prototypes

  for name, count in pairs(contents) do
    local prototype = prototypes[name]
    if prototype then
      local deployed_count = deploy_unit(entity, prototype, count)
      if deployed_count > 0 and entity.valid then
        inventory.remove {name = name, count = deployed_count}
      end
    end
  end
end

local function on_built_entity(event)
  local entity = event.created_entity or event.entity or event.destination
  if not (entity and entity.valid) then
    return
  end

  if not get_deployer_map()[entity.name] then
    return
  end

  get_script_data().machines[entity.unit_number] = entity
  check_deployer(entity)
end

local function on_tick(event)
  local data = get_script_data()
  local entities = data.tick_check[event.tick]
  if not entities then
    return
  end

  data.tick_check[event.tick] = nil

  for unit_number, entity in pairs(entities) do
    data.next_check[unit_number] = nil

    if entity and entity.valid then
      check_deployer(entity)
    else
      data.machines[unit_number] = nil
    end
  end
end

local function handle_removed_entity(event)
  local entity = event.entity or event.destination or event.created_entity
  if not entity then
    return
  end

  local unit_number = event.unit_number or (entity.valid and entity.unit_number)
  if not unit_number then
    return
  end

  if not get_deployer_map()[entity.name] then
    return
  end

  local data = get_script_data()
  data.machines[unit_number] = nil
  clear_pending_check(unit_number)
end

local unit_deployment = {}

unit_deployment.events = {
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_robot_built_entity] = on_built_entity,
  [defines.events.script_raised_built] = on_built_entity,
  [defines.events.script_raised_revive] = on_built_entity,
  [defines.events.on_entity_cloned] = on_built_entity,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_player_mined_entity] = handle_removed_entity,
  [defines.events.on_robot_mined_entity] = handle_removed_entity,
  [defines.events.script_raised_destroy] = handle_removed_entity,
  [defines.events.on_entity_died] = handle_removed_entity
}

unit_deployment.on_init = function()
  local data = get_script_data()
  ensure_tables(data)
  refresh_unit_control_events()
end

unit_deployment.on_load = function()
  script_data = storage.unit_deployment
  if script_data then
    ensure_tables(script_data)
    unit_spawned_event = script_data.unit_spawned_event
  else
    unit_spawned_event = nil
  end
end

unit_deployment.on_configuration_changed = function()
  local data = get_script_data()
  ensure_tables(data)

  for unit_number, entity in pairs(data.machines) do
    if not (entity and entity.valid) then
      data.machines[unit_number] = nil
      clear_pending_check(unit_number)
    end
  end

  for tick, entries in pairs(data.tick_check) do
    for unit_number, entity in pairs(entries) do
      if not (entity and entity.valid) then
        entries[unit_number] = nil
      end
    end
    if not next(entries) then
      data.tick_check[tick] = nil
    end
  end

  refresh_unit_control_events()

  for _, entity in pairs(data.machines) do
    if entity and entity.valid then
      schedule_check(entity, game.tick + 1)
    end
  end
end

return unit_deployment
