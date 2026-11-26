class_name GameSession
extends Node2D
## Runs one match: builds the systems and drives the fixed per-frame order:
##   clock -> zone -> snakes simulate -> spatial index -> food -> combat
##   -> consequences -> zone erosion -> leaderboard -> respawns -> draw order
## Collaborators own the details:
##   MatchDirector       clock, REGULAR -> SHOWDOWN -> OVER, outcome
##   ZoneSystem          battle-royale safe zone (wait -> shrink phases)
##   ZoneErosion         burns snakes that stay outside the zone
##   ShowdownDirector    final phase (feast, final zone phase, enraged boss)
##   CombatConsequences  food, rewards, revives and respawns after combat
##   MatchFeedback       VFX / sound / shake reactions (never changes gameplay)
## Everything that happens is published as a signal; UI only subscribes.
## Attract mode (main-menu background): no player, no clock, endless.

signal game_started
signal game_paused
signal game_resumed
signal game_over(result: MatchResult)
signal phase_changed(phase: MatchDirector.Phase)
signal level_up(actor: SnakeActor, old_level: int, new_level: int)
signal food_collected(actor: SnakeActor, xp: int)
@warning_ignore("unused_signal")  # emitted by CombatConsequences
signal snake_struck(striker: SnakeActor, victim: SnakeActor, kind: StrikeRecord.Kind, xp_taken: int, at: Vector2)
@warning_ignore("unused_signal")  # emitted by CombatConsequences
signal snake_died(victim: SnakeActor, killer: SnakeActor)
signal snake_eroded(actor: SnakeActor, xp_lost: int)
signal strike_blocked(striker: SnakeActor, target: SnakeActor, at: Vector2)
signal snake_respawned(actor: SnakeActor)
@warning_ignore("unused_signal")  # emitted by CombatConsequences
signal combat_resolved(winner: SnakeActor, loser: SnakeActor)
signal boss_spawned(boss: SnakeActor)
@warning_ignore("unused_signal")  # emitted by CombatConsequences
signal boss_defeated(by: SnakeActor)
signal rank_changed(actor: SnakeActor, old_rank: int, new_rank: int)
signal leaderboard_updated(entries: Array[LeaderboardEntry])
signal time_changed(seconds_left: int)
signal revives_changed(revives_left: int)
@warning_ignore("unused_signal")  # emitted by CombatConsequences
signal player_respawn_scheduled(delay_sec: float)

const DEFAULT_BALANCE: String = "res://resources/balance/GameBalance.tres"
## Simulation step cap: a long frame never tunnels snakes through each other.
const MAX_STEP: float = 1.0 / 30.0

@export var balance: GameBalance

var world := WorldContext.new()
var levels: LevelSystem
var combat: CombatSystem
var spawner: SpawnSystem
var leaderboard := LeaderboardSystem.new()
var scorer: ScoreSystem
var states := GameStateMachine.new()
var respawns := RespawnQueue.new()
var director: MatchDirector
var zone: ZoneSystem
var erosion: ZoneErosion
var showdown: ShowdownDirector
var consequences: CombatConsequences
var feedback: MatchFeedback
var player: SnakeActor
var boss: SnakeActor
var attract_mode: bool = false
var revives_left: int = 0
var elapsed: float = 0.0

## Regular-phase or showdown seconds left (whichever is running).
var time_left: float:
	get: return director.time_left
	set(value): director.time_left = value

var _input := PlayerInputSource.new()
var _player_alive_sec: float = 0.0
var _boss_defeated: bool = false
var _draw_order := DrawOrderSorter.new()
var _attract_camera: AttractCamera

@onready var arena_floor: ArenaFloor = $ArenaFloor
@onready var food: FoodField = $FoodField
@onready var snakes_root: Node2D = $Snakes
@onready var zone_renderer: ZoneRenderer = $ZoneRenderer
@onready var vfx: VfxLayer = $Vfx
@onready var camera: GameCamera = $GameCamera


