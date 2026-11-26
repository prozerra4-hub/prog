class_name FoodTable
extends Resource
## Ambient food population and pickup behaviour.

@export var kinds: Array[FoodKind] = []
## Kind used for remains dropped by dead snakes.
@export var remains_kind: FoodKind
## Ambient orb value multiplier. Orb XP is also scaled by the eater's level, so an
## orb is always worth about (xp * this / 3) of a level.
@export var ambient_xp_multiplier: float = 2.0
## Ambient food the arena tries to keep alive.
@export var target_count: int = 1500
## Max ambient orbs respawned per second while below target.
@export var refill_per_sec: float = 90.0
## Pickup reach beyond touching, in head radii.
@export var magnet_reach_r: float = 0.9
@export var absorb_duration: float = 0.14
@export var spawn_pop_duration: float = 0.28
## Keep new food at least this far (world px) from any snake bead.
@export var spawn_clearance: float = 40.0
