class_name AIState
extends RefCounted
## Base class for AI behaviour states. A state decides *where to steer* and *when
## to hand over*; global interrupts (danger -> ESCAPE) live in the state machine.

const IDLE: StringName = &"IDLE"
const SEEK_FOOD: StringName = &"SEEK_FOOD"
const WANDER: StringName = &"WANDER"
const CHASE: StringName = &"CHASE"
const ESCAPE: StringName = &"ESCAPE"
const ATTACK: StringName = &"ATTACK"
const RECOVER: StringName = &"RECOVER"
const STAY: StringName = &""


func id() -> StringName:
	return STAY


func enter(_ctx: AIContext) -> void:
	pass


func exit(_ctx: AIContext) -> void:
	pass


## Called on think ticks. Returns the next state id, or STAY.
func evaluate(_ctx: AIContext) -> StringName:
	return STAY


## Called every frame. Desired world direction (zero keeps heading).
func steer(_ctx: AIContext) -> Vector2:
	return Vector2.ZERO
