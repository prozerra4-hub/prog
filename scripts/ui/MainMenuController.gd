class_name MainMenuController
extends Node
## Title screen over a live attract-mode arena. One left column shows one view at
## a time: main buttons, HOW TO PLAY, SKINS, SETTINGS (each its own MenuView class).

signal start_requested
signal quit_requested

const COLUMN_WIDTH: float = MenuView.COLUMN_WIDTH

@onready var _world: GameSession = $GameWorld
@onready var _ui: Control = $UILayer/MenuRoot

var _main_view: VBoxContainer
var _how_to_view: MenuHowToView
var _skins_view: MenuSkinsView
var _settings_view: MenuSettingsView
var _views: Array[Control] = []
var _best_label: Label
var _start_button: Button


func _ready() -> void:
	_world.start(null)  # attract mode
	_ui.theme = UiTheme.shared()
	_build()
	_show_view(_main_view)


func _build() -> void:
	_ui.add_child(_make_shade())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 88)
	margin.add_theme_constant_override(&"margin_top", 56)
	margin.add_theme_constant_override(&"margin_bottom", 40)
	_ui.add_child(margin)
	var layout := UiKit.vbox(0)
	margin.add_child(layout)

	var title_font := FontVariation.new()
	title_font.base_font = UiTheme.font(700)
	title_font.spacing_glyph = 3
	var title := UiKit.label("SERPENT ARENA", &"TitleLabel")
	title.add_theme_font_override(&"font", title_font)
	title.add_theme_font_size_override(&"font_size", 64)
	var accent_bar := ColorRect.new()
	accent_bar.color = UiTheme.ACCENT
	accent_bar.custom_minimum_size = Vector2(56, 4)
	accent_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var tagline := UiKit.label("Eat, outgrow your rivals, cut them down,\nthen topple the Crimson Tyrant in the showdown.", &"BodyDimLabel")
	layout.add_child(title)
	layout.add_child(UiKit.spacer(10))
	layout.add_child(accent_bar)
	layout.add_child(UiKit.spacer(14))
	layout.add_child(tagline)
	layout.add_child(UiKit.spacer(30))

	var column := UiKit.vbox(0)
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(column)

	_best_label = UiKit.label("", &"CaptionLabel")
	_main_view = _build_main_view()
	_how_to_view = MenuHowToView.new()
	_how_to_view.build()
	_skins_view = MenuSkinsView.new()
	_skins_view.build(_world.balance.player_skins)
	_settings_view = MenuSettingsView.new()
	_settings_view.build()
	_views = [_main_view, _how_to_view, _skins_view, _settings_view]
	# The how-to page is tall: hide the tagline and record line while it is open.
	_how_to_view.visibility_changed.connect(func() -> void:
		tagline.visible = not _how_to_view.visible
		_best_label.visible = not _how_to_view.visible)
	for v: Control in _views:
		column.add_child(v)
	for v: MenuView in [_how_to_view, _skins_view, _settings_view]:
		v.back_requested.connect(func() -> void: _show_view(_main_view))

	layout.add_child(_best_label)
	_refresh_best()


func _build_main_view() -> VBoxContainer:
	var v := UiKit.vbox(10)
	_start_button = UiKit.button("GAME START", true, COLUMN_WIDTH)
	var how_to := UiKit.button("HOW TO PLAY", false, COLUMN_WIDTH)
	var skins := UiKit.button("SKINS", false, COLUMN_WIDTH)
	var settings := UiKit.button("SETTINGS", false, COLUMN_WIDTH)
	var quit := UiKit.button("QUIT", false, COLUMN_WIDTH)
	for b: Button in [_start_button, how_to, skins, settings, quit]:
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)
	_start_button.pressed.connect(func() -> void: start_requested.emit())
	how_to.pressed.connect(func() -> void: _show_view(_how_to_view))
	skins.pressed.connect(func() -> void: _show_view(_skins_view))
	settings.pressed.connect(func() -> void: _show_view(_settings_view))
	quit.pressed.connect(func() -> void: quit_requested.emit())
	return v


## Left-side shade so text always reads over the moving arena.
func _make_shade() -> TextureRect:
	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(UiTheme.BG_DEEP, 0.94))
	grad.set_color(1, Color(UiTheme.BG_DEEP, 0.15))
	grad.add_point(0.5, Color(UiTheme.BG_DEEP, 0.84))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	gt.width = 256
	gt.height = 4
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return shade


func _show_view(view: Control) -> void:
	for v: Control in _views:
		v.visible = v == view
	UiKit.reveal(view, 0.0, 0.985)
	var focus: Control = _start_button if view == _main_view else (view as MenuView).focus_target()
	if focus != null:
		focus.grab_focus.call_deferred()


func _refresh_best() -> void:
	var save: SaveService = Services.save
	if save.matches_played == 0:
		_best_label.text = "NO RECORDS YET"
	else:
		_best_label.text = "BEST  %s  ·  %s PTS" % [UiFormat.level(save.best_level).to_upper(), UiFormat.grouped(save.best_score)]
