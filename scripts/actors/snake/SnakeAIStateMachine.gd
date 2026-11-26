class_name SnakeAIStateMachine
extends RefCounted
## Owns the AI states and transitions. States decide their own exits; the only
## global rule here is the danger interrupt (anything -> ESCAPE).

signal state_changed(old_state: StringName, new_state: StringName)

## Danger level that forces ESCAPE regardless of state.
const ESCAPE_DANGER: float = 0.35

var current: AIState
var _states: Dictionary = {}  # StringName -> AIState


func _init() -> void:
	for s: AIState in [AIIdleState.new(), AIWanderState.new(), AISeekFoodState.new(),
			AIChaseState.new(), AIAttackState.new(), AIEscapeState.new(), AIRecoverState.new()]:
		_states[s.id()] = s


## Resets the machine into IDLE (called on spawn).
func start(ctx: AIContext) -> void:
	current = null
	_switch(ctx, AIState.IDLE)


## Id of the active state, or AIState.STAY before start().
func current_id() -> StringName:
	return current.id() if current != null else AIState.STAY


## Think tick: apply the interrupt, then let the current state decide.
func evaluate(ctx: AIContext) -> void:
	if ctx.perception.danger >= ESCAPE_DANGER and current.id() != AIState.ESCAPE:
		_switch(ctx, AIState.ESCAPE)
		return
	var next: StringName = current.evaluate(ctx)
	if next != AIState.STAY and next != current.id():
		_switch(ctx, next)


func steer(ctx: AIContext) -> Vector2:
	return current.steer(ctx)


func _switch(ctx: AIContext, next: StringName) -> void:
	var target: AIState = _states.get(next)
	if target == null:
		push_error("SnakeAIStateMachine: unknown state %s" % next)
		return
	var old: StringName = current_id()
	if current != null:
		current.exit(ctx)
	current = target
	ctx.state_time = 0.0
	current.enter(ctx)
	state_changed.emit(old, next)
