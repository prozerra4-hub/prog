extends Node
## The single autoload. Owns cross-scene services only (assets, save, settings,
## audio). Gameplay state is never stored here; matches own their own systems.

var assets: AssetCatalog
var save: SaveService
var settings: SettingsService
var audio: AudioService


func _enter_tree() -> void:
	assets = AssetCatalog.new()
	save = SaveService.new()
	save.load_data()
	settings = SettingsService.new(save)
	settings.load_from_save()
	audio = AudioService.new()
	audio.name = "AudioService"
	add_child(audio)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var missing: PackedStringArray = assets.preload_all()
	if not missing.is_empty():
		push_error("Services: missing assets: %s" % ", ".join(missing))
	audio.apply_volumes(settings.master_volume, settings.sfx_volume)
	settings.apply_display()
	settings.changed.connect(_on_settings_changed)


func _on_settings_changed() -> void:
	audio.apply_volumes(settings.master_volume, settings.sfx_volume)
