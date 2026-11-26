class_name ResultScreenController
extends Control
## End-of-match summary.

signal retry_requested
signal menu_requested

var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _record: Label
var _grid: GridContainer
var _retry: Button


func _ready() -> void:
	theme = UiTheme.shared()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = UiKit.panel(32, UiTheme.PANEL_SOLID)
	_panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(_panel)
	var v := UiKit.vbox(6)
	_panel.add_child(v)
	_title = UiKit.label("", &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_title.add_theme_font_size_override(&"font_size", 48)
	_subtitle = UiKit.label("", &"BodyDimLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_record = UiKit.label("NEW PERSONAL BEST", &"CaptionLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_record.add_theme_color_override(&"font_color", UiTheme.GOLD)
	v.add_child(_title)
	v.add_child(_subtitle)
	v.add_child(_record)
	v.add_child(UiKit.spacer(10))
	var sep := HSeparator.new()
	v.add_child(sep)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override(&"h_separation", 24)
	_grid.add_theme_constant_override(&"v_separation", 10)
	v.add_child(_grid)
	v.add_child(HSeparator.new())
	v.add_child(UiKit.spacer(6))
	var buttons := UiKit.hbox(12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_retry = UiKit.button("RETRY", true, 190.0)
	var menu := UiKit.button("MAIN MENU", false, 190.0)
	buttons.add_child(_retry)
	buttons.add_child(menu)
	v.add_child(buttons)
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	menu.pressed.connect(func() -> void: menu_requested.emit())
	visible = false


## Fills and reveals the result panel.
func show_result(r: MatchResult) -> void:
	_title.text = r.outcome_title()
	var tint: Color = UiTheme.TEXT
	match r.outcome:
		MatchResult.Outcome.VICTORY:
			tint = UiTheme.GOLD
		MatchResult.Outcome.ELIMINATED:
			tint = UiTheme.DANGER
	_title.add_theme_color_override(&"font_color", tint)
	_subtitle.text = "Finished #%d of %d" % [r.final_rank, r.participants]
	_record.visible = r.new_record
	for c: Node in _grid.get_children():
		c.queue_free()
	_row("FINAL LEVEL", UiFormat.grouped(r.final_level))
	_row("RANK", "#%d" % r.final_rank)
	_row("KILLS", str(r.kills))
	_row("SURVIVAL", UiFormat.clock(int(r.survival_sec)))
	_row("BOSS", "DEFEATED" if r.boss_defeated else "—", UiTheme.GOLD if r.boss_defeated else UiTheme.TEXT_DIM)
	_row("SCORE", UiFormat.grouped(r.score), UiTheme.ACCENT.lightened(0.3))
	visible = true
	UiKit.reveal(_panel, 0.05)
	_retry.grab_focus.call_deferred()


func _row(caption: String, value: String, color: Color = UiTheme.TEXT) -> void:
	var c := UiKit.label(caption, &"CaptionLabel")
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UiKit.label(value, &"SubheadingLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_theme_color_override(&"font_color", color)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(c)
	_grid.add_child(v)
