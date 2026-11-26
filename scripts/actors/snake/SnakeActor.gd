class_name SnakeActor
extends Node2D
## A snake. Composition root that wires the components together:
##   SnakeMovement     head kinematics
##   SnakePathHistory  trail of head positions
##   SnakeBody         bead positions/radii sampled from the trail (render + collision)
##   SnakeStats        level / XP / kill counters
##   SnakeBrain        steering source (player input, AI, boss)
##   SnakeBodyRenderer + SnakeFaceRenderer (+ SnakeCrestRenderer for bosses)
## It does not decide combat, spawning or scoring; systems do that.
##
## Positions are world coordinates; this node itself stays at the origin.

signal died(actor: SnakeActor, killer: SnakeActor)
signal leveled_up(actor: SnakeActor, old_level: int, new_level: int)
signal respawned(actor: SnakeActor)

enum Role { PLAYER, AI, BOSS }

const DEATH_ANIM_SEC: float = 0.55

var slot: int = -1
var role: Role = Role.AI
var display_name: String = ""
var skin: SnakeSkin
var stats: SnakeStats
var brain: SnakeBrain
var is_alive: bool = false
## Visual radius of a body bead (smoothly follows the level target).
var radius: float = 15.0
## Personality / boss modifiers.
var speed_multiplier: float = 1.0
var turn_multiplier: float = 1.0
## Body length relative to the level-based length (bosses are chunky, not endless).
var length_multiplier: float = 1.0
## Band beads from this share of the body onward are weak spots (bosses). 2 = none.
var weak_spot_from_share: float = 2.0

var movement := SnakeMovement.new()
var path := SnakePathHistory.new()
var body := SnakeBody.new()

## Brightness flash (decays to 0); drives the shader's brightness channel.
var flash: float = 0.0
## Red "bitten" tint (decays to 0); drives the shader's hurt channel.
var hurt: float = 0.0
## 0 when alive; counts up after death for the dissolve animation.
var death_anim: float = 0.0

var is_player: bool:
	get: return role == Role.PLAYER
var is_boss: bool:
	get: return role == Role.BOSS

var _tuning: SnakeTuning
var _invulnerable_left: float = 0.0
var _strike_cooldown: float = 0.0
## Escape burst after being struck (speed multiplier while > 0).
var _burst_left: float = 0.0
var _burst_speed: float = 1.0
var _length: float = 0.0
## After a cut the body stays short: its target length is capped and the cap only
## grows in proportion to new growth (0 = no cap).
var _cut_cap: float = 0.0
var _cut_cap_level: int = 1

@onready var _renderer: SnakeBodyRenderer = $BodyRenderer


## One-time wiring after instancing: identity, skin, tuning and brain. Call before spawn().
func configure(p_slot: int, p_role: Role, p_name: String, p_skin: SnakeSkin,
		tuning: SnakeTuning, level_system: LevelSystem, p_brain: SnakeBrain) -> void:
	slot = p_slot
	role = p_role
	display_name = p_name
	skin = p_skin
	_tuning = tuning
	brain = p_brain
	stats = SnakeStats.new(level_system)
	stats.level_changed.connect(_on_level_changed)
	name = "Snake_%d_%s" % [slot, p_name.replace(" ", "_")]
	_renderer.setup(self, is_boss)


## Places the snake fully grown at `level` (straight body behind it) and makes it live.
func spawn(pos: Vector2, heading_angle: float, level: int, invulnerable_sec: float) -> void:
	stats.set_level(level)
	radius = _tuning.radius_for_level(stats.level)
	_length = _target_length()
	movement.reset(pos, heading_angle, _target_speed())
	path.reset(pos, Vector2.from_angle(heading_angle), _length + radius * 4.0, _path_step())
	body.rebuild(path, radius, _length, _tuning)
	is_alive = true
	death_anim = 0.0
	flash = 0.0
	hurt = 0.0
	_strike_cooldown = 0.0
	_cut_cap = 0.0
	_invulnerable_left = invulnerable_sec
	visible = true
	brain.on_spawned(self)
	_renderer.refresh()
	respawned.emit(self)


