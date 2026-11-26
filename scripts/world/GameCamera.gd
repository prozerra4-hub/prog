class_name GameCamera
extends Camera2D
## Follows a snake's head with look-ahead; zooms out as it grows. Holds still on
## the last position when the target dies. Screen shake is optional (settings).

var _cfg: CameraConfig
var _target: SnakeActor
var _anchor: Vector2 = Vector2.ZERO
var _shake: float = 0.0
var _rng := RandomNumberGenerator.new()
var shake_enabled: bool = true


func setup(cfg: CameraConfig) -> void:
	_cfg = cfg
	zoom = Vector2.ONE * cfg.base_zoom
	position_smoothing_enabled = false


## Follows `target`; `snap` jumps there instantly with the right zoom.
func follow(target: SnakeActor, snap: bool = false) -> void:
	_target = target
	if snap and target != null:
		_anchor = target.head_position()
		global_position = _anchor
		zoom = Vector2.ONE * _zoom_for(target)


## Adds screen shake (0..1, decays; ignored if disabled in settings).
func add_shake(amount: float) -> void:
	if shake_enabled:
		_shake = minf(_shake + amount, 1.0)


func _process(delta: float) -> void:
	if _cfg == null:
		return
	if _target != null and _target.is_alive:
		var ahead: Vector2 = _target.heading() * _target.head_radius() * _cfg.look_ahead_r
		var goal: Vector2 = _target.head_position() + ahead
		_anchor = _anchor.lerp(goal, 1.0 - exp(-_cfg.follow_smoothing * delta))
		var z: float = _zoom_for(_target)
		zoom = Vector2.ONE * lerpf(zoom.x, z, 1.0 - exp(-_cfg.zoom_smoothing * delta))
	_shake = move_toward(_shake, 0.0, delta * _cfg.shake_decay * 0.25)
	var jitter := Vector2.ZERO
	if _shake > 0.001:
		var mag: float = _cfg.shake_max_px * _shake * _shake / maxf(zoom.x, 0.01)
		jitter = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * mag
	global_position = _anchor + jitter


func _zoom_for(target: SnakeActor) -> float:
	var k: float = pow(maxf(target.radius, 1.0) / _cfg.reference_radius, _cfg.zoom_radius_exponent)
	return clampf(_cfg.base_zoom / k, _cfg.min_zoom, _cfg.max_zoom)
