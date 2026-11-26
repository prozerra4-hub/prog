class_name MatchFeedback
extends RefCounted
## Turns match events into sensory feedback (VFX, sound, camera shake).
## Pure reaction: it subscribes to GameSession / FoodField signals and never
## changes gameplay state. Keeping it here keeps GameSession about rules only.

const LEVEL_UP_FX_COOLDOWN: float = 0.45
const BOSS_WARNING_RANGE: float = 1600.0

var _session: GameSession
var _vfx: VfxLayer
var _camera: GameCamera
var _levelup_ready_at: int = 0


func _init(session: GameSession, vfx: VfxLayer, camera: GameCamera, food: FoodField) -> void:
	_session = session
	_vfx = vfx
	_camera = camera
	session.level_up.connect(_on_level_up)
	session.snake_struck.connect(_on_struck)
	session.snake_died.connect(_on_died)
	session.snake_respawned.connect(_on_respawned)
	session.boss_defeated.connect(_on_boss_defeated)
	food.food_collected.connect(_on_food)


## Small spark where two even heads bounced.
func on_bounce(a: SnakeActor, b: SnakeActor, at: Vector2) -> void:
	_vfx.play(VfxLayer.Fx.BOUNCE, at, maxf(a.head_radius(), b.head_radius()) * 4.0)


## Rumble + shake when the boss winds up a charge near the player.
func on_boss_windup(boss: SnakeActor) -> void:
	var p: SnakeActor = _session.player
	if p != null and p.is_alive and boss.head_position().distance_to(p.head_position()) < BOSS_WARNING_RANGE:
		Services.audio.play(AudioService.Sfx.BOSS_CHARGE)
		_camera.add_shake(0.25)


func _on_level_up(actor: SnakeActor, old_level: int, new_level: int) -> void:
	if not actor.is_player or not actor.is_alive or new_level <= old_level:
		return
	var now: int = Time.get_ticks_msec()
	if now < _levelup_ready_at:
		return
	_levelup_ready_at = now + int(LEVEL_UP_FX_COOLDOWN * 1000.0)
	_vfx.play_following(VfxLayer.Fx.LEVEL_UP, actor.head_position, actor.head_radius() * 6.0)
	Services.audio.play(AudioService.Sfx.LEVEL_UP)


func _on_food(actor: SnakeActor, _xp: int, at: Vector2, special: bool) -> void:
	if not actor.is_player:
		return
	if special:
		_vfx.play(VfxLayer.Fx.RARE_PICKUP, at, actor.head_radius() * 4.0)
		Services.audio.play(AudioService.Sfx.EAT_RARE)
	else:
		Services.audio.play(AudioService.Sfx.EAT, 0.08)


func _on_struck(striker: SnakeActor, victim: SnakeActor, _kind: StrikeRecord.Kind, _xp: int, at: Vector2) -> void:
	_vfx.play(VfxLayer.Fx.KILL_SPARK, at, striker.head_radius() * 3.0)
	if victim.is_player:
		Services.audio.play(AudioService.Sfx.DEATH, 0.1)
		_camera.add_shake(0.45)
	elif striker.is_player:
		Services.audio.play(AudioService.Sfx.KILL, 0.08)
		_camera.add_shake(0.2)


func _on_died(victim: SnakeActor, killer: SnakeActor) -> void:
	var big: float = victim.head_radius()
	_vfx.play(VfxLayer.Fx.DEATH_SMOKE, victim.head_position(), big * 5.0)
	if killer != null:
		_vfx.play(VfxLayer.Fx.KILL_SPARK, victim.head_position(), killer.head_radius() * 4.0)
	if victim.is_boss:
		_vfx.play(VfxLayer.Fx.BOSS_BURST, victim.head_position(), big * 9.0)
	if victim.is_player:
		Services.audio.play(AudioService.Sfx.DEATH)
		_camera.add_shake(0.8)
	elif killer != null and killer.is_player:
		Services.audio.play(AudioService.Sfx.KILL, 0.05)
		_camera.add_shake(0.35)


func _on_respawned(actor: SnakeActor) -> void:
	if actor.is_player:
		_vfx.play_following(VfxLayer.Fx.RESPAWN, actor.head_position, actor.head_radius() * 8.0)
		Services.audio.play(AudioService.Sfx.RESPAWN)


func _on_boss_defeated(_by: SnakeActor) -> void:
	Services.audio.play(AudioService.Sfx.BOSS_DOWN)
	_camera.add_shake(1.0)
