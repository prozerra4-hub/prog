class_name AIChaseState
extends AIState
## Close in on a weaker snake's best strike point (often just behind its head,
## where a cut takes the most), leading its motion.

## Switch to ATTACK when this close (in own head radii).
const ATTACK_RANGE_R: float = 6.0


func id() -> StringName:
	return CHASE


func enter(ctx: AIContext) -> void:
	ctx.lock_prey()


func evaluate(ctx: AIContext) -> StringName:
	if not still_prey(ctx, ctx.chase_target) or ctx.state_time > ctx.personality.chase_timeout:
		return RECOVER
	# Follow the perception's best strike point; switch targets if a much better one appears.
	var p: AIPerception = ctx.perception
	if p.prey == ctx.chase_target or (p.prey != null and p.prey_distance < ctx.actor.head_position().distance_to(ctx.chase_point()) * 0.6):
		ctx.lock_prey()
	if ctx.actor.head_position().distance_to(ctx.chase_point()) < ctx.actor.head_radius() * ATTACK_RANGE_R:
		return ATTACK
	return STAY


func steer(ctx: AIContext) -> Vector2:
	if ctx.chase_target == null or not ctx.chase_target.is_alive:
		return Vector2.ZERO
	return ctx.dir_to(ctx.chase_point())


## True while `prey` is alive, unshielded, weak enough and within reach to keep hunting.
static func still_prey(ctx: AIContext, prey: SnakeActor) -> bool:
	if prey == null or not prey.is_alive or prey.is_invulnerable():
		return false
	if float(prey.stats.level) > float(ctx.actor.stats.level) * ctx.personality.prey_ratio:
		return false
	return prey.head_position().distance_to(ctx.actor.head_position()) < ctx.perception.sight * 1.5
