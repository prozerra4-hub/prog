class_name AIEscapeState
extends AIState
## Flee stronger snakes. Steers along the danger gradient with a sideways component
## so fleeing snakes arc away instead of running in a straight, catchable line.

## Seconds without danger before calming down.
const CALM_NEEDED: float = 0.6

var _swerve: float = 1.0


func id() -> StringName:
	return ESCAPE


func enter(ctx: AIContext) -> void:
	_swerve = 1.0 if ctx.rng.randf() < 0.5 else -1.0


func evaluate(ctx: AIContext) -> StringName:
	if ctx.calm_time >= CALM_NEEDED:
		return RECOVER
	return STAY


func steer(ctx: AIContext) -> Vector2:
	var away: Vector2 = ctx.perception.avoidance
	if away.length_squared() < 0.0001:
		return Vector2.ZERO
	away = away.normalized()
	# Arc away (harder to cut off) and lean toward the zone centre, away from its edge.
	var to_center: Vector2 = (ctx.world.zone.center - ctx.actor.head_position()).normalized()
	var center_pull: Vector2 = to_center * 0.4 if ctx.perception.edge_distance < ctx.actor.head_radius() * 12.0 else Vector2.ZERO
	return (away + away.orthogonal() * 0.35 * _swerve + center_pull).normalized()
