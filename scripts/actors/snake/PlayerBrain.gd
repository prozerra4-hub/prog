class_name PlayerBrain
extends SnakeBrain
## Steering from a PlayerInputSource (mouse / keyboard).

var _input: PlayerInputSource
var _desired: Vector2 = Vector2.ZERO


func _init(input: PlayerInputSource) -> void:
	_input = input


func think(actor: SnakeActor, _world: WorldContext, _delta: float) -> void:
	_desired = _input.read_direction(actor.get_viewport(), actor.head_position())


func desired_direction() -> Vector2:
	return _desired


func look_target(actor: SnakeActor) -> Vector2:
	var dir: Vector2 = _desired if _desired != Vector2.ZERO else actor.heading()
	return actor.head_position() + dir * 100.0
