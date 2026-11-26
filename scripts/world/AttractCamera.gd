class_name AttractCamera
extends RefCounted
## Main-menu background camera: follows the top rival, re-picking periodically.

const RETARGET_SEC: float = 7.0

var _camera: GameCamera
var _timer: float = 0.0
var _placed: bool = false


func _init(camera: GameCamera) -> void:
	_camera = camera


func tick(delta: float, snakes: Array[SnakeActor]) -> void:
	_timer -= delta
	if _timer <= 0.0:
		retarget(snakes)


## Follows the highest-level living rival.
func retarget(snakes: Array[SnakeActor]) -> void:
	_timer = RETARGET_SEC
	var best: SnakeActor = null
	for s: SnakeActor in snakes:
		if s.is_alive and not s.is_boss and (best == null or s.stats.level > best.stats.level):
			best = s
	if best != null:
		_camera.follow(best, not _placed)
		_placed = true
