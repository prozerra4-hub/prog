class_name ZoneSystem
extends RefCounted
## The shrinking safe zone (circle: center + radius) inside the fixed arena.
## Phase cycle: WAITING (current circle holds, next circle is already announced)
## -> SHRINKING (current circle lerps into the next) -> next phase ... -> DONE.
## Pure geometry and timing; erosion of snakes outside is ZoneErosion's job.

signal phase_started(index: int, wait_sec: float)
signal shrink_started(index: int)
signal shrink_finished(index: int)

enum State { WAITING, SHRINKING, DONE }

var state: State = State.DONE
var center: Vector2 = Vector2.ZERO
var radius: float = 0.0
## The circle the zone will shrink to (shown as an outline while waiting).
var next_center: Vector2 = Vector2.ZERO
var next_radius: float = 0.0
## Index into the phase list (-1 before the first phase, `phases.size()` for final).
var phase_index: int = -1

var _arena_radius: float
var _phases: Array[ZonePhase] = []
var _rng: RandomNumberGenerator
var _timer: float = 0.0
var _from_center: Vector2 = Vector2.ZERO
var _from_radius: float = 0.0
var _current: ZonePhase


func _init(arena_radius: float, rng: RandomNumberGenerator) -> void:
	_arena_radius = arena_radius
	_rng = rng
	center = Vector2.ZERO
	radius = arena_radius
	next_center = center
	next_radius = radius


## Starts the regular phase list from the full arena.
func start(phases: Array[ZonePhase]) -> void:
	_phases = phases
	phase_index = -1
	_advance()


## Jumps straight into `phase` (the showdown), from wherever the zone is now.
func start_final(phase: ZonePhase) -> void:
	_phases = []
	phase_index = 999
	_begin_phase(phase)


func tick(delta: float) -> void:
	if state == State.DONE or _current == null:
		return
	_timer += delta
	if state == State.WAITING:
		if _timer >= _current.wait_sec:
			_timer = 0.0
			state = State.SHRINKING
			_from_center = center
			_from_radius = radius
			shrink_started.emit(phase_index)
	elif state == State.SHRINKING:
		var t: float = clampf(_timer / maxf(_current.shrink_sec, 0.01), 0.0, 1.0)
		center = _from_center.lerp(next_center, t)
		radius = lerpf(_from_radius, next_radius, t)
		if t >= 1.0:
			shrink_finished.emit(phase_index)
			_advance()


## Seconds until the current wait ends (0 while shrinking or done).
func seconds_to_shrink() -> float:
	if state != State.WAITING or _current == null:
		return 0.0
	return maxf(_current.wait_sec - _timer, 0.0)


## True while the circle is closing.
func is_shrinking() -> bool:
	return state == State.SHRINKING


## True if `p` is at least `margin` inside the safe zone.
func contains(p: Vector2, margin: float = 0.0) -> bool:
	return p.distance_to(center) <= radius - margin


## How far `p` is from the zone edge, positive inside.
func distance_to_edge(p: Vector2) -> float:
	return radius - p.distance_to(center)


## Uniform random point inside the zone (optionally inside the NEXT circle, which
## is safer to spawn in shortly before a shrink).
func random_point(rng: RandomNumberGenerator, ratio: float = 1.0, use_next: bool = false) -> Vector2:
	var c: Vector2 = next_center if use_next else center
	var r: float = (next_radius if use_next else radius) * ratio
	return c + Vector2.from_angle(rng.randf() * TAU) * r * sqrt(rng.randf())


func _advance() -> void:
	phase_index += 1
	if phase_index >= _phases.size():
		state = State.DONE
		_current = null
		next_center = center
		next_radius = radius
		return
	_begin_phase(_phases[phase_index])


func _begin_phase(phase: ZonePhase) -> void:
	_current = phase
	_timer = 0.0
	next_radius = minf(_arena_radius * phase.radius_ratio, radius)
	var room: float = maxf(radius - next_radius, 0.0) * phase.center_shift
	next_center = center + Vector2.from_angle(_rng.randf() * TAU) * room * sqrt(_rng.randf())
	# Never let the next circle poke out of the arena wall.
	var limit: float = _arena_radius - next_radius
	if next_center.length() > limit:
		next_center = next_center.normalized() * maxf(limit, 0.0)
	state = State.WAITING if phase.wait_sec > 0.0 else State.SHRINKING
	_from_center = center
	_from_radius = radius
	phase_started.emit(phase_index, phase.wait_sec)
	if state == State.SHRINKING:
		shrink_started.emit(phase_index)
