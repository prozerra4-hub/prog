class_name MenuSkinsView
extends MenuView
## Skin picker. Previews use the real in-game shader; locked skins show the
## best level needed to unlock them.

var _back: Button


func build(skins: Array[SnakeSkin]) -> void:
	add_theme_constant_override(&"separation", 12)
	_add_title("SKINS")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 10)
	grid.add_theme_constant_override(&"v_separation", 10)
	add_child(grid)
	var group := ButtonGroup.new()
	for skin: SnakeSkin in skins:
		grid.add_child(_skin_card(skin, group))
	_back = _add_back_button()


## BACK gets focus when the view opens.
func focus_target() -> Control:
	return _back


func _skin_card(skin: SnakeSkin, group: ButtonGroup) -> Button:
	var unlocked: bool = Services.save.is_skin_unlocked(skin)
	var card := Button.new()
	card.toggle_mode = true
	card.button_group = group
	card.custom_minimum_size = Vector2(106, 104)
	card.disabled = not unlocked
	card.focus_mode = Control.FOCUS_ALL
	# Initial state set silently: opening the menu must not write the save file.
	var selected: StringName = Services.save.selected_skin
	card.set_pressed_no_signal(unlocked and (selected == skin.id or (selected == &"" and skin.unlock_best_level == 0)))
	var v := UiKit.vbox(0)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6
	v.offset_right = -6
	v.offset_top = 6
	v.offset_bottom = -8
	card.add_child(v)
	var preview := SkinPreview.new()
	preview.custom_minimum_size = Vector2(90, 58)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.setup(skin)
	preview.locked = not unlocked
	v.add_child(preview)
	var caption: String = skin.display_name.to_upper() if unlocked else "LV %s" % UiFormat.grouped(skin.unlock_best_level)
	var l := UiKit.label(caption, &"CaptionLabel", HORIZONTAL_ALIGNMENT_CENTER)
	if unlocked:
		l.add_theme_color_override(&"font_color", UiTheme.TEXT)
	v.add_child(l)
	card.tooltip_text = skin.display_name if unlocked else "Reach Lv %s to unlock" % UiFormat.grouped(skin.unlock_best_level)
	card.toggled.connect(func(on: bool) -> void:
		if on:
			Services.save.selected_skin = skin.id
			Services.save.save_data())
	return card
