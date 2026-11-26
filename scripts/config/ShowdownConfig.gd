class_name ShowdownConfig
extends Resource
## The final phase that starts when the regular clock runs out: rivals dissolve
## into food, the safe zone plays its final (closing) phase, and the enraged boss
## comes for the player. The match ends when the boss falls, the player runs out
## of revives, or the showdown clock expires.

@export var duration_sec: float = 60.0
## Rivals turn into food when the showdown begins (a last feast before the fight).
@export var dissolve_rivals: bool = true
## Respawn protection during the showdown (the circle is small and the boss is close).
@export var respawn_invulnerable_sec: float = 5.0
## Boss charge cooldown multiplier while enraged.
@export var enraged_cooldown_multiplier: float = 1.0
