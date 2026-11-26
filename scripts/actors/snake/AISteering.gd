class_name AISteering
extends RefCounted
## Context steering. On each think tick, 16 candidate directions get a DANGER score
## (predicted threat mouths, blocking bodies ahead, the arena wall and the safe
## zone edge). Every frame the state's wish is turned into an INTEREST score per
## direction, and the best safe direction wins (blended with its neighbours for
## smooth turns).
## Result: AI that slips through gaps instead of grinding along bodies or walls.

const DIRECTIONS: int = 16
## Probe distances along each direction, in own head radii.
const PROBE_NEAR_R: float = 2.5
const PROBE_FAR_R: float = 5.5
const DANGER_WEIGHT: float = 1.7
## Directions this dangerous are only used if nothing else is open.
const BLOCKED: float = 0.85

var _dirs := PackedVector2Array()
var _danger := PackedFloat32Array()


func _init() -> void:
	for i: int in DIRECTIONS:
		_dirs.append(Vector2.from_angle(TAU * float(i) / float(DIRECTIONS)))
	_danger.resize(DIRECTIONS)


## Rebuilds the 16-direction danger map (call on think ticks, not every frame).
func update_danger(me: SnakeActor, perception: AIPerception, arena: ArenaSystem, zone: ZoneSystem) -> void:
	var head: Vector2 = me.head_position()
	var r: float = me.head_radius()
	for i: int in DIRECTIONS:
		var dir: Vector2 = _dirs[i]
		var d: float = 0.0
		# Threat mouths: moving toward one is the worst choice.
		for t: int in perception.threat_points.size():
			var to: Vector2 = perception.threat_points[t] - head
			var dist: float = to.length()
			var w: float = clampf(1.0 - dist / perception.threat_reach[t], 0.0, 1.0)
			if w > 0.0:
				var align: float = maxf(dir.dot(to / maxf(dist, 0.001)), 0.0)
				d = maxf(d, w * (0.25 + 0.75 * align))
		# Bodies and wall along the probe line.
		for k: int in 2:
			var reach: float = r * (PROBE_NEAR_R if k == 0 else PROBE_FAR_R)
			var weight: float = 0.75 if k == 0 else 0.4
			var probe: Vector2 = head + dir * reach
			if probe.length() > arena.radius - r * 1.5:
				d = maxf(d, weight + 0.15)
			# Leaving the safe zone is as bad as hitting a wall (unless already outside).
			if zone.contains(head) and not zone.contains(probe, r):
				d = maxf(d, weight + 0.1)
			for o: int in perception.obstacle_points.size():
				var clear: float = probe.distance_to(perception.obstacle_points[o]) - perception.obstacle_radii[o] - r * 0.8
				if clear < 0.0:
					d = maxf(d, weight)
					break
		_danger[i] = clampf(d, 0.0, 1.0)


## Best direction for `desired` given the cached danger map.
func choose(desired: Vector2, heading: Vector2) -> Vector2:
	var want: Vector2 = desired if desired.length_squared() > 0.0001 else heading
	var scores := PackedFloat32Array()
	scores.resize(DIRECTIONS)
	var best: int = 0
	for i: int in DIRECTIONS:
		var interest: float = maxf(_dirs[i].dot(want), 0.0) + 0.12 * maxf(_dirs[i].dot(heading), 0.0)
		var s: float = interest - _danger[i] * DANGER_WEIGHT
		if _danger[i] >= BLOCKED:
			s -= 2.0
		scores[i] = s
		if s > scores[best]:
			best = i
	# Blend with neighbours that are nearly as good: smooth, non-quantised turns.
	var out: Vector2 = _dirs[best]
	for offset: int in [-1, 1]:
		var j: int = (best + offset + DIRECTIONS) % DIRECTIONS
		var share: float = clampf(1.0 - (scores[best] - scores[j]) * 3.0, 0.0, 1.0) * 0.5
		out += _dirs[j] * share
	return out.normalized()
