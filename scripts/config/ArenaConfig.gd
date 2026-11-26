class_name ArenaConfig
extends Resource
## Circular arena layout.

@export var radius: float = 4800.0
## Floor tile, AssetCatalog key.
@export var floor_texture_key: StringName = &"arena.floor"
## World pixels per floor texture pixel.
@export var floor_texture_scale: float = 2.0
## Snakes spawn inside this share of the radius.
@export_range(0.1, 1.0) var spawn_radius_ratio: float = 0.82
## Clearance from other snakes required for a safe spawn.
@export var safe_spawn_clearance: float = 520.0
@export var safe_spawn_samples: int = 28
