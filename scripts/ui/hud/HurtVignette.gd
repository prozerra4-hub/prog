class_name HurtVignette
extends TextureRect
## Faint red edge tint flashed when the player is struck.

var _tween: Tween


func build() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.1, 0.08, 0.0))
	g.set_color(1, Color(0.85, 0.1, 0.08, 0.3))
	g.add_point(0.72, Color(0.85, 0.1, 0.08, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.05, 0.5)
	t.width = 256
	t.height = 144
	texture = t
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Brief red edge flash.
func flash() -> void:
	if _tween != null:
		_tween.kill()
	modulate.a = 1.0
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 0.0, 0.55)
