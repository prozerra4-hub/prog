class_name FloatingTextLayer
extends Control
## Short combat numbers anchored to WORLD positions (converted to the screen each
## frame): "-45%" where you got cut, "CUT -52%" on your victim, "SHIELD" when a
## strike bounced off protection. They rise a little and fade. Pooled.

const POOL: int = 14
const LIFE_SEC: float = 0.95
const RISE_PX: float = 36.0

var _labels: Array[Label] = []
var _world_pos := PackedVector2Array()
var _age := PackedFloat32Array()
var _next: int = 0


func build() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i: int in POOL:
		var l := Label.new()
		l.add_theme_font_override(&"font", UiTheme.font(700))
		l.add_theme_font_size_override(&"font_size", 20)
		l.add_theme_color_override(&"font_outline_color", Color(0.02, 0.04, 0.08, 0.9))
		l.add_theme_constant_override(&"outline_size", 6)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.visible = false
		add_child(l)
		_labels.append(l)
	_world_pos.resize(POOL)
	_age.resize(POOL)
	_age.fill(LIFE_SEC)


## Shows `text` rising from a WORLD position (follows the camera).
func spawn(world_pos: Vector2, text: String, color: Color, big: bool = false) -> void:
	var i: int = _next
	_next = (_next + 1) % POOL
	var l: Label = _labels[i]
	l.text = text
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_font_size_override(&"font_size", 26 if big else 20)
	l.visible = true
	l.reset_size()
	_world_pos[i] = world_pos
	_age[i] = 0.0


func _process(delta: float) -> void:
	var xf: Transform2D = get_viewport().get_canvas_transform()
	for i: int in POOL:
		if _age[i] >= LIFE_SEC:
			continue
		_age[i] += delta
		var l: Label = _labels[i]
		if _age[i] >= LIFE_SEC:
			l.visible = false
			continue
		var t: float = _age[i] / LIFE_SEC
		var screen: Vector2 = xf * _world_pos[i]
		l.position = (screen - Vector2(l.size.x * 0.5, l.size.y + RISE_PX * (1.0 - pow(1.0 - t, 2.0)))).round()
		l.modulate.a = 1.0 - smoothstep(0.6, 1.0, t)
		var pop: float = 1.0 + 0.25 * (1.0 - smoothstep(0.0, 0.15, t))
		l.pivot_offset = l.size * 0.5
		l.scale = Vector2(pop, pop)
