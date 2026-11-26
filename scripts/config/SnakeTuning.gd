class_name SnakeTuning
extends Resource
## Shape, size and handling of every snake. All lengths are world pixels unless the
## name ends in `_r`, which means "multiples of the snake's current radius".
##
## Size grows as a power of level so big gaps LOOK big: Lv1 -> Lv1000 is ~7x wider.
## Handling: small snakes are quick and agile; big ones are heavy and slow to turn.

@export_group("Size")
## radius = base_radius * pow(level, radius_exponent)
@export var base_radius: float = 13.0
@export var radius_exponent: float = 0.28
## How fast the drawn radius catches up with the target radius (1/s).
@export var radius_smoothing: float = 6.0
## Head is drawn this much larger than a body bead.
@export var head_scale: float = 1.22

@export_group("Length")
## length_r = length_base_r + length_log_gain_r * ln(level)
@export var length_base_r: float = 10.0
@export var length_log_gain_r: float = 6.0
## Preferred distance between beads, in radii.
@export var segment_spacing_r: float = 0.55
## Upper bound of rendered/collidable beads per snake. When the logical length needs
## more, spacing widens instead so the visible length always matches the logical one.
@export var render_segment_cap: int = 140
## Beads at the tail end that taper down.
@export var tail_taper_segments: int = 9
@export_range(0.1, 1.0) var tail_min_scale: float = 0.42

@export_group("Movement")
@export var base_speed: float = 240.0
## speed = base_speed * pow(radius / base_radius, speed_radius_exponent).
## World speed rises slower than size, so on screen big snakes feel heavy.
@export var speed_radius_exponent: float = 0.5
## Max angular speed (rad/s) at level 1.
@export var turn_rate: float = 9.0
## turn_rate is divided by pow(radius / base_radius, turn_size_falloff).
@export var turn_size_falloff: float = 0.5
## Angular acceleration smoothing (1/s). Higher = snappier.
@export var turn_smoothing: float = 26.0
## Proportional gain from heading error to desired angular velocity.
@export var turn_gain: float = 13.0
@export var speed_smoothing: float = 8.0

@export_group("Path")
## Minimum head travel (in radii) before a new path point is recorded.
@export var path_step_r: float = 0.18

@export_group("Feedback")
## Bulge wave when swallowing food.
@export var gulp_wave_speed_r: float = 22.0
@export var gulp_wave_amplitude: float = 0.16
@export var gulp_wave_width_r: float = 2.2


## Body radius a snake of `level` grows to.
func radius_for_level(level: int) -> float:
	return base_radius * pow(float(maxi(level, 1)), radius_exponent)


## Body length in radii for `level`.
func length_r_for_level(level: int) -> float:
	return length_base_r + length_log_gain_r * log(float(maxi(level, 1)))


## Body length a snake of `level` settles at (radius fully grown).
func full_length_for_level(level: int, length_multiplier: float = 1.0) -> float:
	return length_r_for_level(level) * radius_for_level(level) * length_multiplier


## Highest level whose full length fits in `length` (used when a body is cut).
func level_for_length(length: float, max_level: int, length_multiplier: float = 1.0) -> int:
	var lo: int = 1
	var hi: int = max_level
	while lo < hi:
		var mid: int = (lo + hi + 1) >> 1
		if full_length_for_level(mid, length_multiplier) <= length:
			lo = mid
		else:
			hi = mid - 1
	return lo


## Base movement speed for a body radius (px/s).
func speed_for_radius(radius: float) -> float:
	return base_speed * pow(radius / base_radius, speed_radius_exponent)


## Max turn rate for a body radius (rad/s); bigger turns slower.
func turn_rate_for_radius(radius: float) -> float:
	return turn_rate / pow(radius / base_radius, turn_size_falloff)
