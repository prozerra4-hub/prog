class_name ScoreWeights
extends Resource
## ScoreSystem weights.

@export var per_level: int = 10
@export var per_kill: int = 250
@export var per_food: int = 2
@export var per_second_alive: int = 5
## Bonus for final rank 1..N (index 0 = rank 1).
@export var rank_bonus: PackedInt32Array = PackedInt32Array([3000, 1800, 1000, 500, 250])
@export var boss_defeated_bonus: int = 10000
