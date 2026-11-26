class_name HudToast
extends VBoxContainer
## Centre-top announcement (title + optional subtitle), fades in and out.

var _title: Label
var _subtitle: Label
var _tween: Tween


func build() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", 0)
	_title = _outlined(UiKit.label("", &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER), 8)
	_subtitle = _outlined(UiKit.label("", &"SubheadingLabel", HORIZONTAL_ALIGNMENT_CENTER), 6)
	add_child(_title)
	add_child(_subtitle)
	modulate.a = 0.0


## Centre announcement: fade in, hold `hold` seconds, fade out.
func show_message(title: String, color: Color, hold: float, subtitle: String = "") -> void:
	_title.text = title
	_title.add_theme_color_override(&"font_color", color)
	_subtitle.text = subtitle
	_subtitle.visible = subtitle != ""
	if _tween != null:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.tween_interval(hold)
	_tween.tween_property(self, "modulate:a", 0.0, 0.35)


static func _outlined(l: Label, size_px: int) -> Label:
	l.add_theme_color_override(&"font_outline_color", Color(0.02, 0.04, 0.08, 0.9))
	l.add_theme_constant_override(&"outline_size", size_px)
	return l
