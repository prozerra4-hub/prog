class_name SpawnSystem
extends RefCounted
## Creates snakes and chooses where/at what level they (re)appear.
## It does not run them; GameSession owns the simulation order.

const SNAKE_SCENE: PackedScene = preload("res://scenes/actors/snake/SnakeActor.tscn")

var _balance: GameBalance
var _levels: LevelSystem
var _arena: ArenaSystem
var _zone: ZoneSystem
var _rng: RandomNumberGenerator
var _next_slot: int = 0


func _init(balance: GameBalance, levels: LevelSystem, arena: ArenaSystem, rng: RandomNumberGenerator) -> void:
	_balance = balance
	_levels = levels
	_arena = arena
	_rng = rng


## Creates the player snake (not yet spawned).
func create_player(parent: Node, skin: SnakeSkin, input: PlayerInputSource) -> SnakeActor:
	return _create(parent, SnakeActor.Role.PLAYER, "You", skin, PlayerBrain.new(input), 1.0, 1.0, 1.0)


## Creates rival #`index` with its name, skin, personality and small random variation.
func create_ai(parent: Node, index: int) -> SnakeActor:
	var names: PackedStringArray = _balance.ai_names
	var display: String = names[index % names.size()] if not names.is_empty() else "Rival %d" % (index + 1)
	var skin: SnakeSkin = _balance.ai_skins[index % _balance.ai_skins.size()]
	var personality: AIPersonality = _balance.ai_personalities[index % _balance.ai_personalities.size()]
	var brain := SnakeAIController.new(personality, _rng.randi())
	# Small per-snake variation so no two rivals move identically.
	var speed: float = personality.speed_multiplier * _rng.randf_range(0.94, 1.06)
	var xp_mult: float = personality.xp_multiplier * _rng.randf_range(0.9, 1.1)
	return _create(parent, SnakeActor.Role.AI, display, skin, brain, speed, 1.0, xp_mult)


## Creates the boss from the BossDefinition (fixed level, short body, weak spots).
func create_boss(parent: Node) -> SnakeActor:
	var def: BossDefinition = _balance.boss
	var brain := BossController.new(def, _rng.randi())
	return _create(parent, SnakeActor.Role.BOSS, def.display_name, def.skin, brain,
			def.speed_multiplier, def.turn_multiplier, 1.0)


## A point far from every live snake, inside the safe zone the arena is heading
## to (the NEXT circle, so a spawn is never about to be swallowed by a shrink).
## Falls back to the best candidate found.
func find_safe_point(index: SnakeSpatialIndex, avoid: Vector2 = Vector2.INF, avoid_radius: float = 0.0) -> Vector2:
	var cfg: ArenaConfig = _arena.config
	var best: Vector2 = Vector2.ZERO
	var best_clear: float = -1.0
	for i: int in cfg.safe_spawn_samples:
		var p: Vector2 = _zone.random_point(_rng, cfg.spawn_radius_ratio, true) if _zone != null else _arena.random_point(_rng, cfg.spawn_radius_ratio)
		var clear: float = index.clearance(p, cfg.safe_spawn_clearance)
		if avoid != Vector2.INF:
			clear = minf(clear, p.distance_to(avoid) - avoid_radius)
		if clear > best_clear:
			best_clear = clear
			best = p
		if clear >= cfg.safe_spawn_clearance:
			break
	return best


## Spawn points follow the safe zone once one exists.
func set_zone(zone: ZoneSystem) -> void:
	_zone = zone


## Heading that points roughly toward the zone centre (never straight into a wall).
func spawn_heading(p: Vector2) -> float:
	var c: Vector2 = _zone.next_center if _zone != null else Vector2.ZERO
	var to_center: Vector2 = c - p if p.distance_squared_to(c) > 1.0 else Vector2.from_angle(_rng.randf() * TAU)
	return to_center.angle() + _rng.randf_range(-0.8, 0.8)


## Random starting level for a rival.
func ai_start_level() -> int:
	return _rng.randi_range(_balance.ai_start_level_min, _balance.ai_start_level_max)


## AI come back scaled to the player so there is always both prey and danger.
func ai_respawn_level(player_level: int) -> int:
	var ratio: float = _rng.randf_range(_balance.ai_respawn_ratio_min, _balance.ai_respawn_ratio_max)
	var cap: int = maxi(1, int(float(_balance.boss.level) * _balance.ai_level_cap_ratio_of_boss))
	return clampi(int(round(float(player_level) * ratio)), 1, cap)


## Highest level a rival may reach (below the boss).
func ai_level_cap() -> int:
	return maxi(1, int(float(_balance.boss.level) * _balance.ai_level_cap_ratio_of_boss))


func _create(parent: Node, role: SnakeActor.Role, display: String, skin: SnakeSkin,
		brain: SnakeBrain, speed_mult: float, turn_mult: float, xp_mult: float) -> SnakeActor:
	var actor: SnakeActor = SNAKE_SCENE.instantiate()
	parent.add_child(actor)
	actor.configure(_next_slot, role, display, skin, _balance.snake, _levels, brain)
	actor.speed_multiplier = speed_mult
	actor.turn_multiplier = turn_mult
	actor.stats.xp_multiplier = xp_mult
	# The boss is the apex: its level is fixed and rivals can never reach it.
	match role:
		SnakeActor.Role.AI:
			actor.stats.level_cap = ai_level_cap()
		SnakeActor.Role.BOSS:
			actor.stats.level_cap = _balance.boss.level
			actor.length_multiplier = _balance.boss.length_multiplier
			actor.weak_spot_from_share = _balance.boss.weak_spot_from_share
	_next_slot += 1
	return actor
