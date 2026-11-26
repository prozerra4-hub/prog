class_name CombatSystem
extends RefCounted
## Resolves head contacts once per frame, after every snake has moved.
## Rule (numbers in CombatRules): the FRONT HALF of a head touching any part of a
## LOWER-level snake strikes it:
##   body -> bites a CHUNK out there (size by level gap); the chunk drops as food
##   head -> BITE sized by the level gap
##   neck (front of the body), or a bite that leaves nothing -> SWALLOWED.
## The victim's level always drops to match its remaining length.
## Otherwise: equal heads BOUNCE; every other body or head the head runs into is a
## WALL it SLIDES along (no harm) - including a lower-level snake it cannot strike
## right now (strike cooldown, touched with the side/back of the head).
##   * Shielded (invulnerable) snakes neither strike nor get struck, and are
##     passed through. Only the player can strike the boss.
##   * The boss outside the showdown ignores snakes below its notice level
##     (BossController.will_strike): its head passes through them.
##   * Each snake is struck at most once per frame, in slot order.

signal bounced(a: SnakeActor, b: SnakeActor, at: Vector2)
## A strike that WOULD have landed but the target was shielded (so the UI can say
## why nothing happened).
signal blocked(striker: SnakeActor, target: SnakeActor, at: Vector2)

var _rules: CombatRules
var _mouth_cos: float
var _hits := PackedInt32Array()


func _init(rules: CombatRules) -> void:
	_rules = rules
	_mouth_cos = cos(deg_to_rad(rules.mouth_half_angle_deg))


## Resolves every head contact this frame; returns strikes and swallows.
func resolve(world: WorldContext) -> CombatResult:
	var result := CombatResult.new()
	var struck: Dictionary = {}  # SnakeActor -> true
	var order: Array[SnakeActor] = world.snakes.duplicate()
	order.sort_custom(func(a: SnakeActor, b: SnakeActor) -> bool: return a.slot < b.slot)
	for attacker: SnakeActor in order:
		if not attacker.is_alive or struck.has(attacker) or attacker.is_invulnerable():
			continue
		var hit: Dictionary = _find_strike(attacker, world.index, struck)
		if hit.has("shielded"):
			blocked.emit(attacker, hit["shielded"], hit["pos"])
			hit = {}
		if not hit.is_empty():
			_strike(attacker, hit, result, struck)
			continue
		var touch: Dictionary = _find_touch(attacker, world.index, struck)
		if touch.is_empty():
			continue
		var other: SnakeActor = touch["other"]
		if touch["head_on"] and is_even(attacker, other):
			_bounce(attacker, other)
			bounced.emit(attacker, other, attacker.head_position().lerp(touch["pos"], 0.5))
		elif _is_wall_for(attacker, other):
			_slide(attacker, touch["pos"], touch["reach"])
	return result


## True when `other` stops `attacker`'s head (it slides along instead).
## Everything is solid except what the boss deliberately ignores.
func _is_wall_for(attacker: SnakeActor, other: SnakeActor) -> bool:
	if other.stats.level >= attacker.stats.level:
		return true
	return not attacker.is_boss  # the tyrant ploughs through snakes it ignores


## True when `striker` may strike `victim` right now (ignores geometry).
func can_strike(striker: SnakeActor, victim: SnakeActor) -> bool:
	if not striker.strike_ready() or victim.is_invulnerable():
		return false
	if victim.is_boss and not striker.is_player:
		return false
	if striker.is_boss and not (striker.brain as BossController).will_strike(victim):
		return false  # the tyrant ignores small fry (outside the showdown)
	return float(striker.stats.level) > float(victim.stats.level) * (1.0 + _rules.even_match_ratio)


## True when two levels are an even match (heads bounce).
func is_even(a: SnakeActor, b: SnakeActor) -> bool:
	var hi: float = float(maxi(a.stats.level, b.stats.level))
	var lo: float = float(mini(a.stats.level, b.stats.level))
	return hi <= lo * (1.0 + _rules.even_match_ratio)