func _ready() -> void:
	if balance == null:
		balance = load(DEFAULT_BALANCE) as GameBalance
	assert(balance != null, "GameSession: GameBalance resource missing")
	world.rng = RandomNumberGenerator.new()
	world.rng.randomize()
	levels = LevelSystem.new(balance.level_curve)
	world.arena = ArenaSystem.new(balance.arena)
	world.index = SnakeSpatialIndex.new()
	world.food = food
	zone = ZoneSystem.new(balance.arena.radius, world.rng)
	world.zone = zone
	erosion = ZoneErosion.new(balance.zone)
	erosion.eroded.connect(func(a: SnakeActor, xp: int) -> void: snake_eroded.emit(a, xp))
	world.rules = balance.combat
	combat = CombatSystem.new(balance.combat)
	spawner = SpawnSystem.new(balance, levels, world.arena, world.rng)
	spawner.set_zone(zone)
	scorer = ScoreSystem.new(balance.score)
	director = MatchDirector.new(balance.match_duration_sec, balance.showdown.duration_sec)
	director.time_changed.connect(func(sec: int) -> void: time_changed.emit(sec))
	director.phase_changed.connect(_on_phase_changed)
	director.finished.connect(_finish)
	showdown = ShowdownDirector.new(balance.showdown, balance.zone)
	consequences = CombatConsequences.new(self)
	leaderboard.updated.connect(func(e: Array[LeaderboardEntry]) -> void: leaderboard_updated.emit(e))
	leaderboard.rank_changed.connect(func(a: SnakeActor, o: int, n: int) -> void: rank_changed.emit(a, o, n))
	arena_floor.setup(world.arena)
	zone_renderer.setup(zone, balance.arena.radius)
	food.setup(balance.food, world.arena, zone, world.rng)
	food.food_collected.connect(func(a: SnakeActor, xp: int, _at: Vector2, _special: bool) -> void: food_collected.emit(a, xp))
	camera.setup(balance.camera)
	camera.shake_enabled = Services.settings.screen_shake
	feedback = MatchFeedback.new(self, vfx, camera, food)
	combat.bounced.connect(feedback.on_bounce)
	combat.blocked.connect(func(st: SnakeActor, t: SnakeActor, at: Vector2) -> void: strike_blocked.emit(st, t, at))
	_attract_camera = AttractCamera.new(camera)


## Starts a match. `player_skin == null` starts attract mode (menu background).
func start(player_skin: SnakeSkin) -> void:
	attract_mode = player_skin == null
	revives_left = balance.revive_count

	boss = spawner.create_boss(snakes_root)
	_register(boss)
	world.boss = boss
	boss.spawn(_boss_spawn_point(), randf() * TAU, balance.boss.level, 0.0)
	(boss.brain as BossController).charge_windup_started.connect(feedback.on_boss_windup)

	if not attract_mode:
		player = spawner.create_player(snakes_root, player_skin, _input)
		_register(player)
		world.player = player
		world.index.rebuild(world.snakes)
		var p: Vector2 = spawner.find_safe_point(world.index, boss.head_position(), 1800.0)
		player.spawn(p, spawner.spawn_heading(p), 1, balance.combat.respawn_invulnerable_sec)
		camera.follow(player, true)

	for i: int in balance.ai_count:
		var ai: SnakeActor = spawner.create_ai(snakes_root, i)
		_register(ai)
		world.index.rebuild(world.snakes)
		var at: Vector2 = spawner.find_safe_point(world.index)
		ai.spawn(at, spawner.spawn_heading(at), spawner.ai_start_level(), 0.0)

	world.index.rebuild(world.snakes)
	food.populate(world.index)
	leaderboard.refresh()
	if attract_mode:
		_attract_camera.retarget(world.snakes)
	else:
		zone.start(balance.zone.phases)
	states.transition(GameStateMachine.State.PLAYING)
	boss_spawned.emit(boss)
	revives_changed.emit(revives_left)
	game_started.emit()


## Pauses the match (tree paused; pause menu opens via game_paused).
func pause() -> void:
	if states.transition(GameStateMachine.State.PAUSED):
		get_tree().paused = true
		game_paused.emit()


## Resumes a paused match.
func resume() -> void:
	if states.transition(GameStateMachine.State.PLAYING):
		get_tree().paused = false
		game_resumed.emit()


## True while paused.
func is_paused() -> bool:
	return states.state == GameStateMachine.State.PAUSED


## True while the match is being played (not paused or ended).
func is_running() -> bool:
	return states.is_playing()


## Whole seconds left on the running clock (regular or showdown).
func seconds_left() -> int:
	return director.seconds_left()


## True during the final boss phase.
func is_showdown() -> bool:
	return director.is_showdown()


