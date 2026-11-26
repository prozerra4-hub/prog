class_name GameScreenController
extends Node
## The playing screen: GameWorld + HUD + pause + results. Starts the match with the
## selected skin, routes pause input, persists the result, and asks Main to
## navigate. Gameplay itself lives entirely in GameSession.

signal restart_requested
signal main_menu_requested

@onready var _session: GameSession = $GameWorld
@onready var _hud: GameHUDController = $HUDLayer/GameHUD
@onready var _pause: PauseMenuController = $PauseLayer/PauseMenu
@onready var _result: ResultScreenController = $ResultLayer/ResultScreen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_session.process_mode = Node.PROCESS_MODE_PAUSABLE
	_session.start(_selected_skin())
	_hud.bind(_session)
	_session.game_over.connect(_on_game_over)
	_pause.resume_requested.connect(_session.resume)
	_pause.restart_requested.connect(func() -> void: restart_requested.emit())
	_pause.menu_requested.connect(func() -> void: main_menu_requested.emit())
	_session.game_paused.connect(_pause.open)
	_session.game_resumed.connect(_pause.close)
	_result.retry_requested.connect(func() -> void: restart_requested.emit())
	_result.menu_requested.connect(func() -> void: main_menu_requested.emit())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if _session.is_paused():
		_session.resume()
	elif _session.is_running():
		_session.pause()
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# Losing window focus pauses the match (never punish alt-tab).
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _session != null and _session.is_running():
		_session.pause()


## The match this screen runs.
func session() -> GameSession:
	return _session


func _on_game_over(result: MatchResult) -> void:
	var save: SaveService = Services.save
	result.new_record = save.record_match(result)
	for skin: SnakeSkin in _session.balance.player_skins:
		if skin.unlock_best_level <= save.best_level:
			save.unlock_skin(skin.id)
	save.save_data()
	_hud.visible = false
	_result.show_result(result)


func _selected_skin() -> SnakeSkin:
	var skins: Array[SnakeSkin] = _session.balance.player_skins
	var wanted: StringName = Services.save.selected_skin
	for skin: SnakeSkin in skins:
		if skin.id == wanted and Services.save.is_skin_unlocked(skin):
			return skin
	return skins[0]
