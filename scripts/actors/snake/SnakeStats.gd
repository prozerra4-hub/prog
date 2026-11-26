class_name SnakeStats
extends RefCounted
## Progression data of one snake. Total XP is the single source of truth; level is
## derived from it through LevelSystem.

signal level_changed(old_level: int, new_level: int)

var total_xp: int = 0
var level: int = 1
var kills: int = 0
var food_eaten: int = 0
var deaths: int = 0
var peak_level: int = 1
## Highest total XP reached this match (respawn floor reference).
var peak_xp: int = 0
## Personal growth speed multiplier (AI personalities vary this).
var xp_multiplier: float = 1.0
## Highest level this snake may reach (AI stay below the boss; the boss is fixed).
var level_cap: int

var _levels: LevelSystem


func _init(level_system: LevelSystem) -> void:
	_levels = level_system
	level_cap = level_system.max_level


## Adds XP (scaled by xp_multiplier). Returns the number of levels gained.
func add_xp(amount: int) -> int:
	if amount <= 0:
		return 0
	var scaled: int = maxi(1, int(round(float(amount) * xp_multiplier)))
	return _set_total_xp(total_xp + scaled)


## Sets total XP to the start of `new_level` (clamped by level_cap).
func set_level(new_level: int) -> void:
	_set_total_xp(_levels.total_xp_for_level(new_level))


## Death penalty: keeps `keep_ratio` of the current XP, but never less than
## `peak_floor_ratio` of the best XP reached this match, so being cut down before
## dying does not send you back to nothing.
func apply_xp_penalty(keep_ratio: float, peak_floor_ratio: float = 0.0) -> void:
	var keep: int = int(float(total_xp) * clampf(keep_ratio, 0.0, 1.0))
	var floor_xp: int = int(float(peak_xp) * clampf(peak_floor_ratio, 0.0, 1.0))
	_set_total_xp(maxi(keep, floor_xp))


## Ambient food scaled so one orb is worth the same share of a level at any size:
## base_xp * required_xp(level) / required_xp(1). Keeps food meaningful late game.
func add_food_xp(base_xp: int) -> int:
	var scale: float = float(_levels.required_xp(level)) / float(_levels.required_xp(1))
	return add_xp(maxi(base_xp, int(round(float(base_xp) * scale))))


## Progress from the current level to the next, 0..1.
func progress() -> float:
	return _levels.level_progress(total_xp)


func _set_total_xp(value: int) -> int:
	var ceiling: int = _levels.total_xp_for_level(mini(level_cap, _levels.max_level))
	if level_cap >= _levels.max_level:
		ceiling = _levels.max_total_xp()
	total_xp = clampi(value, 0, ceiling)
	peak_xp = maxi(peak_xp, total_xp)
	var old_level: int = level
	level = _levels.level_for_total_xp(total_xp)
	peak_level = maxi(peak_level, level)
	if level != old_level:
		level_changed.emit(old_level, level)
	return level - old_level
