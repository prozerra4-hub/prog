class_name ZoneRenderer
extends Node2D
## Draws the safe zone over the arena (above snakes, below VFX):
##   * outside the zone: a translucent blue veil (the "blue zone")
##   * the zone edge: a crisp bright line
##   * the next circle: a dashed outline, so players can plan the move early
## Line widths are converted to screen pixels so they read the same at any zoom.

const VEIL: Color = Color(0.13, 0.27, 0.72, 0.24)
const EDGE: Color = Color(0.52, 0.76, 1.0, 0.95)
const NEXT: Color = Color(1.0, 1.0, 1.0, 0.75)
const EDGE_PX: float = 3.0
const NEXT_PX: float = 2.0
const SEGMENTS: int = 160
## Dash length on screen (px); the dash count follows the circle's screen size.
const DASH_PX: float = 18.0
const MAX_DASHES: int = 1440

var _zone: ZoneSystem
var _arena_radius: float = 0.0


func setup(zone: ZoneSystem, arena_radius: float) -> void:
	_zone = zone
	_arena_radius = arena_radius


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _zone == null or _zone.radius >= _arena_radius - 1.0 and _zone.state == ZoneSystem.State.DONE:
		return
	var zoom: float = maxf(get_canvas_transform().get_scale().x, 0.0001)
	var c: Vector2 = _zone.center
	var r: float = _zone.radius
	# Veil: one thick ring from the zone edge out past the arena wall.
	var outer: float = _arena_radius + c.length() + 200.0
	var w: float = outer - r
	if w > 0.0:
		draw_arc(c, r + w * 0.5, 0.0, TAU, SEGMENTS, VEIL, w, false)
	draw_arc(c, r, 0.0, TAU, SEGMENTS, EDGE, EDGE_PX / zoom, true)
	if _zone.state != ZoneSystem.State.DONE and _zone.next_radius < r - 1.0:
		_draw_dashed_circle(_zone.next_center, _zone.next_radius, NEXT, NEXT_PX / zoom, zoom)


## Evenly dashed circle with screen-sized dashes; only dashes in view are drawn.
func _draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float, zoom: float) -> void:
	var screen_circumference: float = TAU * radius * zoom
	var dashes: int = clampi(int(screen_circumference / (DASH_PX * 2.0)) * 2, 48, MAX_DASHES)
	var step: float = TAU / float(dashes)
	var view: Rect2 = _view_rect().grow(DASH_PX / zoom)
	for i: int in range(0, dashes, 2):
		var a0: float = step * float(i)
		var mid: Vector2 = center + Vector2.from_angle(a0 + step * 0.5) * radius
		if view.has_point(mid):
			draw_arc(center, radius, a0, a0 + step, 3, color, width, true)


func _view_rect() -> Rect2:
	var inv: Transform2D = get_canvas_transform().affine_inverse()
	var a: Vector2 = inv * Vector2.ZERO
	var b: Vector2 = inv * get_viewport_rect().size
	return Rect2(a, Vector2.ZERO).expand(b)
