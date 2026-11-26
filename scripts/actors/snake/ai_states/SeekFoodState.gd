class_name AISeekFoodState
extends AIState
## Head for the best-valued food in sight; collectors stay here longer.


func id() -> StringName:
	return SEEK_FOOD


func evaluate(ctx: AIContext) -> StringName:
	# Collectors (high food bias) are less tempted to break off and hunt.
	var temptation: float = ctx.personality.aggression / maxf(ctx.personality.food_bias, 0.1)
	if ctx.has_prey() and ctx.rng.randf() < temptation * 0.6:
		return CHASE
	if not ctx.has_food():
		return WANDER
	return STAY


func steer(ctx: AIContext) -> Vector2:
	if ctx.has_food():
		return ctx.dir_to(ctx.perception.food_point)
	return Vector2.ZERO
