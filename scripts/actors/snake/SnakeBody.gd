class_name SnakeBody
extends RefCounted
## Geometry of the body for the current frame: bead positions and radii, sampled
## from SnakePathHistory. Rendering *and* collision read these same arrays, so what
## you see is exactly what you hit.
##
## Logical length (from level) and rendered bead count are decoupled: the count is
## capped and the spacing widens instead, so the visible length always matches the
## logical length even at Lv 99999.

## Index 0 = bead right behind the head, last = tail tip.
var positions: PackedVector2Array = PackedVector2Array()
var radii: PackedFloat32Array = PackedFloat32Array()
var count: int = 0
var spacing: float = 0.0
## Logical length in world px.
var length: float = 0.0

## Active swallow bulges: distance (px) travelled from the head.
var _gulps: PackedFloat32Array = PackedFloat32Array()


## Resamples bead positions/radii from the trail for the given radius and length.
func rebuild(path: SnakePathHistory, radius: float, target_length: float,
		tuning: SnakeTuning) -> void:
	length = target_length
	var preferred: float = maxf(radius * tuning.segment_spacing_r, 1.0)
	var wanted: int = maxi(3, int(ceil(length / preferred)))
	count = mini(wanted, tuning.render_segment_cap)
	spacing = length / float(count)
	path.sample_evenly(spacing, count, positions)
	radii.resize(count)

	var taper_n: int = mini(tuning.tail_taper_segments, count - 1)
	var gulp_width: float = radius * tuning.gulp_wave_width_r
	for i: int in count:
		var r: float = radius
		var from_tail: int = count - 1 - i
		if from_tail < taper_n:
			var t: float = float(from_tail) / float(taper_n)
			r *= lerpf(tuning.tail_min_scale, 1.0, sqrt(t))
		if not _gulps.is_empty():
			var d: float = spacing * float(i + 1)
			for g: float in _gulps:
				var x: float = (d - g) / gulp_width
				r *= 1.0 + tuning.gulp_wave_amplitude * exp(-x * x)
		radii[i] = r


## Starts a swallow bulge at the head.
func add_gulp() -> void:
	if _gulps.size() < 6:
		_gulps.append(0.0)


## Moves swallow bulges toward the tail; drops those past the end.
func advance_gulps(delta: float, radius: float, tuning: SnakeTuning) -> void:
	if _gulps.is_empty():
		return
	var speed: float = radius * tuning.gulp_wave_speed_r
	var kept: PackedFloat32Array = PackedFloat32Array()
	for g: float in _gulps:
		var moved: float = g + speed * delta
		if moved < length:
			kept.append(moved)
	_gulps = kept


## Axis-aligned bounds of head + body (for culling and broad-phase).
func bounds(head: Vector2, head_radius: float) -> Rect2:
	var r := Rect2(head, Vector2.ZERO)
	for p: Vector2 in positions:
		r = r.expand(p)
	return r.grow(head_radius)
