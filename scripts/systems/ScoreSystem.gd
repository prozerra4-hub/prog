class_name ScoreSystem
extends RefCounted
## Pure score calculation from a MatchResult and ScoreWeights.

var _w: ScoreWeights


func _init(weights: ScoreWeights) -> void:
	_w = weights


## Final score for a result using ScoreWeights.
func compute(r: MatchResult) -> int:
	var total: int = 0
	total += r.final_level * _w.per_level
	total += r.kills * _w.per_kill
	total += r.food_eaten * _w.per_food
	total += int(r.survival_sec) * _w.per_second_alive
	var rank_index: int = r.final_rank - 1
	if rank_index >= 0 and rank_index < _w.rank_bonus.size():
		total += _w.rank_bonus[rank_index]
	if r.boss_defeated:
		total += _w.boss_defeated_bonus
	return total
