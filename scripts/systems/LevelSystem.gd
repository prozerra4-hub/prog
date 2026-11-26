class_name LevelSystem
extends RefCounted
## Owns the XP curve. Snakes store *total* XP; level is derived from it with a
## precomputed cumulative table, so multi-level jumps, penalties and max-level
## clamping are all exact and O(log n).

var max_level: int:
	get: return _curve.max_level

var _curve: LevelCurve
## _cumulative[L] = total XP needed to *reach* level L (index 0 unused, [1] = 0).
var _cumulative: PackedInt64Array = PackedInt64Array()


func _init(curve: LevelCurve) -> void:
	assert(curve != null, "LevelSystem needs a LevelCurve")
	_curve = curve
	_build_table()


## XP needed to go from `level` to `level + 1`.
func required_xp(level: int) -> int:
	var lv: int = clampi(level, 1, _curve.max_level)
	var raw: float = _curve.base_xp + pow(float(lv), _curve.growth_exponent) * _curve.growth_factor
	return maxi(1, int(round(raw)))


## Total XP needed to reach `level`.
func total_xp_for_level(level: int) -> int:
	return _cumulative[clampi(level, 1, _curve.max_level)]


## Total XP at the max level.
func max_total_xp() -> int:
	return _cumulative[_curve.max_level]


## Level for a total XP (binary search over the cumulative table).
func level_for_total_xp(total_xp: int) -> int:
	if total_xp <= 0:
		return 1
	if total_xp >= _cumulative[_curve.max_level]:
		return _curve.max_level
	# Largest L with _cumulative[L] <= total_xp.
	var lo: int = 1
	var hi: int = _curve.max_level
	while lo < hi:
		var mid: int = (lo + hi + 1) >> 1
		if _cumulative[mid] <= total_xp:
			lo = mid
		else:
			hi = mid - 1
	return lo


## Progress (0..1) from the current level towards the next one.
func level_progress(total_xp: int) -> float:
	var lv: int = level_for_total_xp(total_xp)
	if lv >= _curve.max_level:
		return 1.0
	var start: int = _cumulative[lv]
	var span: int = _cumulative[lv + 1] - start
	return clampf(float(total_xp - start) / float(span), 0.0, 1.0)


func _build_table() -> void:
	_cumulative.resize(_curve.max_level + 1)
	_cumulative[0] = 0
	_cumulative[1] = 0
	for lv: int in range(2, _curve.max_level + 1):
		_cumulative[lv] = _cumulative[lv - 1] + required_xp(lv - 1)
