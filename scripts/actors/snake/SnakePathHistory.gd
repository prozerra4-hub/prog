class_name SnakePathHistory
extends RefCounted
## Trail of points the head has passed through, with cumulative arc length.
## Body beads are placed by sampling this trail at fixed distances behind the head,
## so every bead follows exactly the route the head took.
##
## Memory is bounded: points older than the current body length (plus margin) are
## trimmed in batches, so path size depends on body length / step, not on play time.

const TRIM_BATCH: int = 64

## Oldest -> newest recorded points. The live head position is *not* stored here.
var _points: PackedVector2Array = PackedVector2Array()
## Arc length of each recorded point measured from an arbitrary origin.
var _dist: PackedFloat64Array = PackedFloat64Array()
var _head: Vector2 = Vector2.ZERO
var _head_dist: float = 0.0


## Restarts the trail as a straight line of `prefill_length` behind `head`.
func reset(head: Vector2, heading: Vector2, prefill_length: float, step: float) -> void:
	_points.clear()
	_dist.clear()
	var dir: Vector2 = heading.normalized() if heading.length_squared() > 0.0 else Vector2.RIGHT
	var safe_step: float = maxf(step, 1.0)
	var count: int = int(ceil(prefill_length / safe_step)) + 1
	# Lay the trail out straight behind the head so the body appears fully formed.
	for i: int in range(count, 0, -1):
		_points.append(head - dir * safe_step * float(i))
		_dist.append(-safe_step * float(i))
	_head = head
	_head_dist = 0.0


## Moves the head. Records a trail point once the head has travelled `step`.
func push_head(new_head: Vector2, step: float) -> void:
	_head_dist += _head.distance_to(new_head)
	_head = new_head
	if _points.is_empty() or _dist[_dist.size() - 1] <= _head_dist - step:
		_points.append(_head)
		_dist.append(_head_dist)


## Drops trail points further than `keep_length` behind the head.
func trim(keep_length: float) -> void:
	var cutoff: float = _head_dist - keep_length
	var n: int = _dist.size()
	if n < TRIM_BATCH * 2 or _dist[TRIM_BATCH] >= cutoff:
		return
	# Find how many leading points are entirely behind the cutoff (keep one before it).
	var drop: int = 0
	while drop + 1 < n and _dist[drop + 1] < cutoff:
		drop += 1
	if drop >= TRIM_BATCH:
		_points = _points.slice(drop)
		_dist = _dist.slice(drop)


## Fills `out_pos` with positions at distances `spacing * i` (i = 1..count) behind
## the head, walking the trail once (O(points + count)).
## Returns how many samples were placed (fewer if the trail is shorter).
func sample_evenly(spacing: float, count: int, out_pos: PackedVector2Array) -> int:
	out_pos.resize(count)
	if count == 0:
		return 0
	var idx: int = _points.size() - 1
	# Current segment runs from point[idx] (older) to `seg_end` (newer).
	var seg_end: Vector2 = _head
	var seg_end_dist: float = _head_dist
	var placed: int = 0
	for i: int in range(1, count + 1):
		var target: float = _head_dist - spacing * float(i)
		while idx >= 0 and _dist[idx] > target:
			seg_end = _points[idx]
			seg_end_dist = _dist[idx]
			idx -= 1
		if idx < 0:
			# Trail shorter than the body (sudden growth): continue straight back
			# from the oldest recorded direction instead of piling beads up.
			_extrapolate_tail(spacing, placed, count, out_pos)
			return count
		var seg_start_dist: float = _dist[idx]
		var span: float = seg_end_dist - seg_start_dist
		var t: float = 0.0 if span <= 0.000001 else (target - seg_start_dist) / span
		out_pos[placed] = _points[idx].lerp(seg_end, t)
		placed += 1
	return placed


func _extrapolate_tail(spacing: float, from: int, count: int, out_pos: PackedVector2Array) -> void:
	var origin: Vector2 = _head
	var origin_dist: float = _head_dist
	var back: Vector2 = Vector2.LEFT
	if not _points.is_empty():
		origin = _points[0]
		origin_dist = _dist[0]
		var newer: Vector2 = _points[1] if _points.size() > 1 else _head
		var d: Vector2 = origin - newer
		if d.length_squared() > 0.0001:
			back = d.normalized()
	for j: int in range(from, count):
		var target: float = _head_dist - spacing * float(j + 1)
		out_pos[j] = origin + back * (origin_dist - target)


## Number of stored trail points (memory check).
func point_count() -> int:
	return _points.size()


## Length of trail currently stored behind the head.
func stored_length() -> float:
	if _dist.is_empty():
		return 0.0
	return _head_dist - _dist[0]
