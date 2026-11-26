class_name AIRecoverState
extends AIState
## Cool-down after a chase or escape: drift toward open space, then resume.

const DURATION_MIN: float = 0.5
const DURATION_MAX: float = 1.1

var _duration: float = 0.8


func id() -> StringName:
	return RECOVER


func enter(ctx: AIContext) -> void:
	_duration = ctx.rng.randf_range(DURATION_MIN, DURATION_MAX)
	ctx.chase_target = null
	ctx.pick_wander_target(0.5)


func evaluate(ctx: AIContext) -> StringName:
	if ctx.state_time < _duration:
		return STAY
	return SEEK_FOOD if ctx.has_food() else WANDER


func steer(ctx: AIContext) -> Vector2:
	return ctx.dir_to(ctx.wander_target)
