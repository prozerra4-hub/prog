class_name SnakeSkin
extends Resource
## A colour scheme. Every skin recolours the same bead artwork through
## shaders/snake_skin.gdshader, so material, lighting and outline stay identical
## across colours. Hue is in turns (0..1).

@export var id: StringName = &"azure"
@export var display_name: String = "Azure"
@export_range(0.0, 1.0) var hue: float = 0.594
@export_range(0.0, 2.0) var saturation: float = 1.0
@export_range(0.0, 2.0) var value: float = 1.0
## Secondary band colour (used by bosses / patterned skins).
@export_range(0.0, 1.0) var band_hue: float = 0.12
@export_range(0.0, 2.0) var band_saturation: float = 1.0
@export_range(0.0, 2.0) var band_value: float = 1.0
## Every Nth bead uses the band colour. 0 = no bands.
@export var band_every: int = 0
## Flat UI colour used for nameplates, leaderboard and remains.
@export var ui_color: Color = Color(0.25, 0.6, 1.0)
## Remains food texture key (matches the skin colour family).
@export var remains_texture_key: StringName = &"food.cyan"
## Best level required to unlock in the skin menu. 0 = always unlocked.
@export var unlock_best_level: int = 0
