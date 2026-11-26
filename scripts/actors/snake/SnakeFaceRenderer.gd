class_name SnakeFaceRenderer
extends Node2D
## Eyes, drawn on top of the head bead. Eye placement follows the heading; pupils
## look toward the brain's look target; the catch-light stays at the top-left to
## match the bead artwork's key light. Bosses get angled brows and slit pupils.
## While the snake is protected (respawn / just struck / bounce) a shield bubble
## surrounds the head, so "why didn't that cut?" is always answerable at a glance.

## Eye layout in head radii.
const EYE_FORWARD: float = 0.30
const EYE_SIDE: float = 0.40
const EYE_RADIUS: float = 0.30
const OUTLINE: float = 0.075
const PUPIL_RADIUS: float = 0.56  # of eye radius
const PUPIL_TRAVEL: float = 0.34  # of eye radius
const LIGHT_DIR: Vector2 = Vector2(-0.6, -0.8)

const SCLERA: Color = Color(0.96, 0.97, 0.99)
const PUPIL: Color = Color(0.05, 0.06, 0.10)
const BOSS_IRIS: Color = Color(1.0, 0.76, 0.22)
const SHIELD: Color = Color(0.62, 0.86, 1.0)

var _actor: SnakeActor
var _outline_color: Color = Color(0.05, 0.12, 0.3)
var _blink_timer: float = 3.0
var _blink: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(actor: SnakeActor) -> void:
	_actor = actor
	_rng.seed = hash(actor.slot * 7919 + 17)
	_blink_timer = _rng.randf_range(1.5, 4.5)


## Matches the eye outline to the skin hue.
func apply_skin(skin: SnakeSkin) -> void:
	# Same hue family as the bead outline in the artwork (dark, saturated).
	_outline_color = Color.from_hsv(skin.hue, 0.9, 0.3 * clampf(skin.value, 0.6, 1.2))


func _process(delta: float) -> void:
	if _actor == null or not _actor.is_alive:
		return
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink = 1.0
		_blink_timer = _rng.randf_range(2.2, 5.5)
	_blink = maxf(_blink - delta * 7.0, 0.0)


func _draw() -> void:
	if _actor == null:
		return
	var renderer := get_parent() as SnakeBodyRenderer
	var alpha: float = renderer.body_alpha()
	var R: float = _actor.head_radius() * renderer.death_scale(-1, _actor.body.count)
	if alpha <= 0.01 or R < 2.0:
		return
	var head: Vector2 = _actor.head_position()
	var fwd: Vector2 = _actor.heading()
	var side: Vector2 = fwd.orthogonal()
	var look: Vector2 = (_actor.brain.look_target(_actor) - head)
	look = look.normalized() if look.length_squared() > 1.0 else fwd
	# Pupils can't point backwards through the skull.
	if look.dot(fwd) < 0.1:
		look = (look + fwd * (0.1 - look.dot(fwd)) * 1.5).normalized()
	var openness: float = 1.0 - _blink_curve()
	for s: float in [-1.0, 1.0]:
		var eye: Vector2 = head + fwd * (EYE_FORWARD * R) + side * (EYE_SIDE * R * s)
		_draw_eye(eye, R * EYE_RADIUS, fwd, look, openness, alpha, s)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if _actor.is_alive and _actor.is_invulnerable():
		_draw_shield(head, R)


## Translucent bubble + rim; fades out over the last half second of protection.
func _draw_shield(head: Vector2, R: float) -> void:
	var fade: float = clampf(_actor.invulnerable_left() / 0.5, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	var fill: Color = SHIELD
	fill.a = 0.10 * fade
	var rim: Color = SHIELD
	rim.a = (0.55 + 0.3 * pulse) * fade
	draw_circle(head, R * 1.5, fill, true, -1.0, true)
	draw_arc(head, R * 1.5, 0.0, TAU, 40, rim, maxf(R * 0.09, 1.5), true)


func _draw_eye(center: Vector2, er: float, fwd: Vector2, look: Vector2,
		openness: float, alpha: float, side_sign: float) -> void:
	var boss: bool = _actor.is_boss
	# Local frame: x along heading, y squashes for blinking.
	draw_set_transform(center, fwd.angle(), Vector2(1.0, maxf(openness, 0.08)))
	var outline: Color = _outline_color
	outline.a = alpha
	var sclera: Color = SCLERA
	sclera.a = alpha
	draw_circle(Vector2.ZERO, er + er * OUTLINE / EYE_RADIUS, outline, true, -1.0, true)
	draw_circle(Vector2.ZERO, er, sclera, true, -1.0, true)
	if openness > 0.35:
		var local_look: Vector2 = look.rotated(-fwd.angle())
		var pupil_pos: Vector2 = local_look * er * PUPIL_TRAVEL
		var pupil_col: Color = PUPIL
		pupil_col.a = alpha
		if boss:
			var iris: Color = BOSS_IRIS
			iris.a = alpha
			draw_circle(pupil_pos, er * 0.72, iris, true, -1.0, true)
			# Vertical slit across the heading.
			draw_set_transform(center + (pupil_pos.rotated(fwd.angle())), fwd.angle(), Vector2(0.38, 1.0) * Vector2(1.0, maxf(openness, 0.08)))
			draw_circle(Vector2.ZERO, er * 0.6, pupil_col, true, -1.0, true)
			draw_set_transform(center, fwd.angle(), Vector2(1.0, maxf(openness, 0.08)))
		else:
			draw_circle(pupil_pos, er * PUPIL_RADIUS, pupil_col, true, -1.0, true)
		# Catch-light: world-fixed key light, converted to the eye's local frame.
		var light_local: Vector2 = LIGHT_DIR.rotated(-fwd.angle())
		var glint := Color(1, 1, 1, 0.9 * alpha)
		draw_circle(pupil_pos + light_local * er * 0.28, er * 0.17, glint, true, -1.0, true)
	if boss:
		# Heavy lid covering the inner-rear part of each eye: seen from above the two
		# lids form a V pointing forward, which reads as a scowl.
		# Local frame: +x = heading, +y * inward = toward the head's centre line.
		var inward: float = side_sign
		var brow_col: Color = _outline_color.darkened(0.25)
		brow_col.a = alpha
		draw_set_transform(center, fwd.angle(), Vector2.ONE)
		var a := Vector2(er * 0.3, inward * er * 1.15)
		var b := Vector2(-er * 1.15, -inward * er * 0.35)
		var c := Vector2(-er * 1.15, inward * er * 1.15)
		draw_colored_polygon(PackedVector2Array([a, b, c]), brow_col)
		draw_line(a, b, brow_col, er * 0.2, true)


func _blink_curve() -> float:
	# 0 -> 1 -> 0 over the blink.
	return sin(_blink * PI) if _blink > 0.0 else 0.0
