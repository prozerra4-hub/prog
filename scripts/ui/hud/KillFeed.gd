class_name KillFeed
extends VBoxContainer
## Short-lived event lines (swallows, cuts involving the player).

const MAX_LINES: int = 4
const TTL_SEC: float = 4.0


func build() -> void:
	add_theme_constant_override(&"separation", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Adds a line (oldest drops past MAX_LINES; each fades after TTL).
func push(text: String, color: Color) -> void:
	var l := UiKit.label(text, &"HudSmall")
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_outline_color", Color(0.02, 0.04, 0.08, 0.8))
	l.add_theme_constant_override(&"outline_size", 4)
	add_child(l)
	while get_child_count() > MAX_LINES:
		get_child(0).free()
	var tw := l.create_tween()
	tw.tween_interval(TTL_SEC)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)
