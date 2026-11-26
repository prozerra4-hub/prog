class_name ShowdownDirector
extends RefCounted
## Runs the final phase: rivals dissolve into a last feast of food, the safe zone
## starts its final closing phase, and the boss turns relentless toward the player.

var active: bool = false

var _cfg: ShowdownConfig
var _zone_cfg: ZoneConfig


func _init(cfg: ShowdownConfig, zone_cfg: ZoneConfig) -> void:
	_cfg = cfg
	_zone_cfg = zone_cfg


## `dissolve` is called for each living rival (turns it into food, no respawn).
func begin(world: WorldContext, respawns: RespawnQueue, dissolve: Callable) -> void:
	active = true
	respawns.cancel_where(func(a: SnakeActor) -> bool: return not a.is_player and not a.is_boss)
	if _cfg.dissolve_rivals:
		for s: SnakeActor in world.snakes:
			if s.is_alive and not s.is_player and not s.is_boss:
				dissolve.call(s)
	if _zone_cfg.final_phase != null:
		world.zone.start_final(_zone_cfg.final_phase)
	if world.boss != null:
		(world.boss.brain as BossController).set_enraged(true, _cfg.enraged_cooldown_multiplier)


## Respawned rivals are not allowed while the showdown runs.
func allows_rival_respawn() -> bool:
	return not active
