class_name RespawnQueue
extends RefCounted
## Pending respawns. An entry fires once its delay has passed AND the actor's death
## dissolve has finished, so a snake never pops back mid-animation.

var _entries: Array[Dictionary] = []  # {actor: SnakeActor, t: float}


## Queues `actor` to respawn after `delay` seconds (and its death animation).
func schedule(actor: SnakeActor, delay: float) -> void:
	_entries.append({"actor": actor, "t": delay})


## Drops pending respawns whose actor matches `predicate(actor) -> bool`.
func cancel_where(predicate: Callable) -> void:
	var keep: Array[Dictionary] = []
	for e: Dictionary in _entries:
		if not predicate.call(e["actor"]):
			keep.append(e)
	_entries = keep


## Calls `on_ready(actor)` for every entry that is due, and drops it.
func tick(delta: float, on_ready: Callable) -> void:
	if _entries.is_empty():
		return
	var keep: Array[Dictionary] = []
	var due: Array[SnakeActor] = []
	for e: Dictionary in _entries:
		e["t"] = float(e["t"]) - delta
		var actor: SnakeActor = e["actor"]
		if float(e["t"]) > 0.0 or not actor.is_death_finished():
			keep.append(e)
		else:
			due.append(actor)
	_entries = keep
	for actor: SnakeActor in due:
		on_ready.call(actor)
