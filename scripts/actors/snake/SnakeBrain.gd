class_name SnakeBrain
extends RefCounted
## Steering contract for anything that drives a SnakeActor (player input, AI, boss).
## SnakeActor depends only on this interface, never on a concrete controller.


## Called every simulation step before movement. Implementations update their
## decision state here (AI throttles its own thinking).
func think(_actor: SnakeActor, _world: WorldContext, _delta: float) -> void:
	pass


## World-space direction the snake wants to travel. Zero keeps the current heading.
func desired_direction() -> Vector2:
	return Vector2.ZERO


## Where the eyes should look (world point). Defaults to straight ahead.
func look_target(actor: SnakeActor) -> Vector2:
	return actor.head_position() + actor.heading() * 100.0


## Multiplier on movement speed this frame (boss charge uses it).
func speed_factor() -> float:
	return 1.0


func on_spawned(_actor: SnakeActor) -> void:
	pass


func on_died(_actor: SnakeActor) -> void:
	pass
