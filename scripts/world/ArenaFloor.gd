class_name ArenaFloor
extends Node2D
## Draws the arena: tiled floor clipped to the circle, a soft inner vignette near
## the wall, and a crisp boundary line. Outside the circle is the plain clear colour.

const SEGMENTS: int = 160
const EDGE_LINE: Color = Color(0.29, 0.56, 0.92, 0.9)
const EDGE_GLOW: Color = Color(0.20, 0.42, 0.80, 0.16)
const EDGE_SHADE: Color = Color(0.0, 0.0, 0.0, 0.28)

var _arena: ArenaSystem
var _floor: Polygon2D


func setup(arena: ArenaSystem) -> void:
	_arena = arena
	var cfg: ArenaConfig = arena.config
	_floor = Polygon2D.new()
	_floor.name = "FloorTiles"
	var tex: Texture2D = Services.assets.texture(cfg.floor_texture_key)
	_floor.texture = tex
	_floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_floor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_floor.texture_scale = Vector2.ONE / cfg.floor_texture_scale
	_floor.polygon = _circle(arena.radius, SEGMENTS)
	# Children draw after their parent by default; the tiles must sit under the edge shading.
	_floor.show_behind_parent = true
	add_child(_floor)
	move_child(_floor, 0)
	queue_redraw()


func _draw() -> void:
	if _arena == null:
		return
	var R: float = _arena.radius
	# Inner shade band: darkens the last stretch before the wall (danger cue).
	for i: int in 6:
		var w: float = 60.0
		var r: float = R - w * (float(i) + 0.5)
		var c: Color = EDGE_SHADE
		c.a *= 1.0 - float(i) / 6.0
		draw_arc(Vector2.ZERO, r, 0.0, TAU, SEGMENTS, c, w, true)
	draw_arc(Vector2.ZERO, R - 10.0, 0.0, TAU, SEGMENTS, EDGE_GLOW, 20.0, true)
	draw_arc(Vector2.ZERO, R, 0.0, TAU, SEGMENTS, EDGE_LINE, 5.0, true)


static func _circle(r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in n:
		pts.append(Vector2.from_angle(TAU * float(i) / float(n)) * r)
	return pts
