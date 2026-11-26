class_name AIAttackState
extends AIState
## Short committed strike: drive the mouth straight into the chosen strike point.

const MAX_DURATION: float = 1.2


func id() -> StringName:
	return ATTACK


func evaluate(ctx: AIContext) -> StringName:
	if not AIChaseState.still_prey(ctx, ctx.chase_target):
		return RECOVER
	if ctx.state_time > MAX_DURATION:
		return CHASE
	if ctx.perception.prey == ctx.chase_target:
		ctx.lock_prey()  # keep aiming at the best part as the bodies move
	return STAY


func steer(ctx: AIContext) -> Vector2:
	if ctx.chase_target == null or not ctx.chase_target.is_alive:
		return Vector2.ZERO
	return ctx.dir_to(ctx.chase_point())
