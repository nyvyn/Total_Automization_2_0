local name = names.units.shell_tank

local sprite_base = util.copy(data.raw.car.tank)
local path = util.path("prototypes/units/shell_tank/")
util.recursive_hack_make_hr(sprite_base)
util.recursive_hack_scale(sprite_base, 1.5)
local tank_animation = util.copy(data.raw.car.tank.animation)
util.recursive_hack_scale(tank_animation, 1.5)
sprite_base.animation = tank_animation

local shifts = require(path.."shell_tank_creation_parameters")
for k, shift in pairs (shifts) do
  shift[2][2] = shift[2][2] - 1.3
end
local attack_range = 36
local stream_name = name.."-stream"
local explosion_name = name.."-explosion"
local unit =
{
  type = "unit",
  name = name,
  localised_name = {name},
  icon = sprite_base.icon,
  icon_size = sprite_base.icon_size,
  flags = util.unit_flags(),
  map_color = {b = 0.5, g = 1},
  enemy_map_color = {r = 1},
  max_health = 525,
  radar_range = 3,
  order="i-d",
  subgroup = "iron-units",
  healing_per_tick = 0,
  minable = {result = name, mining_time = 2},
  collision_box = {{-2, -2}, {2, 2}},
  selection_box = {{-2, -2}, {2, 2}},
  collision_mask = util.ground_unit_collision_mask(),
  max_pursue_distance = 64,
  resistances = nil,
  old_resistances =
  {
    {
      type = "acid",
      decrease = 10,
      percent = 80
    }
  },
  min_persue_time = (60 * 15),
  --sticker_box = {{-0.2, -0.2}, {0.2, 0.2}},
  distraction_cooldown = (15),
  move_while_shooting = false,
  can_open_gates = true,
  ai_settings =
  {
    do_separation = true
  },
  attack_parameters =
  {
    type = "projectile",
    ammo_category = util.ammo_category("iron-units"),
    warmup = 30,
    cooldown = 145,
    cooldown_deviation = 0.1,
    range = attack_range,
    min_attack_distance = attack_range - 8,
    lead_target_for_projectile_speed = 1,
    --projectile_creation_distance = 1.5,
    --projectile_center = {0, -1.5},
    projectile_creation_distance = 1.6,
    projectile_center = {-0.15625, -1.2},
    --range = 7 * 32,
    --min_range = 1 * 32,
    projectile_creation_parameters = shifts,
    sound =
    {
      {
        filename = "__base__/sound/fight/tank-cannon.ogg",
        volume = 1.0
      }
    },
    ammo_type =
    {
      category = util.ammo_category("iron-units"),
      target_type = "direction",
      action =
      {
        {
          type = "direct",
          action_delivery =
          {
            type = "stream",
            stream = stream_name,
            source_offset = {0, -5},
            source_effects =
            {
              type = "create-explosion",
              entity_name = "artillery-cannon-muzzle-flash"
            }
          }
        }
      }
    },
    animation = sprite_base.animation
  },
  vision_distance = 40,
  has_belt_immunity = true,
  movement_speed = 0.12,
  distance_per_frame = 0.15,
  absorptions_to_join_attack = {pollution = 1000},
  --corpse = name.." Corpse",
  dying_explosion = "explosion",
  vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
  working_sound = sprite_base.working_sound,
  run_animation = sprite_base.animation
}


local particle_gfx = util.copy(data.raw.projectile["cannon-projectile"])


local animation =
{
  filename = path.."shell_tank_projectile.png",
  line_length = 4,
  width = 46,
  height = 82,
  frame_count = 16,
  priority = "high",
  scale = 0.3,
  animation_speed = 1,
  blend_mode = "additive"
}

local shadow =
{
  filename = path.."shell_tank_projectile_shadow.png",
  line_length = 4,
  width = 94,
  height = 170,
  frame_count = 16,
  priority = "high",
  shift = {-0.09, 0.395},
  draw_as_shadow = true,
  scale = 0.3,
  animation_speed = 1,
}