## Advances movement and rebuilds body geometry. Called by GameSession in a fixed order.
func simulate(delta: float, world: WorldContext) -> void:
	if not is_alive:
		_tick_death(delta)
		return
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	_strike_cooldown = maxf(_strike_cooldown - delta, 0.0)
	_burst_left = maxf(_burst_left - delta, 0.0)
	flash = move_toward(flash, 0.0, delta * 3.0)
	hurt = move_toward(hurt, 0.0, delta * 2.2)

	var smooth: float = 1.0 - exp(-_tuning.radius_smoothing * delta)
	radius = lerpf(radius, _tuning.radius_for_level(stats.level), smooth)
	_length = lerpf(_length, _capped_target_length(), smooth)

	brain.think(self, world, delta)
	var turn: float = _tuning.turn_rate_for_radius(radius) * turn_multiplier
	movement.step(brain.desired_direction(), _target_speed() * brain.speed_factor(), turn, _tuning, delta)

	var normal: Vector2 = world.arena.clamp_inside(movement, head_radius())
	if normal != Vector2.ZERO:
		movement.slide_along(normal)

	path.push_head(movement.position, _path_step())
	# Keep history for the length the body is *growing toward*, not just its
	# current length, so a sudden level jump unrolls along the real trail.
	path.trim(maxf(_length, _final_length()) + radius * 6.0)
	body.advance_gulps(delta, radius, _tuning)
	body.rebuild(path, radius, _length, _tuning)
	_renderer.refresh()


## Marks the snake dead (dissolve animation starts) and emits `died`. Idempotent.
func kill(killer: SnakeActor) -> void:
	if not is_alive:
		return
	is_alive = false
	death_anim = 0.0
	stats.deaths += 1
	brain.on_died(self)
	died.emit(self, killer)


## `level_scaled`: ambient food is worth the same share of a level at any size.
func on_food_eaten(xp: int, level_scaled: bool) -> void:
	stats.food_eaten += 1
	if level_scaled:
		stats.add_food_xp(xp)
	else:
		stats.add_xp(xp)
	body.add_gulp()


## Survived a strike: knocked away from the striker, red tint, brief protection
## and an escape burst so a cut snake can get away and eat its spilled food.
func on_struck(away: Vector2, invulnerable_sec: float, burst_speed: float = 1.0, burst_sec: float = 0.0) -> void:
	movement.deflect(away)
	hurt = 1.0
	grant_invulnerability(invulnerable_sec)
	_burst_speed = burst_speed
	_burst_left = burst_sec


## True if bead `index` is a weak spot (a band on the rear part of a boss).
func is_weak_spot(index: int) -> bool:
	var every: int = skin.band_every
	if every <= 0 or index < 0 or index >= body.count:
		return false
	return index % every == every - 1 and float(index) >= float(body.count) * weak_spot_from_share


## True when the strike cooldown has elapsed.
func strike_ready() -> bool:
	return _strike_cooldown <= 0.0


## Starts the post-strike cooldown and a brief brightness flash.
func start_strike_cooldown(sec: float) -> void:
	_strike_cooldown = sec
	flash = maxf(flash, 0.5)


## Level this snake drops to if only `keep_share` of its body remains.
## Size IS strength: the new level is the one whose body length matches what is
## left, so a snake that has been cut short is genuinely weaker in every fight.
func level_after_cut(keep_share: float) -> int:
	var keep_length: float = _final_length() * clampf(keep_share, 0.0, 1.0)
	return mini(stats.level, _tuning.level_for_length(keep_length, stats.level_cap, length_multiplier))


## Cuts the body at bead `index`: beads index..tail fall off (returned so they
## can become food), the level drops to match the remaining length, and the
## drawn body shortens immediately instead of easing.
func cut_at(index: int) -> SnakeCut:
	var cut := SnakeCut.new()
	var count: int = body.count
	var i: int = clampi(index, 1, count)
	cut.severed = body.positions.slice(i, count)
	_shrink(1.0 - float(i) / float(maxi(count, 1)), cut)
	return cut


