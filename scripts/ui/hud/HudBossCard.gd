class_name HudBossCard
extends PanelContainer
## Top-right: the boss's live level and what the player should do about it.

var _level: Label
var _state: Label
var _defeated: bool = false


func build(boss_name: String) -> void:
	add_theme_stylebox_override(&"panel", UiTheme.panel_box(UiTheme.PANEL, UiTheme.PANEL_BORDER, 12))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(236, 0)
	var row := UiKit.hbox(10)
	row.add_child(UiKit.icon(AssetIds.ICON_SKULL, 34.0))
	var text := UiKit.vbox(0)
	var title := UiKit.label(boss_name.to_upper(), &"CaptionLabel")
	title.add_theme_color_override(&"font_color", UiTheme.DANGER)
	_level = UiKit.label("", &"SubheadingLabel")
	_state = UiKit.label("", &"CaptionLabel")
	text.add_child(title)
	text.add_child(_level)
	text.add_child(_state)
	row.add_child(text)
	add_child(row)


func refresh(boss: SnakeActor, player: SnakeActor, even_ratio: float, showdown: bool) -> void:
	if _defeated or boss == null or not boss.is_alive or player == null:
		return
	_level.text = UiFormat.level(boss.stats.level)
	var can_strike: bool = float(player.stats.level) > float(boss.stats.level) * (1.0 + even_ratio)
	var hint: String
	if can_strike:
		hint = "STRIKE IT ANYWHERE!"
	elif showdown:
		hint = "DODGE THE JAWS, CUT ITS GOLD TAIL"
	else:
		hint = "AVOID ITS JAWS"
	_state.text = hint
	_state.add_theme_color_override(&"font_color", UiTheme.GOLD if can_strike else (UiTheme.DANGER if showdown else UiTheme.TEXT_DIM))


## Freezes the card in its DEFEATED state.
func mark_defeated() -> void:
	_defeated = true
	_state.text = "DEFEATED"
	_state.add_theme_color_override(&"font_color", UiTheme.GOLD)
	modulate = Color(1, 1, 1, 0.6)
