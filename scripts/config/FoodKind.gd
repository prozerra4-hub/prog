class_name FoodKind
extends Resource
## One kind of collectible. Visual metrics are measured from the source PNG so the
## drawn orb matches its pickup radius exactly.

@export var id: StringName = &"normal"
## AssetCatalog keys; one is picked at random per spawned orb.
@export var texture_keys: Array[StringName] = []
@export var xp: int = 1
## World radius of the visible orb.
@export var radius: float = 7.0
## Radius of the opaque orb inside the texture, in texture pixels.
@export var sprite_radius_px: float = 24.5
## Relative spawn weight among ambient food.
@export var spawn_weight: float = 1.0
## Draw the soft aura under it (rare / special pickups).
@export var has_aura: bool = false
