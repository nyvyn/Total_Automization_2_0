## Scenario structure
Scenarios have a wiki page (https://wiki.factorio.com/Scenario_system) with the following naming convention:
- "control.lua" - (optional) runtime code
- "image.png" - (optional) used as preview image of the scenario
- "image_space_age.png" - (optional) used as preview image of the scenario when SA is enabled
- "locale" dir - (optional) for all the localisations (worth mentioning that localisation of "scenario-name" and 
"scenario-description" supports both "scenario-name" and "scenario-name-space-age" / "scenario-description", "scenario-description-space-age")
- "blueprint.zip" - (optional) the map's zip used in this scenario
- "description.json" (mandatory) - keys as described in https://wiki.factorio.com/Scenario_system

## Campaigns structure
Campaigns are a collection of scenarios basically, although campaigns dont have an official wiki reference, by looking at base's structure, here's the presumed structure of it:

Campaign structure:
- "locale" dir - (optional) for all the localisations, supports default keys "name", "description" (with SA variants),
probably supports "[levels]" localisation group as well to rename each campaign's level
- "image.png" - (optional) used as preview image of the scenario
- "image_space_age.png" - (optional) used as preview image of the scenario when SA is enabled
- "lualib" dir - (optional) a directory to store other files that is ignored by the campaign's levels list
- "*/" - any number of folders containing the levels, no specific naming convention
- "description.json" (mandatory) - describes the properties of this campaign, in particular:
  - "starting-level" - Undocumented- string - Default 1st level alphabetically sorted
  - "is-main-game" - boolean - Default: false
  - "multiplayer-compatible" - boolean - Default: false
  - "order" - Order
  - "difficulties" - Undocumented - Array of strings [ "easy", "normal", "hard" ]?

Campaign's Level structure:
- "locale" dir - (optional) for all the localisations (no default keys for level's name or description)
- "control.lua" - (optional) runtime code
- "blueprint.zip" - (optional) the map's zip used in this level
- no "image/image_SA.png" are supported, campaign's top level image/image_SA are used instead

## Total Automization 2.0 Port Notes

Use **Xorimuth’s Factorio 2.0 Mod Porting Guide** for the authoritative checklist: https://github.com/tburrows13/factorio-2.0-mod-porting-guide (GitHub README). Highlights that apply to this mod:

- **Disable expansions while iterating.** Follow the guide's recommendation to port against base 2.0 first (no Quality/Space Age/Elevated Rails) so the prototype warnings stay focused on our data.
- **Update metadata.** `info.json` now targets `factorio_version = "2.0"` and depends on `base >= 2.0.0` plus `Unit_Control >= 1.0.0`.
- **Runtime storage rename.** Anything that persisted data via `global` must now use the new `storage` table. `script/unit_deployment.lua` and `script/killcam.lua` have been migrated; keep that pattern for any future state.
- **Event registration.** Factorio 2.0 exposes native multiple-handler support, so we removed the external `event_handler` library. Add new modules by inserting them into the `libraries` table in `control.lua`.
- **Recipe canonicalisation.** All recipes require longhand `{type=..., name=..., amount=...}` entries and `results`. Every deployer and unit recipe now follows this; copy that format when adding new crafting or unit deployment recipes.
- **Prototypes directory.** Data-stage content now lives under `prototypes/` (renamed from `data/`) to mirror the 2.0 base mod layout. Put new prototype files there and update `require` paths accordingly.
- **Fluid boxes.** `base_area`/`base_level`/`type` were replaced by `volume` and `flow_direction + direction`. See the deploy machine prototypes for the updated structure (`volume = 100`, north-facing connection at `{0, -2}`).
- **Science packs.** Technology `unit.ingredients` also use the longhand format. Leave commented-out packs in longhand form to avoid typos when re-enabling them later.
- **Quality check tools.** After loading into 2.0, enable `check-unused-prototype-data` from the diagnostics menu (Ctrl+Alt+Click "Settings") to catch leftover 1.1 definitions, as suggested by the guide.

### Validation checklist

- Load the mod with only `base` and `Unit Control 1.0.0+` enabled and confirm the game reaches the main menu.
- Place each deployer in a fresh save, craft a unit batch, and verify that spawned entities still raise `unit_control` events.
- Run an existing 1.1 save after migrating it to 2.0 to ensure `storage.unit_deployment` rehydrates and schedules future checks correctly.
