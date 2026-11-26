class_name SettingsService
extends RefCounted
## Player settings. Applies them to the engine and persists via SaveService.

signal changed

const KEY_MASTER: String = "master_volume"
const KEY_SFX: String = "sfx_volume"
const KEY_FULLSCREEN: String = "fullscreen"
const KEY_SHOW_FPS: String = "show_fps"
const KEY_SCREEN_SHAKE: String = "screen_shake"

var master_volume: float = 0.8
var sfx_volume: float = 0.8
var fullscreen: bool = false
var show_fps: bool = false
var screen_shake: bool = true

var _save: SaveService


func _init(save: SaveService) -> void:
	_save = save


## Reads settings from the loaded save (with defaults).
func load_from_save() -> void:
	var s: Dictionary = _save.settings
	master_volume = clampf(float(s.get(KEY_MASTER, master_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(s.get(KEY_SFX, sfx_volume)), 0.0, 1.0)
	fullscreen = bool(s.get(KEY_FULLSCREEN, fullscreen))
	show_fps = bool(s.get(KEY_SHOW_FPS, show_fps))
	screen_shake = bool(s.get(KEY_SCREEN_SHAKE, screen_shake))


## Applies window mode (skipped in headless runs).
func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## Saves settings, applies them and emits `changed`.
func commit() -> void:
	_save.settings = {
		KEY_MASTER: master_volume,
		KEY_SFX: sfx_volume,
		KEY_FULLSCREEN: fullscreen,
		KEY_SHOW_FPS: show_fps,
		KEY_SCREEN_SHAKE: screen_shake,
	}
	_save.save_data()
	apply_display()
	changed.emit()
