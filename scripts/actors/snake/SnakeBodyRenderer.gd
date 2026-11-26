class_name SnakeBodyRenderer
extends Node2D
## Draws tail -> body -> head as recoloured copies of one bead texture.
## Beads are never rotated: the artwork's key light (top-left) and baked contact
## shadow stay world-fixed, so lighting is consistent along every curve.
## Direction is conveyed by the face (SnakeFaceRenderer), not by rotating art.

const SKIN_SHADER: Shader = preload("res://shaders/snake_skin.gdshader")
const INVULN_BLINK_HZ: float = 7.0

var _actor: SnakeActor
var _bead: Texture2D
var _bead_half_scale: float = 1.0
var _shader_material: ShaderMaterial

@onready var _face: SnakeFaceRenderer = $Face
@onready var _crest: SnakeCrestRenderer = $Crest


func setup(actor: SnakeActor, with_crest: bool) -> void:
	_actor = actor
	_bead = Services.assets.texture(AssetIds.SNAKE_BEAD)
	# Texture px per world px at radius 1: sprite width covers 256 px for 66.5 px radius.
	_bead_half_scale = float(_bead.get_width()) * 0.5 / AssetIds.BEAD_SPRITE_RADIUS_PX
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = SKIN_SHADER
	material = _shader_material
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	apply_skin(actor.skin)
	_face.setup(actor)
	_crest.setup(actor)
	_crest.visible = with_crest


## Pushes the skin colours into the recolour shader (and eye outline colour).
func apply_skin(skin: SnakeSkin) -> void:
	_shader_material.set_shader_parameter(&"primary_hue", skin.hue)
	_shader_material.set_shader_parameter(&"primary_sat", skin.saturation)
	_shader_material.set_shader_parameter(&"primary_val", skin.value)
	_shader_material.set_shader_parameter(&"band_hue", skin.band_hue)
	_shader_material.set_shader_parameter(&"band_sat", skin.band_saturation)
	_shader_material.set_shader_parameter(&"band_val", skin.band_value)
	_face.apply_skin(skin)


## Boss crest aura intensity 0..1 (charge wind-up telegraph).
func set_aura_boost(value: float) -> void:
	_crest.aura_boost = value


func refresh() -> void:
	queue_redraw()
	_face.queue_redraw()
	if _crest.visible:
		_crest.queue_redraw()


## Shared by face/crest so all parts fade and shrink together.
func body_alpha() -> float:
	if not _actor.is_alive:
		return 1.0 - smoothstep(0.55, 1.0, _actor.death_progress())
	if _actor.is_invulnerable():
		var phase: float = sin(Time.get_ticks_msec() * 0.001 * TAU * INVULN_BLINK_HZ)
		return 0.8 + 0.2 * (0.5 + 0.5 * phase)  # gentle: the shield bubble carries the message
	return 1.0


## Death dissolve: beads collapse head-first in a wave toward the tail.
func death_scale(bead_index: int, count: int) -> float:
	if _actor.is_alive:
		return 1.0
	var p: float = _actor.death_progress()
	var start: float = float(bead_index + 1) / float(count + 1) * 0.6
	return 1.0 - smoothstep(start, start + 0.4, p)


func _draw() -> void:
	if _actor == null or _bead == null:
		return
	var body: SnakeBody = _actor.body
	var alpha: float = body_alpha()
	if alpha <= 0.01:
		return
	var brightness: float = 1.0 + _actor.flash * 0.35
	var hurt: float = _actor.hurt
	var band_every: int = _actor.skin.band_every
	var count: int = body.count
	for i: int in range(count - 1, -1, -1):
		var r: float = body.radii[i] * death_scale(i, count)
		if r < 0.5:
			continue
		# Banded skins: on bosses only the weak-spot bands (rear part) are drawn gold.
		var banded: bool = band_every > 0 and (i % band_every) == band_every - 1
		if banded and _actor.weak_spot_from_share <= 1.0:
			banded = _actor.is_weak_spot(i)
		var band: float = 1.0 if banded else 0.0
		_draw_bead(body.positions[i], r, Color(brightness, band, hurt, alpha))
	var head_r: float = _actor.head_radius() * death_scale(-1, count)
	if head_r >= 0.5:
		_draw_bead(_actor.head_position(), head_r, Color(brightness, 0.0, hurt, alpha))


func _draw_bead(center: Vector2, r: float, channels: Color) -> void:
	var half: float = r * _bead_half_scale
	draw_texture_rect(_bead, Rect2(center.x - half, center.y - half, half * 2.0, half * 2.0), false, channels)
