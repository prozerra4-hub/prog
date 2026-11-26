class_name ArenaSystem
extends RefCounted
## Circular arena geometry: containment, edge distance, random points.
## The arena is centred on the world origin.

## Fixed outer wall. The shrinking play area is ZoneSystem's job.
var radius: float
var config: ArenaConfig


func _init(cfg: ArenaConfig) -> void:
	config = cfg
	radius = cfg.radius


## Keeps a circle of `r` inside the arena. Returns the outward normal if the head
## was pushed back (so the caller can slide along the wall), else Vector2.ZERO.
func clamp_inside(movement: SnakeMovement, r: float) -> Vector2:
	var limit: float = radius - r
	var d: float = movement.position.length()
	if d <= limit:
		return Vector2.ZERO
	var normal: Vector2 = movement.position / d
	movement.position = normal * limit
	return normal


## Distance from `p` to the arena wall (positive inside).
func distance_to_edge(p: Vector2) -> float:
	return radius - p.length()


## True if `p` is at least `margin` inside the wall.
func contains(p: Vector2, margin: float = 0.0) -> bool:
	return p.length() <= radius - margin


## Uniform random point in the disc of `ratio * radius`.
func random_point(rng: RandomNumberGenerator, ratio: float = 1.0, margin: float = 0.0) -> Vector2:
	var max_r: float = maxf(radius * ratio - margin, 0.0)
	var r: float = max_r * sqrt(rng.randf())
	return Vector2.from_angle(rng.randf() * TAU) * r
