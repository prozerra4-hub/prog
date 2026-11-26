class_name SnakeCut
extends RefCounted
## Result of cutting a snake's body (SnakeActor.cut_at).

var xp_lost: int = 0
## Positions of the beads that fell off.
var severed := PackedVector2Array()
