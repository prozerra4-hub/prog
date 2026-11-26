class_name SnakeAIController
extends SnakeBrain
## AI brain: perceives on a throttled interval (staggered per snake), runs the
## state machine, and turns the state's wish into a safe direction through
## context steering (AISteering). Outside the safe zone, getting back in
## overrides whatever the state wants.

var ctx := AIContext.new()
var machine := SnakeAIStateMachine.new()
var steering := AISteering.new()

var _think_left: float = 0.0
var _interval: float = 0.18
var _desired: Vector2 = Vector2.ZERO


func _init(personality: AIPersonality, seed_value: int) -> void:
	ctx.personality = personality
	ctx.rng.seed = seed_value
	_interval = personality.think_interval * ctx.rng.randf_range(0.75, 1.25)


func on_spawned(actor: SnakeActor) -> void:
	ctx.actor = actor
	ctx.calm_time = 0.0
	ctx.chase_target = null
	ctx.perception = AIPerception.new()  # forget the previous life
	_think_left = 0.0
	if ctx.world != null:
		machine.start(ctx)


func think(actor: SnakeActor, world: WorldContext, delta: float) -> void:
	if ctx.world == null:
		ctx.world = world
		ctx.actor = actor
		machine.start(ctx)
	ctx.state_time += delta
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = _interval
		ctx.perception.refresh(actor, world, ctx.personality, world.rules)
		steering.update_danger(actor, ctx.perception, world.arena, world.zone)
		if ctx.perception.danger > 0.05:
			ctx.calm_time = 0.0
		machine.evaluate(ctx)
	if ctx.perception.danger <= 0.05:
		ctx.calm_time += delta
	var wish: Vector2 = machine.steer(ctx)
	var zone: ZoneSystem = world.zone
	if not zone.contains(actor.head_position(), actor.head_radius()):
		wish = (zone.next_center - actor.head_position()).normalized()
	_desired = steering.choose(wish, actor.heading())


func desired_direction() -> Vector2:
	return _desired


func look_target(actor: SnakeActor) -> Vector2:
	if ctx.chase_target != null and ctx.chase_target.is_alive:
		return ctx.chase_point()
	return actor.head_position() + (_desired if _desired != Vector2.ZERO else actor.heading()) * 100.0


## Current state machine state (for debugging / tests).
func state_id() -> StringName:
	return machine.current_id()
