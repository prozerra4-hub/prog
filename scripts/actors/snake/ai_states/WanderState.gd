class_name AIWanderState
extends AIState
## Roam toward random destinations until something interesting shows up.


func id() -> StringName:
	return WANDER


func enter(ctx: AIContext) -> void:
	ctx.pick_wander_target()


func evaluate(ctx: AIContext) -> StringName:
	if ctx.has_prey() and ctx.rng.randf() < ctx.personality.aggression:
		return CHASE
	if ctx.has_food():
		return SEEK_FOOD
	if ctx.actor.head_position().distance_to(ctx.wander_target) < ctx.actor.head_radius() * 6.0:
		ctx.pick_wander_target()
	return STAY


func steer(ctx: AIContext) -> Vector2:
	return ctx.dir_to(ctx.wander_target)
