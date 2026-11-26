class_name AssetIds
extends RefCounted
## Every asset key used by code. Keys map to files in AssetCatalog.MANIFEST, so a
## renamed file is fixed in exactly one place.

const SNAKE_BEAD: StringName = &"snake.bead"

const FOOD_SMALL_GOLD: StringName = &"food.small_gold"
const FOOD_MEDIUM_GOLD: StringName = &"food.medium_gold"
const FOOD_LARGE_GOLD: StringName = &"food.large_gold"
const FOOD_RED: StringName = &"food.red"
const FOOD_PURPLE: StringName = &"food.purple"
const FOOD_CYAN: StringName = &"food.cyan"
const FOOD_GREEN: StringName = &"food.green"
const FOOD_RARE: StringName = &"food.rare_orange"
const GEM_BLUE: StringName = &"food.gem_blue"
const GEM_PURPLE: StringName = &"food.gem_purple"
const GEM_GREEN: StringName = &"food.gem_green"

const VFX_LEVELUP_GOLD: StringName = &"vfx.levelup_gold"
const VFX_IMPACT_GOLD: StringName = &"vfx.impact_gold"
const VFX_SPARKLE_WHITE: StringName = &"vfx.sparkle_white"
const VFX_SPARKLE_CYAN: StringName = &"vfx.sparkle_cyan"
const VFX_DEATH_SMOKE: StringName = &"vfx.death_smoke"
const VFX_RESPAWN_PORTAL: StringName = &"vfx.respawn_portal"
const VFX_BOSS_BURST: StringName = &"vfx.boss_burst"
const VFX_RARE_AURA: StringName = &"vfx.rare_aura"

const ARENA_FLOOR: StringName = &"arena.floor"
const ARENA_FLOOR_HEX: StringName = &"arena.floor_hex"

const ICON_CLOCK: StringName = &"ui.clock"
const ICON_HEART: StringName = &"ui.heart"
const ICON_CROWN: StringName = &"ui.crown"
const ICON_SKULL: StringName = &"ui.skull"

## Opaque radius of the bead sphere inside its 256 px texture (measured, see
## docs/ASSET_CATALOG.md). Drawing scale = world_radius / this.
const BEAD_SPRITE_RADIUS_PX: float = 66.5
