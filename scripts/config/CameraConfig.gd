class_name CameraConfig
extends Resource
## Follow camera. zoom = base_zoom / pow(radius / reference_radius, zoom_radius_exponent)
## The exponent is < 1 so a growing snake also grows on screen (a little), while
## the view widens enough that much smaller snakes look small.

@export var base_zoom: float = 1.3
@export var reference_radius: float = 13.0
@export var zoom_radius_exponent: float = 0.8
@export var min_zoom: float = 0.12
@export var max_zoom: float = 1.5
@export var zoom_smoothing: float = 2.5
@export var follow_smoothing: float = 9.0
## Look-ahead along the heading, in head radii.
@export var look_ahead_r: float = 2.0
@export var shake_decay: float = 7.0
@export var shake_max_px: float = 14.0
