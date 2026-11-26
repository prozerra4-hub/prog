class_name DrawOrderSorter
extends RefCounted
## Keeps bigger snakes drawn over smaller ones (the player wins ties).
## Re-sorts on an interval, not every frame.

const INTERVAL_SEC: float = 0.5

var _timer: float = 0.0


func tick(delta: float, snakes: Array[SnakeActor], parent: Node) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = INTERVAL_SEC
	var ordered: Array[SnakeActor] = snakes.duplicate()
	ordered.sort_custom(func(a: SnakeActor, b: SnakeActor) -> bool:
		if a.stats.level != b.stats.level:
			return a.stats.level < b.stats.level
		return not a.is_player and b.is_player)
	for i: int in ordered.size():
		if ordered[i].get_index() != i:
			parent.move_child(ordered[i], i)