## Share of the body a body strike bites off (grows with the level gap).
func body_cut_share(striker_level: int, victim_level: int) -> float:
	var ratio: float = float(striker_level) / float(maxi(victim_level, 1))
	return clampf(_rules.body_cut_base_share + _rules.body_cut_per_ratio * (ratio - 1.0),
			_rules.body_cut_base_share, _rules.body_cut_max_share)


## Share of the victim a head bite takes (capped: a head bite alone never swallows;
## it only kills if it leaves the victim at the swallow floor level).
func bite_fraction(striker_level: int, victim_level: int) -> float:
	var ratio: float = float(striker_level) / float(maxi(victim_level, 1))
	var raw: float = _rules.bite_base_fraction + _rules.bite_fraction_per_ratio * maxf(ratio - 1.0, 0.0)
	return minf(raw, _rules.head_bite_max_share)


## XP a swallow of `victim` is worth.
func kill_reward(victim: SnakeActor) -> int:
	return kill_reward_for_xp(victim.stats.total_xp)


## XP a swallow is worth for a victim with `victim_total_xp`.
func kill_reward_for_xp(victim_total_xp: int) -> int:
	return int(float(victim_total_xp) * _rules.kill_xp_ratio) + _rules.kill_flat_xp


## XP dropped as food along a swallowed victim.
func remains_xp(victim: SnakeActor) -> int:
	return int(float(victim.stats.total_xp) * _rules.remains_xp_ratio)


## In the showdown (boss enraged) the player may cut the boss's weak-spot bands
## whatever the levels. Before that, the boss can only be cut by out-levelling it.
func _weak_spot_hit(attacker: SnakeActor, other: SnakeActor, part: int) -> bool:
	if not (attacker.is_player and other.is_boss and attacker.strike_ready()):
		return false
	var boss_brain := other.brain as BossController
	return boss_brain != null and boss_brain.enraged and not other.is_invulnerable() and other.is_weak_spot(part)


## True when `point` lies inside `actor`'s mouth arc (front of the head).
func in_mouth_arc(actor: SnakeActor, point: Vector2) -> bool:
	var to: Vector2 = point - actor.head_position()
	var d: float = to.length()
	if d < 0.001:
		return true
	return actor.heading().dot(to / d) >= _mouth_cos


func _strike(striker: SnakeActor, hit: Dictionary, result: CombatResult, struck: Dictionary) -> void:
	var victim: SnakeActor = hit["other"]
	var at: Vector2 = hit["pos"]
	struck[victim] = true
	striker.start_strike_cooldown(_rules.strike_cooldown_sec)
	var count: int = maxi(victim.body.count, 1)
	var kind: StrikeRecord.Kind
	var share: float
	var chunk_from: int
	if hit["head_on"]:
		kind = StrikeRecord.Kind.HEAD_BITE
		share = bite_fraction(striker.stats.level, victim.stats.level)
		chunk_from = 0
	else:
		kind = StrikeRecord.Kind.BODY_CUT
		chunk_from = hit["part"]
		if float(chunk_from) / float(count) < _rules.neck_cut_ratio:
			share = 1.0  # neck strike: swallowed whole
		else:
			share = body_cut_share(striker.stats.level, victim.stats.level)
	if share >= 1.0 or victim.level_after_cut(1.0 - share) <= _rules.swallow_floor_level:
		result.kills.append(KillRecord.new(victim, striker, at))
		return
	var cut: SnakeCut = victim.bite_chunk(chunk_from, share)
	var gained: int = int(float(cut.xp_lost) * _rules.cut_gain_ratio)
	var spilled: int = int(float(cut.xp_lost) * _rules.cut_spill_ratio)
	striker.stats.add_xp(gained)
	var away: Vector2 = (victim.head_position() - striker.head_position()).normalized()
	if away == Vector2.ZERO:
		away = -victim.heading()
	victim.on_struck(away, _rules.struck_invulnerable_sec, _rules.escape_burst_speed, _rules.escape_burst_sec)
	result.strikes.append(StrikeRecord.new(striker, victim, kind, cut.xp_lost, spilled, at, cut.severed))