## Bites `share` of the body out starting at bead `from_index`: those beads are
## returned (they become food where they lay), the body gets that much shorter
## (the tail pulls in along the trail) and the level drops to match.
func bite_chunk(from_index: int, share: float) -> SnakeCut:
	var cut := SnakeCut.new()
	var count: int = body.count
	var s: float = clampf(share, 0.0, 1.0)
	var k: int = maxi(1, int(round(float(count) * s)))
	var i: int = clampi(from_index, 0, maxi(count - 1, 0))
	cut.severed = body.positions.slice(i, mini(i + k, count))
	_shrink(s, cut)
	return cut


## Burns `share` of the body off the tail (outside the safe zone). No food drops.
func erode(share: float) -> SnakeCut:
	var cut := SnakeCut.new()
	_shrink(clampf(share, 0.0, 1.0), cut)
	return cut


## Shortens the body by `share`, drops the level to match and records XP lost.
func _shrink(share: float, cut: SnakeCut) -> void:
	var before: int = stats.total_xp
	stats.set_level(level_after_cut(1.0 - share))
	cut.xp_lost = maxi(before - stats.total_xp, 0)
	_length = maxf(_length * (1.0 - share), 1.0)
	# The radius eases down to the new level; until it does, hold the body at the
	# shortened length so it never visibly regrows.
	_cut_cap = _length
	_cut_cap_level = stats.level
	body.rebuild(path, radius, _length, _tuning)
	_renderer.refresh()


## Credits a swallow: kill count + reward XP + flash.
func on_kill_reward(xp: int) -> void:
	stats.kills += 1
	stats.add_xp(xp)
	flash = 1.0


## Boss telegraph intensity (0..1) for the crest aura.
func set_aura_boost(value: float) -> void:
	_renderer.set_aura_boost(value)


## Extends protection to at least `sec` seconds (never shortens it).
func grant_invulnerability(sec: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left, sec)


## True while protected (shield bubble visible; cannot strike or be struck).
func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


## Seconds of protection remaining.
func invulnerable_left() -> float:
	return _invulnerable_left


## World position of the head centre.
func head_position() -> Vector2:
	return movement.position


## Unit vector the head is facing.
func heading() -> Vector2:
	return movement.heading()


## Drawn head radius (body radius * head_scale).
func head_radius() -> float:
	return radius * _tuning.head_scale


## Current movement speed (px/s).
func current_speed() -> float:
	return movement.speed


## True once the death dissolve has finished (actor can be hidden / respawned).
func is_death_finished() -> bool:
	return not is_alive and death_anim >= DEATH_ANIM_SEC


## Dissolve progress after death, 0..1.
func death_progress() -> float:
	return clampf(death_anim / DEATH_ANIM_SEC, 0.0, 1.0)


func _tick_death(delta: float) -> void:
	if death_anim < DEATH_ANIM_SEC:
		death_anim += delta
		_renderer.refresh()
		if death_anim >= DEATH_ANIM_SEC:
			visible = false


## Target length, held short after a cut until growth catches up.
func _capped_target_length() -> float:
	var target: float = _target_length()
	if _cut_cap <= 0.0:
		return target
	var grown: float = _tuning.full_length_for_level(stats.level) / maxf(_tuning.full_length_for_level(_cut_cap_level), 1.0)
	var cap: float = _cut_cap * grown
	if cap >= target:
		_cut_cap = 0.0
		return target
	return cap


func _target_length() -> float:
	return _tuning.length_r_for_level(stats.level) * radius * length_multiplier


## Length once the radius has also caught up with the current level.
func _final_length() -> float:
	return _tuning.length_r_for_level(stats.level) * _tuning.radius_for_level(stats.level) * length_multiplier


func _target_speed() -> float:
	var burst: float = _burst_speed if _burst_left > 0.0 else 1.0
	return _tuning.speed_for_radius(radius) * speed_multiplier * burst


func _path_step() -> float:
	return maxf(radius * _tuning.path_step_r, 1.5)


func _on_level_changed(old_level: int, new_level: int) -> void:
	if new_level > old_level:
		flash = maxf(flash, 0.6)
	leveled_up.emit(self, old_level, new_level)
