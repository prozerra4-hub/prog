class_name UiKit
extends RefCounted
## Small factory helpers so screens build consistent controls in few lines.


## Label with an optional theme variation and alignment.
static func label(text: String, variation: StringName = &"", align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	if variation != &"":
		l.theme_type_variation = variation
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Themed button (primary = filled accent) with hover/click sounds.
static func button(text: String, primary: bool = false, min_width: float = 260.0) -> Button:
	var b := Button.new()
	b.text = text
	if primary:
		b.theme_type_variation = &"PrimaryButton"
	b.custom_minimum_size = Vector2(min_width, 0)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			Services.audio.play(AudioService.Sfx.UI_HOVER))
	b.pressed.connect(func() -> void: Services.audio.play(AudioService.Sfx.UI_CLICK))
	return b


## Square icon from the asset catalog.
static func icon(key: StringName, size: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Services.assets.texture(key)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Themed panel container with padding.
static func panel(pad: int = 14, bg: Color = UiTheme.PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", UiTheme.panel_box(bg, UiTheme.PANEL_BORDER, pad))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## VBox with spacing that ignores the mouse.
static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


## HBox with spacing that ignores the mouse.
static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


## A keyboard key / mouse label drawn as a small bordered cap ("ESC", "W").
static func key_cap(text: String) -> PanelContainer:
	var cap := PanelContainer.new()
	var sb := UiTheme.panel_box(UiTheme.RAISED, UiTheme.TEXT_FAINT, 0)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 3
	sb.set_corner_radius_all(4)
	sb.border_width_bottom = 2
	cap.add_theme_stylebox_override(&"panel", sb)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(text, &"HudSmall", HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_size_override(&"font_size", 14)
	cap.add_child(l)
	return cap


## One "keys -> action" row for control guides.
static func control_row(keys: PackedStringArray, action: String, key_width: float = 190.0) -> HBoxContainer:
	var row := hbox(12)
	var caps := hbox(4)
	caps.custom_minimum_size = Vector2(key_width, 0)
	for k: String in keys:
		if k == "/":
			caps.add_child(label("/", &"CaptionLabel"))
		else:
			caps.add_child(key_cap(k))
	row.add_child(caps)
	row.add_child(label(action, &"BodyDimLabel"))
	return row


## The game's controls, shared by the menu, pause screen and match-start hint.
static func controls_list(key_width: float = 190.0) -> VBoxContainer:
	var v := vbox(8)
	v.add_child(control_row(PackedStringArray(["MOUSE"]), "Steer toward the cursor", key_width))
	v.add_child(control_row(PackedStringArray(["W", "A", "S", "D"]), "Steer (keys override the mouse)", key_width))
	v.add_child(control_row(PackedStringArray(["ARROW KEYS"]), "Steer", key_width))
	v.add_child(control_row(PackedStringArray(["ESC", "/", "P"]), "Pause", key_width))
	return v


## Fixed-height gap.
static func spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Horizontal filler that pushes siblings apart.
static func expand() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Fades and gently scales a control in (UI transition). Never touches position,
## so it is safe for children of Containers (which own their layout).
static func reveal(c: Control, delay: float = 0.0, from_scale: float = 0.97) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(from_scale, from_scale)
	var tw := c.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Pivot is set once layout has produced a real size.
	tw.tween_callback(func() -> void: c.pivot_offset = c.size * 0.5).set_delay(delay)
	tw.tween_property(c, "modulate:a", 1.0, 0.26).set_delay(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.3).set_delay(delay)