## Pushes the head out of a body it ran into and removes the inward motion.
func _slide(attacker: SnakeActor, obstacle: Vector2, reach: float) -> void:
	var m: SnakeMovement = attacker.movement
	var to_obstacle: Vector2 = obstacle - m.position
	var d: float = to_obstacle.length()
	var n: Vector2 = to_obstacle / d if d > 0.001 else attacker.heading()
	m.position = obstacle - n * reach
	m.slide_along(n)
	m.speed *= _rules.slide_speed_keep


func _bounce(a: SnakeActor, b: SnakeActor) -> void:
	var n: Vector2 = (a.head_position() - b.head_position()).normalized()
	if n == Vector2.ZERO:
		n = -a.heading()
	a.movement.deflect(n)
	b.movement.deflect(-n)
	a.grant_invulnerability(_rules.bounce_invulnerable_sec)
	b.grant_invulnerability(_rules.bounce_invulnerable_sec)


## Deepest strikable part touched by the front half of `attacker`'s head.
## If the only candidates were shielded, returns {"shielded": target, "pos": p}.
func _find_strike(attacker: SnakeActor, index: SnakeSpatialIndex, struck: Dictionary) -> Dictionary:
	if not attacker.strike_ready():
		return {}
	var head: Vector2 = attacker.head_position()
	var mouth_r: float = attacker.head_radius() * _rules.mouth_scale
	var mouth: Vector2 = head
	_hits.clear()
	index.query(mouth, mouth_r, _hits)
	var best: Dictionary = {}
	var best_pen: float = 0.0
	var shielded: Dictionary = {}
	for h: int in _hits:
		var other: SnakeActor = index.actor_of(h)
		if other == null or other == attacker or struck.has(other):
			continue
		var part: int = SnakeSpatialIndex.part_of(h)
		var head_on: bool = part == SnakeSpatialIndex.HEAD
		var p: Vector2 = SnakeSpatialIndex.part_position(other, part)
		if not in_mouth_arc(attacker, p):
			continue
		var r: float = SnakeSpatialIndex.part_radius(other, part) * (_rules.head_target_scale if head_on else _rules.body_hit_scale)
		var pen: float = (mouth_r + r) - mouth.distance_to(p)
		if pen <= 0.0:
			continue
		if not can_strike(attacker, other) and not _weak_spot_hit(attacker, other, part):
			if other.is_invulnerable() and attacker.stats.level > other.stats.level and shielded.is_empty():
				shielded = {"shielded": other, "pos": p}
			continue
		if pen > best_pen:
			best_pen = pen
			best = {"other": other, "head_on": head_on, "pos": p, "part": part}
	return best if not best.is_empty() else shielded


## Deepest plain overlap of `attacker`'s head with another snake (for slide/bounce).
func _find_touch(attacker: SnakeActor, index: SnakeSpatialIndex, struck: Dictionary) -> Dictionary:
	var head: Vector2 = attacker.head_position()
	var my_r: float = attacker.head_radius() * _rules.head_target_scale
	_hits.clear()
	index.query(head, my_r, _hits)
	var best: Dictionary = {}
	var best_pen: float = 0.0
	for h: int in _hits:
		var other: SnakeActor = index.actor_of(h)
		if other == null or other == attacker or struck.has(other) or other.is_invulnerable():
			continue
		var part: int = SnakeSpatialIndex.part_of(h)
		var head_on: bool = part == SnakeSpatialIndex.HEAD
		var p: Vector2 = SnakeSpatialIndex.part_position(other, part)
		var r: float = SnakeSpatialIndex.part_radius(other, part) * (_rules.head_target_scale if head_on else _rules.body_hit_scale)
		var reach: float = my_r + r
		var pen: float = reach - head.distance_to(p)
		if pen > best_pen:
			best_pen = pen
			best = {"other": other, "head_on": head_on, "pos": p, "reach": reach}
	return best