local stream = util.copy(data.raw.stream["flamethrower-fire-stream"])
stream.name = stream_name
stream.oriented_particle = true
stream.action =
{
  {
    type = "direct",
    action_delivery =
    {
      type = "instant",
      target_effects =
      {
        {
          type = "create-entity",
          entity_name = explosion_name
        }
      }
    }
  },
  {
    type = "area",
    target_entities = false,
    trigger_from_target = true,
    repeat_count = 60,
    radius = 5,
    action_delivery =
    {
      type = "instant",
      target_effects =
      {
        {
          type = "create-entity",
          entity_name = explosion_name
        }
      }
    }
  },
  {
    type = "area",
    target_entities = false,
    trigger_from_target = true,
    repeat_count = 60,
    radius = 3,
    action_delivery =
    {
      type = "instant",
      target_effects =
      {
        {
          type = "create-entity",
          entity_name = explosion_name
        }
      }
    }
  },
  {
    type = "area",
    force = "not-same",
    ignore_collision_condition = true,
    radius = 5,
    action_delivery =
    {
      type = "instant",
      target_effects =
      {
        {
          type = "damage",
          damage = {amount = 15 , type = util.damage_type("explosion")}
        }
      }
    }
  },
  {
    type = "area",
    force = "not-same",
    ignore_collision_condition = true,
    radius = 3,
    action_delivery =
    {
      type = "instant",
      target_effects =
      {
        {
          type = "damage",
          damage = {amount = 15 , type = util.damage_type("explosion")}
        }
      }
    }
  }
}

stream.particle = animation
stream.shadow = shadow
--stream.shadow.draw_as_shadow = true
stream.particle.scale = 0.7
stream.particle_buffer_size = 1
stream.particle_spawn_interval = (100)
stream.particle_spawn_timeout = (0)
stream.particle_vertical_acceleration = (1.981 / 90)
stream.particle_horizontal_speed = 1
stream.particle_horizontal_speed_deviation = 0.2
stream.particle_start_alpha = 1
stream.particle_end_alpha = 1
stream.particle_start_scale = 0.7
stream.particle_loop_frame_count = 16
stream.particle_fade_out_threshold = 1
stream.particle_loop_exit_threshold = 1
stream.spine_animation = nil
stream.smoke_sources =
{
  {
    name = "soft-fire-smoke",
    frequency = 2, --0.25,
    position = {0.0, 0}, -- -0.8},
    starting_frame_deviation = 60
  }
}
stream.progress_to_create_smoke = 0
stream.target_position_deviation = 3

local explosion = util.copy(data.raw.explosion.explosion)
explosion.name = explosion_name

local sprites = explosion.animations
local new_animations = {}
local add_sprites = function(scale, speed)
  for k, sprite in pairs (sprites) do
    local new = util.copy(sprite)
    new.animation_speed = (new.animation_speed or 1) * speed
    new.scale = (new.scale or 1) * scale
    new.blend_mode = "additive"
    table.insert(new_animations, new)
  end
end

add_sprites(1, 0.5)
add_sprites(0.95, 0.6)
add_sprites(0.9, 0.7)
add_sprites(0.85, 0.8)
add_sprites(0.8, 0.9)
add_sprites(0.75, 1)
add_sprites(0.6, 1.1)
add_sprites(0.5, 1.2)

explosion.animations = new_animations
util.recursive_hack_make_hr(new_animations)
explosion.light = nil
explosion.smoke = nil
explosion.smoke_count = 0



local item = {
  type = "item",
  name = name,
  localised_name = {name},
  icon = unit.icon,
  icon_size = unit.icon_size,
  flags = {},
  subgroup = "iron-units",
  order = "e-"..name,
  stack_size = 10,
  place_result = name
}

local recipe = {
  type = "recipe",
  name = name,
  localised_name = {name},
  category = names.deployers.iron_unit,
  enabled = false,
  ingredients =
  {
    {type = "item", name = "engine-unit", amount = 10},
    {type = "item", name = "steel-plate", amount = 20},
    {type = "item", name = "explosives", amount = 20},
    {type = "item", name = "rocket-fuel", amount = 5}
  },
  energy_required = 45,
  results = {
    {type = "item", name = name, amount = 1}
  }
}


data:extend{unit, item, recipe, stream, explosion}
