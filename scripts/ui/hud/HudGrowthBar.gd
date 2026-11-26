class_name HudGrowthBar
extends VBoxContainer
## Bottom-centre: player level and progress to the next level.

var _level: Label
var _bar: ProgressBar


func build() -> void:
	add_theme_constant_override(&"separation", 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level = UiKit.label("Lv 1", &"HudValue", HORIZONTAL_ALIGNMENT_CENTER)
	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(300, 6)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.13, 0.19, 0.29, 0.8)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiTheme.ACCENT
	fill.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override(&"background", bg)
	_bar.add_theme_stylebox_override(&"fill", fill)
	add_child(_level)
	add_child(_bar)


func refresh(stats: SnakeStats) -> void:
	_level.text = UiFormat.level(stats.level)
	_bar.value = stats.progress()


## Scale pulse on level-up.
func punch() -> void:
	HudFx.pulse(_level, 1.18)
