class_name HudZonePanel
extends PanelContainer
## Safe-zone status under the clock: countdown to the next shrink, "ZONE CLOSING"
## while it shrinks, and a pulsing red warning while the player is outside.

var _label: Label
var _warning_shown: bool = false


func build() -> void:
	add_theme_stylebox_override(&"panel", UiTheme.panel_box(UiTheme.PANEL, UiTheme.PANEL_BORDER, 10))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UiKit.hbox(8)
	var dot := ColorRect.new()
	dot.color = ZoneRenderer.EDGE
	dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UiKit.label("", &"HudSmall")
	row.add_child(dot)
	row.add_child(_label)
	add_child(row)


func refresh(zone: ZoneSystem, player: SnakeActor, erosion_per_sec: float) -> void:
	var outside: bool = player != null and player.is_alive and not zone.contains(player.head_position())
	if outside:
		_label.text = "OUTSIDE THE ZONE  -%d%%/s" % int(round(erosion_per_sec * 100.0))
		_label.add_theme_color_override(&"font_color", UiTheme.DANGER)
		modulate.a = 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.012)
		return
	modulate.a = 1.0
	match zone.state:
		ZoneSystem.State.WAITING:
			_label.text = "ZONE CLOSES IN %s" % UiFormat.clock(int(ceil(zone.seconds_to_shrink())))
			_label.add_theme_color_override(&"font_color", UiTheme.TEXT if zone.seconds_to_shrink() > 5.0 else UiTheme.GOLD)
		ZoneSystem.State.SHRINKING:
			_label.text = "ZONE CLOSING"
			_label.add_theme_color_override(&"font_color", UiTheme.GOLD)
		_:
			_label.text = "FINAL ZONE"
			_label.add_theme_color_override(&"font_color", UiTheme.TEXT_DIM)


## True the first frame the player is outside (for a one-shot toast).
func just_left_zone(zone: ZoneSystem, player: SnakeActor) -> bool:
	var outside: bool = player != null and player.is_alive and not zone.contains(player.head_position())
	var fresh: bool = outside and not _warning_shown
	_warning_shown = outside
	return fresh
