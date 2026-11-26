class_name SnakeMovement
extends RefCounted
## Head kinematics: smoothed angular velocity (no instant reversals) and smoothed
## speed. Knows nothing about input or AI — it only follows a desired direction.

var position: Vector2 = Vector2.ZERO
var angle: float = 0.0
var speed: float = 0.0

var _angular_velocity: float = 0.0


## Teleports the head and clears angular velocity.
func reset(pos: Vector2, heading_angle: float, initial_speed: float) -> void:
	position = pos
	angle = heading_angle
	speed = initial_speed
	_angular_velocity = 0.0


## Unit vector of the current angle.
func heading() -> Vector2:
	return Vector2.from_angle(angle)


## Advances the head.
## `desired_dir` may be zero to keep the current heading.
func step(desired_dir: Vector2, target_speed: float, max_turn_rate: float,
		tuning: SnakeTuning, delta: float) -> void:
	var target_w: float = 0.0
	if desired_dir.length_squared() > 0.0001:
		var diff: float = wrapf(desired_dir.angle() - angle, -PI, PI)
		target_w = clampf(diff * tuning.turn_gain, -max_turn_rate, max_turn_rate)
	var w_blend: float = 1.0 - exp(-tuning.turn_smoothing * delta)
	_angular_velocity = lerpf(_angular_velocity, target_w, w_blend)
	angle = wrapf(angle + _angular_velocity * delta, -PI, PI)

	var v_blend: float = 1.0 - exp(-tuning.speed_smoothing * delta)
	speed = lerpf(speed, target_speed, v_blend)
	position += heading() * speed * delta


## Reflects the heading's outward component (used when sliding along the arena edge).
func slide_along(normal: Vector2) -> void:
	var dir: Vector2 = heading()
	var outward: float = dir.dot(normal)
	if outward > 0.0:
		var tangent: Vector2 = (dir - normal * outward)
		if tangent.length_squared() < 0.0001:
			tangent = normal.orthogonal()
		angle = tangent.angle()
		_angular_velocity *= 0.5


## Instantly turns away from `normal` (head-on bounce).
func deflect(normal: Vector2) -> void:
	angle = normal.angle()
	_angular_velocity = 0.0
	speed *= 0.6
