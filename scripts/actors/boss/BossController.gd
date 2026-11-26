class_name BossController
extends SnakeBrain
## Boss brain. Patrols the core of the safe zone, hunts weaker snakes that come near (the
## player first), and periodically performs a telegraphed charge:
##   PATROL -> HUNT -> WINDUP (slows, aura flares) -> CHARGE (burst) -> HUNT/PATROL
## If the player has out-levelled it, the boss turns evasive (RETREAT) so the kill
## must be earned.

signal charge_windup_started(boss: SnakeActor)
signal charge_started(boss: SnakeActor)

enum Mode { PATROL, HUNT, WINDUP, CHARGE, RETREAT }

const RETARGET_SEC: float = 0.3
const WINDUP_SPEED: float = 0.35

var mode: Mode = Mode.PATROL
var target: SnakeActor
## Showdown: hunts the player relentlessly and charges more often.
var enraged: bool = false

var _def: BossDefinition
var _rng := RandomNumberGenerator.new()
var _desired: Vector2 = Vector2.ZERO
var _mode_time: float = 0.0
var _cooldown: float = 0.0
var _retarget: float = 0.0
var _patrol_point: Vector2 = Vector2.ZERO
var _charge_dir: Vector2 = Vector2.RIGHT
var _cooldown_multiplier: float = 1.0


func _init(definition: BossDefinition, seed_value: int) -> void:
	_def = definition
	_rng.seed = seed_value


## Showdown mode: hunt the player relentlessly; charge cooldown scaled by `cooldown_multiplier`.
func set_enraged(on: bool, cooldown_multiplier: float) -> void:
	enraged = on
	_cooldown_multiplier = cooldown_multiplier if on else 1.0
	_retarget = 0.0


func on_spawned(_actor: SnakeActor) -> void:
	mode = Mode.PATROL
	_mode_time = 0.0
	_cooldown = _def.charge_cooldown_sec * 0.5
	target = null


func think(actor: SnakeActor, world: WorldContext, delta: float) -> void:
	_mode_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	_retarget -= delta
	if _retarget <= 0.0 and mode != Mode.CHARGE and mode != Mode.WINDUP:
		_retarget = RETARGET_SEC
		_choose_target(actor, world)
	var head: Vector2 = actor.head_position()
	match mode:
		Mode.PATROL:
			if head.distance_to(_patrol_point) < actor.head_radius() * 6.0 or _mode_time > 6.0:
				_new_patrol_point(world)
			_desired = (_patrol_point - head).normalized()
			if target != null:
				_set_mode(Mode.RETREAT if _target_outranks(actor) else Mode.HUNT)
		Mode.HUNT:
			if target == null or not target.is_alive:
				_set_mode(Mode.PATROL)
				return
			if _target_outranks(actor):
				_set_mode(Mode.RETREAT)
				return
			var lead: Vector2 = target.head_position() + target.heading() * target.current_speed() * 0.5
			_desired = (lead - head).normalized()
			if _cooldown <= 0.0 and head.distance_to(target.head_position()) < _def.charge_trigger_distance:
				_set_mode(Mode.WINDUP)
				charge_windup_started.emit(actor)
		Mode.WINDUP:
			if target != null and target.is_alive:
				_charge_dir = (target.head_position() + target.heading() * target.current_speed() * 0.6 - head).normalized()
				_desired = _charge_dir
			if _mode_time >= _def.charge_windup_sec:
				_set_mode(Mode.CHARGE)
				charge_started.emit(actor)
		Mode.CHARGE:
			_desired = _charge_dir
			if _mode_time >= _def.charge_duration_sec:
				_cooldown = _def.charge_cooldown_sec * _cooldown_multiplier
				_set_mode(Mode.HUNT if target != null else Mode.PATROL)
		Mode.RETREAT:
			if target == null or not target.is_alive or not _target_outranks(actor):
				_set_mode(Mode.PATROL)
				return
			var away: Vector2 = (head - target.head_position()).normalized()
			# Bias back toward the core so it doesn't pin itself on the wall.
			var core_pull: Vector2 = (world.zone.center - head) / maxf(world.zone.radius, 1.0)
			_desired = (away + core_pull * 1.2).normalized()
	_keep_in_core(actor, world)


func desired_direction() -> Vector2:
	return _desired


func speed_factor() -> float:
	match mode:
		Mode.WINDUP:
			return WINDUP_SPEED
		Mode.CHARGE:
			return _def.charge_speed_multiplier
		_:
			return 1.0


func look_target(actor: SnakeActor) -> Vector2:
	if target != null and target.is_alive:
		return target.head_position()
	return actor.head_position() + actor.heading() * 100.0


## 0..1 telegraph intensity for visuals.
func windup_intensity() -> float:
	if mode == Mode.WINDUP:
		return clampf(_mode_time / maxf(_def.charge_windup_sec, 0.01), 0.0, 1.0)
	if mode == Mode.CHARGE:
		return 1.0 - clampf(_mode_time / maxf(_def.charge_duration_sec, 0.01), 0.0, 1.0)
	return 0.0


func _choose_target(actor: SnakeActor, world: WorldContext) -> void:
	if enraged:
		var p: SnakeActor = world.player
		target = p if p != null and p.is_alive and not p.is_invulnerable() else null
		return
	var head: Vector2 = actor.head_position()
	var best: SnakeActor = null
	var best_score: float = INF
	for s: SnakeActor in world.snakes:
		if s == actor or not s.is_alive or s.is_invulnerable():
			continue
		var d: float = head.distance_to(s.head_position())
		if d > _def.aggro_radius:
			continue
		if float(s.stats.level) < float(actor.stats.level) * _def.min_target_level_ratio:
			continue  # not worth the tyrant's attention
		# Territorial: whoever trespasses nearest is the quarry (no player bias).
		if d < best_score:
			best_score = d
			best = s
	target = best


## Whether the boss's mouth hurts `victim` on contact. Outside the showdown it
## ignores small fry (its head passes through them); enraged, it bites anything.
func will_strike(victim: SnakeActor) -> bool:
	return enraged or victim.stats.level >= notice_level()


## Lowest level the calm (pre-showdown) boss bothers to strike.
func notice_level() -> int:
	return ceili(float(_def.level) * _def.min_target_level_ratio)


func _target_outranks(actor: SnakeActor) -> bool:
	return target != null and target.stats.level > actor.stats.level


func _keep_in_core(actor: SnakeActor, world: WorldContext) -> void:
	if mode == Mode.CHARGE or enraged:
		return
	# Stay in the zone's core: patrol_radius_ratio of the full arena, but never
	# beyond most of the current safe zone.
	var limit: float = minf(world.arena.radius * _def.patrol_radius_ratio, world.zone.radius * 0.8)
	var offset: Vector2 = actor.head_position() - world.zone.center
	var d: float = offset.length()
	if d > limit and mode != Mode.RETREAT:
		var back: Vector2 = -offset / d
		var k: float = clampf((d - limit) / (limit * 0.3), 0.0, 1.0)
		_desired = (_desired + back * k * 2.0).normalized()


func _new_patrol_point(world: WorldContext) -> void:
	_patrol_point = world.zone.random_point(_rng, 0.7)
	_mode_time = 0.0


func _set_mode(m: Mode) -> void:
	mode = m
	_mode_time = 0.0
