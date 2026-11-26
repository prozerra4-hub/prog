class_name UiTheme
extends RefCounted
## The single UI style source: palette, fonts and every StyleBox. Built once and
## shared. Restrained by design: one accent colour, flat panels, 1 px borders,
## 6 px corners, no gradients on controls.

const BG_DEEP: Color = Color("070b14")
const PANEL: Color = Color(0.059, 0.090, 0.149, 0.86)
const PANEL_SOLID: Color = Color("0f1726")
const PANEL_BORDER: Color = Color("22314a")
const RAISED: Color = Color("152138")
const TEXT: Color = Color("e8eef7")
const TEXT_DIM: Color = Color("8a9ab3")
const TEXT_FAINT: Color = Color("56647c")
const ACCENT: Color = Color("3fa2ff")
const ACCENT_DARK: Color = Color("2a7fd1")
const DANGER: Color = Color("ff5a52")
const GOLD: Color = Color("ffc64a")
const SUCCESS: Color = Color("5bd68a")

const RADIUS: int = 6

const FONT_NAMES: PackedStringArray = ["Bahnschrift", "Segoe UI", "Arial"]

static var _theme: Theme
static var _fonts: Dictionary = {}


## The single shared Theme (built on first use).
static func shared() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## weight: 400 regular, 600 semibold, 700 bold.
static func font(weight: int = 400) -> Font:
	if not _fonts.has(weight):
		var f := SystemFont.new()
		f.font_names = FONT_NAMES
		f.font_weight = weight
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_LIGHT
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_fonts[weight] = f
	return _fonts[weight]


## Standard panel StyleBox (flat, 1 px border, 6 px corners).
static func panel_box(bg: Color = PANEL, border: Color = PANEL_BORDER, pad: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(RADIUS)
	sb.set_content_margin_all(pad)
	sb.anti_aliasing = true
	return sb


static func _button_box(bg: Color, border: Color, border_w: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(RADIUS)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 11
	sb.content_margin_bottom = 11
	return sb


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font = font(400)
	t.default_font_size = 18

	# Panels
	t.set_stylebox(&"panel", &"PanelContainer", panel_box())
	t.set_stylebox(&"panel", &"Panel", panel_box())

	# Labels
	t.set_color(&"font_color", &"Label", TEXT)
	t.set_constant(&"line_spacing", &"Label", 2)
	_label_variation(t, &"TitleLabel", 600, 60, TEXT)
	_label_variation(t, &"HeadingLabel", 600, 30, TEXT)
	_label_variation(t, &"SubheadingLabel", 600, 20, TEXT)
	_label_variation(t, &"CaptionLabel", 600, 13, TEXT_DIM)
	_label_variation(t, &"BodyDimLabel", 400, 16, TEXT_DIM)
	_label_variation(t, &"HudValue", 600, 28, TEXT)
	_label_variation(t, &"HudSmall", 600, 16, TEXT)

	# Buttons (default = secondary)
	t.set_stylebox(&"normal", &"Button", _button_box(RAISED, PANEL_BORDER))
	t.set_stylebox(&"hover", &"Button", _button_box(Color("1b2a47"), ACCENT.darkened(0.25)))
	t.set_stylebox(&"pressed", &"Button", _button_box(Color("0e1828"), ACCENT))
	t.set_stylebox(&"hover_pressed", &"Button", _button_box(Color("0e1828"), ACCENT))
	t.set_stylebox(&"disabled", &"Button", _button_box(Color(0.08, 0.11, 0.17, 0.6), Color(0.13, 0.19, 0.29, 0.6)))
	var focus := _button_box(Color(0, 0, 0, 0), ACCENT, 2)
	focus.draw_center = false
	t.set_stylebox(&"focus", &"Button", focus)
	t.set_font(&"font", &"Button", font(600))
	t.set_font_size(&"font_size", &"Button", 18)
	t.set_color(&"font_color", &"Button", TEXT)
	t.set_color(&"font_hover_color", &"Button", Color.WHITE)
	t.set_color(&"font_pressed_color", &"Button", ACCENT)
	t.set_color(&"font_hover_pressed_color", &"Button", ACCENT)
	t.set_color(&"font_focus_color", &"Button", Color.WHITE)
	t.set_color(&"font_disabled_color", &"Button", TEXT_FAINT)
	t.set_constant(&"h_separation", &"Button", 10)

	# Primary button: filled accent
	t.set_type_variation(&"PrimaryButton", &"Button")
	t.set_stylebox(&"normal", &"PrimaryButton", _button_box(ACCENT, ACCENT))
	t.set_stylebox(&"hover", &"PrimaryButton", _button_box(ACCENT.lightened(0.12), ACCENT.lightened(0.25)))
	t.set_stylebox(&"pressed", &"PrimaryButton", _button_box(ACCENT_DARK, ACCENT_DARK))
	t.set_stylebox(&"hover_pressed", &"PrimaryButton", _button_box(ACCENT_DARK, ACCENT_DARK))
	t.set_stylebox(&"disabled", &"PrimaryButton", _button_box(ACCENT.darkened(0.6), ACCENT.darkened(0.6)))
	t.set_color(&"font_color", &"PrimaryButton", Color("06101f"))
	t.set_color(&"font_hover_color", &"PrimaryButton", Color("06101f"))
	t.set_color(&"font_pressed_color", &"PrimaryButton", Color("06101f"))
	t.set_color(&"font_hover_pressed_color", &"PrimaryButton", Color("06101f"))
	t.set_color(&"font_focus_color", &"PrimaryButton", Color("06101f"))

	# Sliders
	var track := StyleBoxFlat.new()
	track.bg_color = PANEL_BORDER
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = ACCENT
	t.set_stylebox(&"slider", &"HSlider", track)
	t.set_stylebox(&"grabber_area", &"HSlider", fill)
	t.set_stylebox(&"grabber_area_highlight", &"HSlider", fill)
	t.set_icon(&"grabber", &"HSlider", _dot(16, TEXT))
	t.set_icon(&"grabber_highlight", &"HSlider", _dot(16, Color.WHITE))

	# CheckButton / CheckBox text
	t.set_font(&"font", &"CheckButton", font(600))
	t.set_color(&"font_color", &"CheckButton", TEXT)
	t.set_color(&"font_hover_color", &"CheckButton", Color.WHITE)
	t.set_color(&"font_pressed_color", &"CheckButton", TEXT)
	t.set_color(&"font_hover_pressed_color", &"CheckButton", Color.WHITE)
	var clear := StyleBoxEmpty.new()
	for s: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus"]:
		t.set_stylebox(s, &"CheckButton", clear)

	# Separators
	var line := StyleBoxLine.new()
	line.color = PANEL_BORDER
	line.thickness = 1
	t.set_stylebox(&"separator", &"HSeparator", line)
	t.set_constant(&"separation", &"HSeparator", 12)
	return t


static func _label_variation(t: Theme, name: StringName, weight: int, size: int, color: Color) -> void:
	t.set_type_variation(name, &"Label")
	t.set_font(&"font", name, font(weight))
	t.set_font_size(&"font_size", name, size)
	t.set_color(&"font_color", name, color)


static func _dot(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: float = (float(size) - 1.0) * 0.5
	for y: int in size:
		for x: int in size:
			var d: float = Vector2(x - c, y - c).length()
			var a: float = clampf(c - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	return ImageTexture.create_from_image(img)
