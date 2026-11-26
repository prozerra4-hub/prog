class_name AIContext
extends RefCounted
## Shared blackboard for one AI snake's states.

var actor: SnakeActor
var world: WorldContext
var personality: AIPersonality
var perception := AIPerception.new()
var rng := RandomNumberGenerator.new()

## Seconds spent in the current state.
var state_time: float = 0.0
var wander_target: Vector2 = Vector2.ZERO
var chase_target: SnakeActor
## Part of chase_target to strike (SnakeSpatialIndex.HEAD or a bead index).
var chase_part: int = SnakeSpatialIndex.HEAD
## Seconds since the last perceived threat.
var calm_time: float = 0.0


## True when perception found a food cluster worth going for.
func has_food() -> bool:
	return perception.food_point != Vector2.INF


## True when perception found a strike opportunity.
func has_prey() -> bool:
	return perception.prey != null


## Unit direction from the head to `point` (current heading if already there).
func dir_to(point: Vector2) -> Vector2:
	var to: Vector2 = point - actor.head_position()
	return to.normalized() if to.length_squared() > 1.0 else actor.heading()


## Adopts the perceived prey (and its best strike part) as the chase target.
func lock_prey() -> void:
	chase_target = perception.prey
	chase_part = perception.prey_part


## Where to aim on the chase target right now, leading its motion a little.
func chase_point() -> Vector2:
	var t: SnakeActor = chase_target
	if t == null:
		return actor.head_position()
	var part: int = chase_part
	if part != SnakeSpatialIndex.HEAD and part >= t.body.count:
		part = SnakeSpatialIndex.HEAD
	var p: Vector2 = SnakeSpatialIndex.part_position(t, part)
	var lead: float = 0.45 if part == SnakeSpatialIndex.HEAD else 0.15
	return p + t.heading() * t.current_speed() * lead


## Picks a roam destination inside the safe zone (inside the NEXT circle when a
## shrink is coming soon), biased away from the boss.
func pick_wander_target(ratio: float = 0.7) -> void:
	var zone: ZoneSystem = world.zone
	var use_next: bool = zone.is_shrinking() or (zone.state == ZoneSystem.State.WAITING and zone.seconds_to_shrink() < 8.0)
	var best: Vector2 = Vector2.ZERO
	var best_score: float = -INF
	for i: int in 4:
		var p: Vector2 = zone.random_point(rng, ratio, use_next)
		var score: float = rng.randf()
		if world.boss != null and world.boss.is_alive:
			score += minf(p.distance_to(world.boss.head_position()) / 2000.0, 1.0)
		if score > best_score:
			best_score = score
			best = p
	wander_target = best
