class_name KillRecord
extends RefCounted
## A swallow (death) produced by CombatSystem, or an externally forced death.

var victim: SnakeActor
## null when nobody gets the credit.
var killer: SnakeActor
var at: Vector2


func _init(p_victim: SnakeActor, p_killer: SnakeActor, p_at: Vector2) -> void:
	victim = p_victim
	killer = p_killer
	at = p_at
