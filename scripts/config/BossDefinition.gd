class_name BossDefinition
extends Resource
## A boss type. Add new bosses by creating new .tres files, no code changes needed.

@export var id: StringName = &"crimson_tyrant"
@export var display_name: String = "Crimson Tyrant"
@export var level: int = 1000
@export var skin: SnakeSkin
@export var speed_multiplier: float = 0.62
@export var turn_multiplier: float = 0.85
## Body length relative to a normal snake of the same level.
@export var length_multiplier: float = 0.45
## Gold bands from this share of the body to the tail are WEAK SPOTS: during the
## showdown the player can cut them at any level (dodge the jaws, cut the tail,
## then finish it).
@export_range(0.0, 1.0) var weak_spot_from_share: float = 0.5
## The boss ignores small fry: it only hunts snakes at least this share of its level.
## Touching its jaws is still lethal, but it will not seek out beginners.
@export_range(0.0, 1.0) var min_target_level_ratio: float = 0.4
## Radius (px) in which the boss notices a target.
@export var aggro_radius: float = 700.0
## Boss stays within this share of the arena radius when patrolling.
@export_range(0.1, 1.0) var patrol_radius_ratio: float = 0.45
@export var charge_windup_sec: float = 0.7
@export var charge_duration_sec: float = 1.1
@export var charge_speed_multiplier: float = 1.75
@export var charge_cooldown_sec: float = 6.0
## Start a charge when the target is closer than this (px).
@export var charge_trigger_distance: float = 500.0
## XP awarded to the player for the kill, as a multiple of its total XP.
@export var reward_xp_ratio: float = 0.5
