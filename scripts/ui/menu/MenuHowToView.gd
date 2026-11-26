class_name MenuHowToView
extends MenuView
## Controls and the core rules, in as few words as possible.

const RULES: PackedStringArray = [
	"Eat orbs to grow. Bigger is stronger, but slower to turn.",
	"Your head never hurts you: bodies are walls you slide along.",
	"A bigger mouth cuts you where it strikes. Red-ringed heads can cut you.",
	"Strike smaller snakes near the neck to swallow them whole.",
	"Stay inside the safe zone: it shrinks, and outside it you burn away.",
	"At 0:00: SHOWDOWN. Cut the Tyrant's gold tail to shrink it, then finish it.",
]

var _back: Button


func build() -> void:
	add_theme_constant_override(&"separation", 8)
	_add_title("HOW TO PLAY")
	add_child(UiKit.label("CONTROLS", &"CaptionLabel"))
	add_child(UiKit.controls_list(170.0))
	add_child(UiKit.spacer(2))
	add_child(UiKit.label("RULES", &"CaptionLabel"))
	for i: int in RULES.size():
		var row := UiKit.hbox(10)
		var n := UiKit.label(str(i + 1), &"CaptionLabel")
		n.add_theme_color_override(&"font_color", UiTheme.ACCENT)
		n.custom_minimum_size = Vector2(14, 0)
		n.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		var t := UiKit.label(RULES[i], &"BodyDimLabel")
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(600, 0)
		row.add_child(n)
		row.add_child(t)
		add_child(row)
	_back = _add_back_button()


## BACK gets focus when the view opens.
func focus_target() -> Control:
	return _back
