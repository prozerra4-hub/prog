class_name SnakeCrestRenderer
extends Node2D
## Boss-only head dressing, drawn *behind* the body (show_behind_parent):
## a dim red aura under the head and two swept horns. The horns use the same
## dark outline + top-left lit two-tone shading as the bead artwork.

const HORN_BASE_ANGLE: float = 0.95  # rad from heading
const HORN_LENGTH: float = 1.05      # head radii
const HORN_WIDTH: float = 0.42       # head radii at the base
const HORN_SWEEP: float = 0.85       # how far the tip bends backwards
const LIGHT_DIR: Vector2 = Vector2(-0.6, -0.8)

const HORN_LIGHT: Color = Color(1.0, 0.86, 0.45)
const HORN_DARK: Color = Color(0.83, 0.55, 0.12)
const HORN_OUTLINE: Color = Color(0.32, 0.12, 0.03)

## Soft radial glow, generated once. The supplied boss_aura_red.png has a hard
## rim and highlight arc that read as a decorative ring, so it is not used.
static var _aura: GradientTexture2D

var _actor: SnakeActor
## 0..1 extra aura intensity (boss charge wind-up drives this).
var aura_boost: float = 0.0


func setup(actor: SnakeActor) -> void:
	_actor = actor
	if _aura == null:
		_aura = _make_aura()
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


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

	# Aura: subtle, slow pulse; brighter during a charge wind-up.
	var t: float = Time.get_ticks_msec() * 0.001
	var pulse: float = 0.5 + 0.5 * sin(t * 2.4)
	var aura_size: float = R * (3.0 + 0.2 * pulse + aura_boost * 0.9)
	var aura_col := Color(1, 1, 1, (0.5 + 0.12 * pulse + aura_boost * 0.5) * alpha)
	draw_texture_rect(_aura, Rect2(head - Vector2(aura_size, aura_size), Vector2(aura_size, aura_size) * 2.0), false, aura_col)

	for s: float in [-1.0, 1.0]:
		_draw_horn(head, fwd, R, s, alpha)


static func _make_aura() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.12, 0.08, 0.55))
	g.set_color(1, Color(0.85, 0.12, 0.08, 0.0))
	g.add_point(0.45, Color(0.75, 0.08, 0.06, 0.28))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


func _draw_horn(head: Vector2, fwd: Vector2, R: float, s: float, alpha: float) -> void:
	var base_dir: Vector2 = fwd.rotated(HORN_BASE_ANGLE * s)
	var base_center: Vector2 = head + base_dir * R * 0.78
	var across: Vector2 = base_dir.orthogonal() * (R * HORN_WIDTH * 0.5)
	# Tip sweeps outward and back.
	var tip_dir: Vector2 = base_dir.rotated(HORN_SWEEP * s).normalized()
	var tip: Vector2 = base_center + tip_dir * R * HORN_LENGTH
	var mid: Vector2 = base_center.lerp(tip, 0.55) + base_dir * R * 0.12
	var b0: Vector2 = base_center + across
	var b1: Vector2 = base_center - across
	var shape := PackedVector2Array([b0, mid + across * 0.45, tip, mid - across * 0.45, b1])

	var outline: Color = HORN_OUTLINE
	outline.a = alpha
	var lit: Color = HORN_LIGHT
	lit.a = alpha
	var shade: Color = HORN_DARK
	shade.a = alpha
	# Per-vertex shading by facing toward the key light.
	var colors := PackedColorArray()
	for p: Vector2 in shape:
		var n: Vector2 = (p - base_center.lerp(tip, 0.4)).normalized()
		# LIGHT_DIR points toward the light, so normals facing it are lit.
		var k: float = clampf(0.5 + 0.5 * n.dot(LIGHT_DIR), 0.0, 1.0)
		colors.append(shade.lerp(lit, k))
	draw_polygon(shape, colors)
	var closed := shape.duplicate()
	closed.append(shape[0])
	draw_polyline(closed, outline, maxf(R * 0.07, 1.5), true)
