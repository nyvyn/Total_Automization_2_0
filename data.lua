util = require "prototypes/tf_util/tf_util"
names = require("shared")
require "prototypes/units/units"
require "prototypes/entities/entities"
require "prototypes/variety_explosions"

local player_mask = util.ground_unit_collision_mask()
for _, character in pairs(data.raw.character) do
  character.collision_mask = player_mask
end

-- The base game acid splashes are OP.
-- Just turn off the damage and sticker on ground effect.

for k, fire in pairs (data.raw.fire) do
  if fire.name:find("acid%-splash%-fire") then
    fire.on_damage_tick_effect = nil
  end
end
