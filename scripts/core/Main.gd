class_name Main
extends Node
## Application root. Swaps between the menu and game screens; owns nothing else.

const MENU_SCENE: PackedScene = preload("res://scenes/main/MainMenu.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/game/GameScreen.tscn")
const FADE_SEC: float = 0.22

var _current: Node
var _fade: ColorRect
var _busy: bool = false


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = UiTheme.BG_DEEP
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_swap_to(MENU_SCENE)


## Fades to the main menu.
func show_menu() -> void:
	_transition(MENU_SCENE)


## Fades into a new match (also used for RETRY / RESTART).
func start_game() -> void:
	_transition(GAME_SCENE)


func _transition(scene: PackedScene) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE_SEC)
	tw.tween_callback(func() -> void: _swap_to(scene))


func _swap_to(scene: PackedScene) -> void:
	get_tree().paused = false
	if _current != null:
		_current.queue_free()
	_current = scene.instantiate()
	add_child(_current)
	move_child(_current, 0)
	if _current is MainMenuController:
		var menu := _current as MainMenuController
		menu.start_requested.connect(start_game)
		menu.quit_requested.connect(func() -> void: get_tree().quit())
	elif _current is GameScreenController:
		var game := _current as GameScreenController
		game.restart_requested.connect(start_game)
		game.main_menu_requested.connect(show_menu)
	_fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, FADE_SEC)
	tw.tween_callback(func() -> void:
		_busy = false
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE)
