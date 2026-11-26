class_name MenuSettingsView
extends MenuView
## Volume, display and comfort settings. Every change is applied and saved at once.

var _back: Button


func build() -> void:
	add_theme_constant_override(&"separation", 14)
	var s: SettingsService = Services.settings
	_add_title("SETTINGS")
	add_child(_slider_row("MASTER VOLUME", s.master_volume, func(x: float) -> void:
		s.master_volume = x
		s.commit()))
	add_child(_slider_row("EFFECTS VOLUME", s.sfx_volume, func(x: float) -> void:
		s.sfx_volume = x
		s.commit()
		Services.audio.play(AudioService.Sfx.EAT)))
	add_child(_toggle_row("FULLSCREEN", s.fullscreen, func(on: bool) -> void:
		s.fullscreen = on
		s.commit()))
	add_child(_toggle_row("SCREEN SHAKE", s.screen_shake, func(on: bool) -> void:
		s.screen_shake = on
		s.commit()))
	add_child(_toggle_row("SHOW FPS", s.show_fps, func(on: bool) -> void:
		s.show_fps = on
		s.commit()))
	_back = _add_back_button()


## BACK gets focus when the view opens.
func focus_target() -> Control:
	return _back


func _slider_row(caption: String, value: float, on_change: Callable) -> Control:
	var v := UiKit.vbox(6)
	var head := UiKit.hbox(0)
	head.add_child(UiKit.label(caption, &"CaptionLabel"))
	head.add_child(UiKit.expand())
	var pct := UiKit.label("%d%%" % int(round(value * 100.0)), &"CaptionLabel")
	head.add_child(pct)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(COLUMN_WIDTH, 18)
	slider.value_changed.connect(func(x: float) -> void:
		pct.text = "%d%%" % int(round(x * 100.0))
		on_change.call(x))
	v.add_child(head)
	v.add_child(slider)
	return v


func _toggle_row(caption: String, value: bool, on_change: Callable) -> Control:
	var t := CheckButton.new()
	t.text = caption
	t.set_pressed_no_signal(value)
	t.custom_minimum_size = Vector2(COLUMN_WIDTH, 30)
	t.add_theme_font_size_override(&"font_size", 15)
	t.toggled.connect(func(on: bool) -> void:
		Services.audio.play(AudioService.Sfx.UI_CLICK)
		on_change.call(on))
	return t
