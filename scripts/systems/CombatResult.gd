class_name CombatResult
extends RefCounted
## Everything CombatSystem.resolve() decided this frame.

## Swallows (deaths), in resolution order.
var kills: Array[KillRecord] = []
## Strikes the victims survived (cuts and bites; XP already moved).
var strikes: Array[StrikeRecord] = []
