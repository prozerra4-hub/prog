class_name LeaderboardSystem
extends RefCounted
## Ranks contestants (player + AI; the boss is not a contestant) by level.
## Refreshes on a fixed interval rather than every frame.

signal updated(entries: Array[LeaderboardEntry])
signal rank_changed(actor: SnakeActor, old_rank: int, new_rank: int)

const REFRESH_SEC: float = 0.25

var _contestants: Array[SnakeActor] = []
var _entries: Array[LeaderboardEntry] = []
var _ranks: Dictionary = {}  # SnakeActor -> int
var _timer: float = 0.0


## Adds a contestant (the boss is not one).
func register(actor: SnakeActor) -> void:
	if not _contestants.has(actor):
		_contestants.append(actor)


func tick(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = REFRESH_SEC
		refresh()


func refresh() -> void:
	var sorted: Array[SnakeActor] = _contestants.duplicate()
	sorted.sort_custom(_compare)
	_entries.clear()
	for i: int in sorted.size():
		var a: SnakeActor = sorted[i]
		var rank: int = i + 1
		var e := LeaderboardEntry.new()
		e.rank = rank
		e.display_name = a.display_name
		e.level = a.stats.level
		e.is_player = a.is_player
		e.alive = a.is_alive
		e.color = a.skin.ui_color
		_entries.append(e)
		var old: int = int(_ranks.get(a, 0))
		if old != rank:
			_ranks[a] = rank
			if old != 0:
				rank_changed.emit(a, old, rank)
	updated.emit(_entries)


## Current 1-based rank of `actor`.
func rank_of(actor: SnakeActor) -> int:
	return int(_ranks.get(actor, _contestants.size()))


## Number of ranked contestants.
func contestant_count() -> int:
	return _contestants.size()


## Last computed rows, best first.
func entries() -> Array[LeaderboardEntry]:
	return _entries


## Higher level first; ties broken by XP, then by stable slot so order never flickers.
static func _compare(a: SnakeActor, b: SnakeActor) -> bool:
	if a.stats.level != b.stats.level:
		return a.stats.level > b.stats.level
	if a.stats.total_xp != b.stats.total_xp:
		return a.stats.total_xp > b.stats.total_xp
	return a.slot < b.slot
