class_name ZoneErosion
extends RefCounted
## Damages snakes whose head is outside the safe zone: every tick a share of the
## body burns off the tail (no food) and the level drops to match. A snake burnt
## down to the swallow floor dies. Invulnerable snakes (fresh respawns) and,
## optionally, the boss are immune.

signal eroded(actor: SnakeActor, xp_lost: int)

var _cfg: ZoneConfig
var _timer: float = 0.0


func _init(cfg: ZoneConfig) -> void:
	_cfg = cfg


## Returns snakes that burned to death this tick (caller turns them into kills).
func tick(delta: float, snakes: Array[SnakeActor], zone: ZoneSystem, floor_level: int) -> Array[SnakeActor]:
	var dead: Array[SnakeActor] = []
	_timer += delta
	if _timer < _cfg.erosion_tick_sec:
		return dead
	var share: float = _cfg.erosion_per_sec * _timer
	_timer = 0.0
	for s: SnakeActor in snakes:
		if not s.is_alive or s.is_invulnerable() or (s.is_boss and _cfg.boss_immune):
			continue
		if zone.contains(s.head_position()):
			continue
		if s.level_after_cut(1.0 - share) <= floor_level or s.body.count <= 3:
			dead.append(s)
			continue
		var cut: SnakeCut = s.erode(share)
		s.hurt = maxf(s.hurt, 0.6)
		eroded.emit(s, cut.xp_lost)
	return dead
