class_name MenuView
extends VBoxContainer
## Base for main-menu views that share the left column. Emits back_requested
## from its BACK button; the controller decides what to show next.

signal back_requested

const COLUMN_WIDTH: float = 340.0


func _add_title(text: String) -> void:
	add_child(UiKit.label(text, &"SubheadingLabel"))


func _add_back_button() -> Button:
	var back := UiKit.button("BACK", false, COLUMN_WIDTH)
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(UiKit.spacer(4))
	add_child(back)
	return back


## Control to focus when the view opens.
func focus_target() -> Control:
	return null