## Records that the player defeated the boss (for the result).
func mark_boss_defeated() -> void:
	_boss_defeated = true


func _process(delta: float) -> void:
	if not states.is_playing():
		return
	var dt: float = minf(delta, MAX_STEP)
	elapsed += dt
	if not attract_mode:
		if player != null and player.is_alive and not director.is_ending():
			_player_alive_sec += dt
		director.tick(dt)
		zone.tick(dt)
	for s: SnakeActor in world.snakes:
		s.simulate(dt, world)
	world.index.rebuild(world.snakes)
	food.update(dt, world)
	consequences.apply(combat.resolve(world))
	if not attract_mode:
		for burnt: SnakeActor in erosion.tick(dt, world.snakes, zone, balance.combat.swallow_floor_level):
			consequences.apply_kill(KillRecord.new(burnt, null, burnt.head_position()))
	leaderboard.tick(dt)
	respawns.tick(dt, _respawn)
	if boss != null and boss.is_alive:
		boss.set_aura_boost((boss.brain as BossController).windup_intensity())
	_draw_order.tick(dt, world.snakes, snakes_root)
	if attract_mode:
		_attract_camera.tick(dt, world.snakes)


func _on_phase_changed(phase: MatchDirector.Phase) -> void:
	if phase == MatchDirector.Phase.SHOWDOWN:
		showdown.begin(world, respawns, consequences.dissolve)
	phase_changed.emit(phase)


func _respawn(actor: SnakeActor) -> void:
	var at: Vector2
	var level: int
	var invuln: float = 0.0
	if actor.is_player:
		actor.stats.apply_xp_penalty(balance.combat.respawn_xp_keep_ratio, balance.combat.respawn_peak_floor_ratio)
		level = actor.stats.level
		at = spawner.find_safe_point(world.index, boss.head_position() if boss.is_alive else Vector2.INF, 900.0)
		# Respawn invulnerability covers the trip if the zone is mid-shrink.
		invuln = balance.showdown.respawn_invulnerable_sec if director.is_showdown() else balance.combat.respawn_invulnerable_sec
	elif actor.is_boss:
		level = balance.boss.level
		at = _boss_spawn_point()
	else:
		var ref_level: int = player.stats.level if player != null else _median_ai_level()
		level = spawner.ai_respawn_level(ref_level)
		actor.stats.total_xp = 0
		at = spawner.find_safe_point(world.index)
	actor.spawn(at, spawner.spawn_heading(at), level, invuln)
	snake_respawned.emit(actor)


func _finish(outcome: MatchResult.Outcome) -> void:
	if not states.transition(GameStateMachine.State.ENDED):
		return
	leaderboard.refresh()
	var r := MatchResult.new()
	r.outcome = outcome
	r.final_level = player.stats.level
	r.peak_level = player.stats.peak_level
	r.final_rank = leaderboard.rank_of(player)
	r.participants = leaderboard.contestant_count()
	r.kills = player.stats.kills
	r.food_eaten = player.stats.food_eaten
	r.survival_sec = _player_alive_sec
	r.boss_defeated = _boss_defeated
	r.score = scorer.compute(r)
	Services.audio.play(AudioService.Sfx.MATCH_END)
	game_over.emit(r)


func _register(actor: SnakeActor) -> void:
	world.snakes.append(actor)
	actor.leveled_up.connect(func(a: SnakeActor, old_level: int, new_level: int) -> void:
		if a.is_alive:  # a level set during (re)spawn is not a level-up
			level_up.emit(a, old_level, new_level))
	if not actor.is_boss:
		leaderboard.register(actor)


func _boss_spawn_point() -> Vector2:
	var away_from: Vector2 = player.head_position() if player != null else Vector2.ZERO
	var best: Vector2 = Vector2.ZERO
	var best_d: float = -1.0
	for i: int in 12:
		var p: Vector2 = zone.random_point(world.rng, balance.boss.patrol_radius_ratio * 0.8)
		var d: float = p.distance_to(away_from)
		if d > best_d:
			best_d = d
			best = p
	return best


func _median_ai_level() -> int:
	var lv: Array[int] = []
	for s: SnakeActor in world.snakes:
		if not s.is_boss:
			lv.append(s.stats.level)
	if lv.is_empty():
		return 1
	lv.sort()
	return lv[lv.size() >> 1]
