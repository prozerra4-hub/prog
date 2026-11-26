class_name AIIdleState
extends AIState
## Brief settle after spawning: keep heading, look around, then go.

const DURATION_MIN: float = 0.25
const DURATION_MAX: float = 0.7

var _duration: float = 0.5


func id() -> StringName:
	return IDLE


func enter(ctx: AIContext) -> void:
	_duration = ctx.rng.randf_range(DURATION_MIN, DURATION_MAX)


func evaluate(ctx: AIContext) -> StringName:
	if ctx.state_time < _duration:
		return STAY
	return SEEK_FOOD if ctx.has_food() else WANDER
