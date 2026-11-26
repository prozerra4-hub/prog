class_name SaveService
extends RefCounted
## Local persistence (ConfigFile). Knows nothing about gameplay: callers hand it a
## MatchResult or settings values. Data is versioned so future schema changes can
## migrate old saves.

const SAVE_PATH: String = "user://serpent_arena_save.cfg"
const SCHEMA_VERSION: int = 1

const SEC_META: String = "meta"
const SEC_PROFILE: String = "profile"
const SEC_SETTINGS: String = "settings"

var best_level: int = 0
var best_score: int = 0
## 0 = never finished a match.
var best_rank: int = 0
var total_kills: int = 0
var matches_played: int = 0
var unlocked_skins: PackedStringArray = PackedStringArray()
var selected_skin: StringName = &""
var settings: Dictionary = {}

var _path: String


func _init(path: String = SAVE_PATH) -> void:
	_path = path


## Loads the profile; missing, unreadable or future-version saves start fresh.
func load_data() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(_path)
	if err == ERR_FILE_NOT_FOUND:
		return
	if err != OK:
		push_warning("SaveService: could not read %s (error %d); starting fresh." % [_path, err])
		return
	var version: int = int(cfg.get_value(SEC_META, "version", 0))
	if version > SCHEMA_VERSION:
		push_warning("SaveService: save version %d is newer than supported %d; ignoring." % [version, SCHEMA_VERSION])
		return
	_migrate(cfg, version)
	best_level = int(cfg.get_value(SEC_PROFILE, "best_level", 0))
	best_score = int(cfg.get_value(SEC_PROFILE, "best_score", 0))
	best_rank = int(cfg.get_value(SEC_PROFILE, "best_rank", 0))
	total_kills = int(cfg.get_value(SEC_PROFILE, "total_kills", 0))
	matches_played = int(cfg.get_value(SEC_PROFILE, "matches_played", 0))
	unlocked_skins = PackedStringArray(cfg.get_value(SEC_PROFILE, "unlocked_skins", PackedStringArray()))
	selected_skin = StringName(cfg.get_value(SEC_PROFILE, "selected_skin", ""))
	settings = {}
	if cfg.has_section(SEC_SETTINGS):
		for key: String in cfg.get_section_keys(SEC_SETTINGS):
			settings[key] = cfg.get_value(SEC_SETTINGS, key)


## Writes the profile and settings with the schema version.
func save_data() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value(SEC_META, "version", SCHEMA_VERSION)
	cfg.set_value(SEC_PROFILE, "best_level", best_level)
	cfg.set_value(SEC_PROFILE, "best_score", best_score)
	cfg.set_value(SEC_PROFILE, "best_rank", best_rank)
	cfg.set_value(SEC_PROFILE, "total_kills", total_kills)
	cfg.set_value(SEC_PROFILE, "matches_played", matches_played)
	cfg.set_value(SEC_PROFILE, "unlocked_skins", unlocked_skins)
	cfg.set_value(SEC_PROFILE, "selected_skin", String(selected_skin))
	for key: String in settings.keys():
		cfg.set_value(SEC_SETTINGS, key, settings[key])
	var err: Error = cfg.save(_path)
	if err != OK:
		push_error("SaveService: failed to write %s (error %d)" % [_path, err])
	return err


## Folds a finished match into the profile. Returns true if any record was beaten.
func record_match(result: MatchResult) -> bool:
	var improved: bool = false
	matches_played += 1
	total_kills += result.kills
	if result.final_level > best_level:
		best_level = result.final_level
		improved = true
	if result.score > best_score:
		best_score = result.score
		improved = true
	if best_rank == 0 or result.final_rank < best_rank:
		best_rank = result.final_rank
		improved = true
	return improved


## Marks a skin unlocked (no-op if already).
func unlock_skin(id: StringName) -> void:
	if not unlocked_skins.has(String(id)):
		unlocked_skins.append(String(id))


## True if the best level reached unlocks `skin` (or it was unlocked explicitly).
func is_skin_unlocked(skin: SnakeSkin) -> bool:
	return skin.unlock_best_level <= best_level or unlocked_skins.has(String(skin.id))


func _migrate(_cfg: ConfigFile, from_version: int) -> void:
	# Version 0 -> 1: no structural changes yet. Future migrations go here.
	if from_version < SCHEMA_VERSION:
		pass
