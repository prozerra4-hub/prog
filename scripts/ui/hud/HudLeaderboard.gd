class_name HudLeaderboard
extends PanelContainer
## Live top-N table. When the player is outside the top N, their row is appended
## under a divider so they always know where they stand.

const ROW_HEIGHT: float = 24.0

var _rows: Array[Dictionary] = []
var _divider: HSeparator
var _player_row: Dictionary


func build(row_count: int) -> void:
	add_theme_stylebox_override(&"panel", UiTheme.panel_box(UiTheme.PANEL, UiTheme.PANEL_BORDER, 12))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(236, 0)
	var v := UiKit.vbox(2)
	add_child(v)
	v.add_child(UiKit.label("LEADERBOARD", &"CaptionLabel"))
	v.add_child(UiKit.spacer(2))
	for i: int in row_count:
		var row: Dictionary = _make_row()
		v.add_child(row["root"])
		_rows.append(row)
	_divider = HSeparator.new()
	_divider.add_theme_constant_override(&"separation", 6)
	v.add_child(_divider)
	_player_row = _make_row()
	v.add_child(_player_row["root"])


## Shows the top rows, plus the player row if they are outside the top N.
func show_entries(entries: Array[LeaderboardEntry]) -> void:
	var player_in_top: bool = false
	for i: int in _rows.size():
		var row: Dictionary = _rows[i]
		if i < entries.size():
			_fill(row, entries[i])
			(row["root"] as Control).visible = true
			if entries[i].is_player:
				player_in_top = true
		else:
			(row["root"] as Control).visible = false
	var you: LeaderboardEntry = null
	for e: LeaderboardEntry in entries:
		if e.is_player:
			you = e
	var show_you: bool = you != null and not player_in_top
	_divider.visible = show_you
	(_player_row["root"] as Control).visible = show_you
	if show_you:
		_fill(_player_row, you)


func _make_row() -> Dictionary:
	var root := UiKit.hbox(8)
	root.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	var marker := ColorRect.new()
	marker.custom_minimum_size = Vector2(3, 16)
	marker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rank := UiKit.label("", &"HudSmall", HORIZONTAL_ALIGNMENT_RIGHT)
	rank.custom_minimum_size = Vector2(22, 0)
	var name_label := UiKit.label("", &"HudSmall")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var level := UiKit.label("", &"HudSmall", HORIZONTAL_ALIGNMENT_RIGHT)
	root.add_child(marker)
	root.add_child(rank)
	root.add_child(name_label)
	root.add_child(level)
	return {"root": root, "marker": marker, "rank": rank, "name": name_label, "level": level}


func _fill(row: Dictionary, e: LeaderboardEntry) -> void:
	(row["rank"] as Label).text = str(e.rank)
	(row["name"] as Label).text = "You" if e.is_player else e.display_name
	(row["level"] as Label).text = UiFormat.grouped(e.level)
	var marker: ColorRect = row["marker"]
	marker.color = e.color if e.alive else Color(e.color, 0.3)
	var text_col: Color = UiTheme.TEXT if e.alive else UiTheme.TEXT_FAINT
	if e.is_player:
		text_col = UiTheme.ACCENT.lightened(0.3) if e.alive else UiTheme.ACCENT.darkened(0.3)
	for key: String in ["rank", "name", "level"]:
		(row[key] as Label).add_theme_color_override(&"font_color", text_col)
	(row["rank"] as Label).add_theme_color_override(&"font_color", UiTheme.GOLD if e.rank == 1 else UiTheme.TEXT_DIM)
