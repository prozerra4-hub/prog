class_name GameBalance
extends Resource
## Root balance resource for a match (resources/balance/GameBalance.tres).
## Systems receive only the sub-resource they need.

@export_group("Match")
@export var match_duration_sec: float = 90.0
@export var ai_count: int = 10
@export var revive_count: int = 3
@export var leaderboard_size: int = 5
@export var player_respawn_delay_sec: float = 1.6
@export var ai_respawn_delay_sec: float = 2.2
## Starting level range for AI at match start.
@export var ai_start_level_min: int = 1
@export var ai_start_level_max: int = 6
## AI respawn level = player level * random ratio in this range.
@export var ai_respawn_ratio_min: float = 0.2
@export var ai_respawn_ratio_max: float = 0.7
## AI never exceed boss level * this ratio (the boss stays the apex threat).
@export_range(0.1, 1.0) var ai_level_cap_ratio_of_boss: float = 0.92
@export var ai_names: PackedStringArray = PackedStringArray()

@export_group("Systems")
@export var level_curve: LevelCurve
@export var snake: SnakeTuning
@export var combat: CombatRules
@export var food: FoodTable
@export var arena: ArenaConfig
@export var camera: CameraConfig
@export var score: ScoreWeights
@export var boss: BossDefinition
@export var showdown: ShowdownConfig
@export var zone: ZoneConfig

@export_group("Roster")
@export var player_skins: Array[SnakeSkin] = []
@export var ai_skins: Array[SnakeSkin] = []
@export var ai_personalities: Array[AIPersonality] = []
