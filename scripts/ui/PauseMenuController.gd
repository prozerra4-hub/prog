class_name PauseMenuController
extends Control
## Pause overlay. Runs while the tree is paused.

signal resume_requested
signal restart_requested
signal menu_requested

var _panel: PanelContainer
var _resume: Button


func _ready() -> void:
	theme = UiTheme.shared()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = UiKit.panel(28, UiTheme.PANEL_SOLID)
	center.add_child(_panel)
	var v := UiKit.vbox(12)
	_panel.add_child(v)
	v.add_child(UiKit.label("PAUSED", &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.spacer(6))
	_resume = UiKit.button("RESUME", true)
	var restart := UiKit.button("RESTART")
	var menu := UiKit.button("MAIN MENU")
	v.add_child(_resume)
	v.add_child(restart)
	v.add_child(menu)
	v.add_child(UiKit.spacer(6))
	v.add_child(HSeparator.new())
	v.add_child(UiKit.label("CONTROLS", &"CaptionLabel"))
	v.add_child(UiKit.controls_list(130.0))
	_resume.pressed.connect(func() -> void: resume_requested.emit())
	restart.pressed.connect(func() -> void: restart_requested.emit())
	menu.pressed.connect(func() -> void: menu_requested.emit())
	visible = false


## Shows the pause overlay and focuses RESUME.
func open() -> void:
	visible = true
	UiKit.reveal(_panel, 0.0)
	_resume.grab_focus.call_deferred()


## Hides the pause overlay.
func close() -> void:
	visible = false
