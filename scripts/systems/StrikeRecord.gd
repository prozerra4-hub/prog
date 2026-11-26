class_name StrikeRecord
extends RefCounted
## A strike the victim survived (XP and length already removed).

enum Kind { BODY_CUT, HEAD_BITE }

var striker: SnakeActor
var victim: SnakeActor
var kind: Kind
## XP removed from the victim.
var xp_taken: int
## Part of xp_taken scattered as food along the severed body.
var xp_spilled: int
var at: Vector2
## World positions of the beads that were cut off (food goes here).
var severed: PackedVector2Array


func _init(p_striker: SnakeActor, p_victim: SnakeActor, p_kind: Kind, p_taken: int,
		p_spilled: int, p_at: Vector2, p_severed: PackedVector2Array) -> void:
	striker = p_striker
	victim = p_victim
	kind = p_kind
	xp_taken = p_taken
	xp_spilled = p_spilled
	at = p_at
	severed = p_severed
