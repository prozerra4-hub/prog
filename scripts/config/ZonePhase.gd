class_name ZonePhase
extends Resource
## One step of the shrinking safe zone: hold for `wait_sec`, then shrink over
## `shrink_sec` to `radius_ratio` of the full arena radius. The next circle is
## placed at a random spot fully inside the current one.

@export var wait_sec: float = 15.0
@export var shrink_sec: float = 12.0
## Target radius as a share of the full arena radius.
@export_range(0.05, 1.0) var radius_ratio: float = 0.7
## How far the new centre may drift, as a share of the room the shrink leaves
## (0 = concentric, 1 = may touch the old edge).
@export_range(0.0, 1.0) var center_shift: float = 0.6
