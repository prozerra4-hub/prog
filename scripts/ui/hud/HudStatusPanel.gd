class_name HudStatusPanel
extends PanelContainer
## Top-left: match clock and revives. During the showdown the clock turns into the
## showdown countdown with a red SHOWDOWN tag.

const URGENT_SECONDS: int = 10

var _time: Label
var _phase: Label
var _revives: Label


func build() -> void:
	add_theme_stylebox_override(&"panel", UiTheme.panel_box(UiTheme.PANEL, UiTheme.PANEL_BORDER, 12))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UiKit.hbox(10)
	row.add_child(UiKit.icon(AssetIds.ICON_CLOCK, 26.0))
	var clock := UiKit.vbox(-6)
	_phase = UiKit.label("SHOWDOWN", &"CaptionLabel")
	_phase.add_theme_color_override(&"font_color", UiTheme.DANGER)
	_phase.visible = false
	_time = UiKit.label("1:30", &"HudValue")
	_time.custom_minimum_size = Vector2(66, 0)
	clock.add_child(_phase)
	clock.add_child(_time)
	row.add_child(clock)
	var sep := VSeparator.new()
	var line := StyleBoxLine.new()
	line.vertical = true
	line.color = UiTheme.PANEL_BORDER
	line.grow_begin = -4
	line.grow_end = -4
	sep.add_theme_stylebox_override(&"separator", line)
	row.add_child(sep)
	row.add_child(UiKit.icon(AssetIds.ICON_HEART, 24.0))
	_revives = UiKit.label("x03", &"HudValue")
	row.add_child(_revives)
	add_child(row)


## Updates the clock (red when urgent or in the showdown).
func set_time(seconds_left: int, showdown: bool) -> void:
	_time.text = UiFormat.clock(seconds_left)
	_phase.visible = showdown
	var urgent: bool = seconds_left <= URGENT_SECONDS
	_time.add_theme_color_override(&"font_color", UiTheme.DANGER if (urgent or showdown) else UiTheme.TEXT)
	if urgent and seconds_left > 0:
		HudFx.pulse(_time, 1.12)


## Updates the revive counter (red at zero).
func set_revives(left: int) -> void:
	_revives.text = "x%02d" % left
	_revives.add_theme_color_override(&"font_color", UiTheme.DANGER if left == 0 else UiTheme.TEXT)
