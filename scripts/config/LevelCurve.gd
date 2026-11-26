class_name LevelCurve
extends Resource
## XP curve data. required_xp(L) = base_xp + pow(L, growth_exponent) * growth_factor
## The formula itself lives in LevelSystem; this resource only holds the numbers.

@export var base_xp: float = 2.0
@export var growth_factor: float = 0.6
@export var growth_exponent: float = 0.25
@export_range(1, 99999) var max_level: int = 99999
