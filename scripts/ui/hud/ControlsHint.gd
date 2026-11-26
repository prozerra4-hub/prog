class_name ControlsHint
extends PanelContainer
## Controls card shown at the start of a match, then faded out.

func build() -> void:
	add_theme_stylebox_override(&"panel", UiTheme.panel_box(UiTheme.PANEL, UiTheme.PANEL_BORDER, 14))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UiKit.vbox(8)
	v.add_child(UiKit.label("CONTROLS", &"CaptionLabel"))
	v.add_child(UiKit.controls_list(150.0))
	add_child(v)


## Fades the card in, holds `seconds`, fades it out.
func show_for(seconds: float) -> void:
	modulate.a = 0.0
	visible = true
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	tw.tween_interval(seconds)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func() -> void: visible = false)
