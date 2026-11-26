class_name SkinPreview
extends Control
## Draws a short curled snake in a given skin using the real in-game shader, so
## the menu preview is exactly what you get in the arena.

const SKIN_SHADER: Shader = preload("res://shaders/snake_skin.gdshader")
const BEADS: int = 7

var _skin: SnakeSkin
var _bead: Texture2D
var _mat: ShaderMaterial
var locked: bool = false:
	set(v):
		locked = v
		queue_redraw()


func setup(skin: SnakeSkin) -> void:
	_skin = skin
	_bead = Services.assets.texture(AssetIds.SNAKE_BEAD)
	_mat = ShaderMaterial.new()
	_mat.shader = SKIN_SHADER
	_mat.set_shader_parameter(&"primary_hue", skin.hue)
	_mat.set_shader_parameter(&"primary_sat", skin.saturation)
	_mat.set_shader_parameter(&"primary_val", skin.value)
	_mat.set_shader_parameter(&"band_hue", skin.band_hue)
	_mat.set_shader_parameter(&"band_sat", skin.band_saturation)
	_mat.set_shader_parameter(&"band_val", skin.band_value)
	material = _mat
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	if _bead == null:
		return
	var r: float = size.y * 0.17
	var half: float = r * float(_bead.get_width()) * 0.5 / AssetIds.BEAD_SPRITE_RADIUS_PX
	var alpha: float = 0.35 if locked else 1.0
	# Gentle S-curve from left (tail) to right (head).
	for i: int in BEADS + 1:
		var t: float = float(i) / float(BEADS)
		var x: float = lerpf(size.x * 0.18, size.x * 0.8, t)
		var y: float = size.y * 0.5 + sin(t * PI * 1.6 + 0.4) * size.y * 0.14
		var rr: float = r * (lerpf(0.6, 1.0, sqrt(t)) if i < BEADS else 1.22)
		var hh: float = half * rr / r
		# Shader channels: r = brightness (dimmed when locked), g = band, a = alpha.
		var brightness: float = 0.55 if locked else 1.0
		draw_texture_rect(_bead, Rect2(x - hh, y - hh, hh * 2.0, hh * 2.0), false, Color(brightness, 0.0, 0.0, alpha))
